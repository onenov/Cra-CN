import AppKit
import SwiftUI

/// Settings ▸ Performance (GitHub #91): what the recorder measured this session, read every two
/// seconds while the pane is on screen and never while it isn't. Card style like Privacy. Not in
/// Dia or Arc: Cra's own, for reports of freezes that are gone by the time they are written up.
struct PerformancePane: View {
    let nav: SettingsNavigation
    let actions: SettingsActions
    @Environment(SidebarStore.self) private var store
    @State private var section = Section.overview
    @State private var report: PerfReport?
    @State private var copied = false

    enum Section: String, CaseIterable { case overview = "Overview", events = "Events", export = "Export" }

    var body: some View {
        @Bindable var store = store
        SettingsCardPane {
            Picker("", selection: $section) { ForEach(Section.allCases, id: \.self) { Text(BrowserLocalization.text($0.rawValue)).tag($0) } }
                .pickerStyle(.segmented).labelsHidden().fixedSize()
                .frame(maxWidth: .infinity)
                .padding(.bottom, 16)
            switch section {
            case .overview: overview($store.settings.perfRecording)
            case .events: events
            case .export: export($store.settings.perfHidesSiteNames)
            }
        }
        .task(id: RefreshKey(open: nav.isOpen && nav.tab == .advanced, recording: store.settings.perfRecording)) {
            report = nil
            guard nav.isOpen, store.settings.perfRecording else { return }
            while !Task.isCancelled {
                if let r = PerfRecorder.shared { r.snapshot { report = $0 } }
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    private struct RefreshKey: Equatable { var open: Bool; var recording: Bool }

    // MARK: Overview

    @ViewBuilder private func overview(_ recording: Binding<Bool>) -> some View {
        SettingsFeatureCard {
            SettingsToggleRow(BrowserLocalization.text("Record performance"),
                              detail: BrowserLocalization.text("Cra measures itself on this Mac: freezes, CPU and memory per process, tab timings."),
                              isOn: recording)
        }
        SettingsFootnote(BrowserLocalization.text("Nothing leaves the Mac unless you export it with Help ▸ Export Diagnostics."))

        if let r = report {
            let insights = PerfInsights.evaluate(r, localize: BrowserLocalization.text)
            if !insights.isEmpty {
                SettingsHeader(BrowserLocalization.text("Findings")).padding(.top, 20)
                SettingsCard {
                    ForEach(Array(insights.enumerated()), id: \.element.id) { i, insight in
                        if i > 0 { SettingsCardDivider() }
                        SettingsCardRow {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: insight.severity == .warning ? "exclamationmark.triangle.fill" : "info.circle.fill")
                                    .foregroundStyle(insight.severity == .warning ? Color(nsColor: .systemOrange) : Color.secondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(insight.title).font(.system(size: 13))
                                    Text(insight.detail).font(.system(size: 11)).foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        } trailing: { EmptyView() }
                    }
                }
            }
            let m = r.mainThread
            card("Main thread", [
                ("Stalls of ¼ s or more", "\(m.freezes)"),
                ("Freezes of 1 s or more", "\(m.longFreezes)"),
                ("Longest freeze", m.longestFreezeMs > 0 ? PerfInsights.duration(m.longestFreezeMs) : "–"),
                ("In menus, drags, alerts, start-up", "\(m.outsideFreezes)"),
                ("Longest pass", m.longestPassMs > 0 ? PerfInsights.duration(m.longestPassMs) + (m.longestPassMode.map { " (\($0))" } ?? "") : "–"),
                ("Typical pass (99 %)", PerfInsights.duration(m.passes.percentile(0.99))),
            ])
            card("Processes", r.processes.filter { $0.count > 0 }.map { g in
                (g.kind.label + (g.count > 1 ? " ×\(g.count)" : ""),
                 g.available ? "\(String(format: "%.1f", g.cpuPct)) % CPU · \(PerfInsights.bytes(g.footprintBytes))" : "not available")
            })
            if let s = r.system {
                card("Mac", [
                    ("CPU, all cores", s.cpuPct.map { "\(Int($0.rounded())) %" } ?? "–"),
                    ("Memory pressure", s.memoryPressure.rawValue.capitalized),
                    ("Temperature", s.thermalState.capitalized),
                    ("Low Power Mode", s.lowPowerMode ? "On" : "Off"),
                    ("Free disk", s.freeDiskBytes.map(PerfInsights.bytes) ?? "–"),
                ])
            }
            card("Tabs", tabRows(r))
            Text(BrowserLocalization.format("Session %1$@, launch %2$@, up %3$@ min · recording costs %4$@ %% of a core", "\(r.session.id)", "\(r.session.launch)", "\(Int(r.session.uptimeSeconds / 60))", "\(String(format: "%.3f", r.selfCost.cpuPct))"))
                .font(.system(size: 11)).foregroundStyle(.secondary)
                .padding(.leading, 8).padding(.top, 12)
        } else if !recording.wrappedValue {
            SettingsFootnote(BrowserLocalization.text("Recording is off: no samples, no timers, nothing written. Files already recorded stay until you clear them."))
                .padding(.top, 12)
        } else {
            ProgressView().controlSize(.small).frame(maxWidth: .infinity).padding(.top, 24)
        }
    }

    private func tabRows(_ r: PerfReport) -> [(String, String)] {
        var rows: [(String, String)] = []
        if let t = r.tabs.latest { rows.append(("Tabs", BrowserLocalization.format("%1$@ · %2$@ loaded · %3$@ asleep", "\(t.tabs)", "\(t.live)", "\(t.slept)"))) }
        for (title, metric) in [("Tab switch", PerfMetric.tabSwitch), ("New page", .pageCreate), ("Page load", .pageLoad), ("Waking a slept tab", .tabWake)] {
            guard let h = r.timings[metric.rawValue], h.count > 0 else { continue }
            rows.append((title, BrowserLocalization.format("%1$@ typical · %2$@ slow", PerfInsights.duration(h.percentile(0.5)), PerfInsights.duration(h.percentile(0.95)))))
        }
        if r.tabs.longTasks > 0 { rows.append(("Busy page (long tasks)", "\(r.tabs.longTasks) · \(PerfInsights.duration(r.tabs.longTaskMs))")) }
        if r.tabs.longFrames > 0 { rows.append(("Late frames", BrowserLocalization.format("%1$@ · longest %2$@", "\(r.tabs.longFrames)", PerfInsights.duration(r.tabs.longestFrameMs)))) }
        if r.tabs.videoFrames > 0 { rows.append(("Video frames dropped", BrowserLocalization.format("%1$@ of %2$@", "\(r.tabs.droppedVideoFrames)", "\(r.tabs.videoFrames)"))) }
        return rows
    }

    @ViewBuilder private func card(_ title: String, _ rows: [(String, String)]) -> some View {
        if !rows.isEmpty {
            SettingsHeader(BrowserLocalization.text(title)).padding(.top, 20)
            SettingsCard {
                ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                    if i > 0 { SettingsCardDivider() }
                    SettingsCardRow {
                        Text(BrowserLocalization.text(row.0)).font(.system(size: 13))
                    } trailing: {
                        Text(BrowserLocalization.text(row.1)).font(.system(size: 13).monospacedDigit()).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: Events

    @ViewBuilder private var events: some View {
        let list = report.map(Self.timeline) ?? []
        if list.isEmpty {
            SettingsFootnote(report == nil ? BrowserLocalization.text("Recording is off.") : BrowserLocalization.text("Nothing has happened this session: no stalls, crashed pages or failed loads."))
        } else {
            SettingsCard {
                ForEach(Array(list.prefix(100).enumerated()), id: \.offset) { i, e in
                    if i > 0 { SettingsCardDivider() }
                    SettingsCardRow {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(e.title).font(.system(size: 13))
                            if !e.detail.isEmpty {
                                Text(e.detail).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(2)
                            }
                        }
                    } trailing: {
                        Text(e.time).font(.system(size: 11).monospacedDigit()).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private struct Row { var at: Double; var time: String; var title: String; var detail: String }

    /// Stalls and events, newest first.
    private static func timeline(_ r: PerfReport) -> [Row] {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        func time(_ at: Double) -> String { f.string(from: r.session.startedAt.addingTimeInterval(at)) }
        var rows = r.mainThread.recent.map { s in
            Row(at: s.at, time: time(s.at),
                title: "\(s.freeze ? (BrowserLocalization.text(s.kind == .stall ? "Stall" : "Freeze")) : BrowserLocalization.format("Busy %1$@ loop", BrowserLocalization.text(s.mode))) \(PerfInsights.duration(s.ms))",
                detail: ([s.site].compactMap { $0 } + (s.marks.isEmpty ? [] : [BrowserLocalization.format("after %1$@", s.marks.joined(separator: " → "))])).joined(separator: " · "))
        }
        rows += r.events.filter { $0.kind != "freeze" && $0.kind != "hang" }.map { e in
            Row(at: e.at, time: time(e.at), title: e.kind == "renderer" ? BrowserLocalization.format("Page process %1$@", "\(e.detail)") : BrowserLocalization.format("Load failed (%1$@)", "\(e.detail)"),
                detail: e.site ?? "")
        }
        return rows.sorted { $0.at > $1.at }
    }

    // MARK: Export

    @ViewBuilder private func export(_ hideSites: Binding<Bool>) -> some View {
        SettingsCard {
            SettingsCardRow {
                Text("Hide site names").font(.system(size: 13))
            } trailing: {
                Toggle("Hide site names", isOn: hideSites).toggleStyle(.arcSwitch).labelsHidden()
            }
        }
        SettingsFootnote(BrowserLocalization.text("Sites in the exported files become site-1, site-2… in every file, logs included. Without it they keep their host name (never the full address), as Cra's logs always have."))
        HStack(spacing: 8) {
            Button("Export Diagnostics…") { actions.exportDiagnostics() }
            Button(copied ? BrowserLocalization.text("Copied") : BrowserLocalization.text("Copy Summary")) {
                guard let r = report else { return }
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(PerfSummary.text(r), forType: .string)
                copied = true
            }
            .disabled(report == nil)
            Spacer(minLength: 0)
            Button("Clear…") { confirmClear() }
        }
        .padding(.top, 16)
        SettingsFootnote(BrowserLocalization.format("Copy Summary never names a site. The recording lives in %1$@ and stays under 2 MB.", "\(AppPaths.file("Perf").path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))"))
            .padding(.top, 4)
    }

    private func confirmClear() {
        let alert = AppDialog(title: BrowserLocalization.text("Clear the performance recording?"),
                              message: BrowserLocalization.text("This session's numbers, the last 24 hours and saved freezes are deleted."),
                              actions: [DialogAction(BrowserLocalization.text("Clear"), role: .destructive), .cancel])
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        PerfRecorder.clear()
        report = nil
    }
}

private extension PerfProcessKind {
    var label: String {
        switch self {
        case .browser: return BrowserLocalization.text("Cra")
        case .renderer: return BrowserLocalization.text("Pages")
        case .gpu: return BrowserLocalization.text("GPU")
        case .utility: return BrowserLocalization.text("Network, storage, audio")
        case .other: return BrowserLocalization.text("Other")
        }
    }
}
