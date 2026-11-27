import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct PluginsPane: View {
    @State private var registry = LiveFolderPluginStore.shared
    @State private var error: String?
    @State private var preparing = false

    var body: some View {
        SettingsCardPane {
            SettingsHeader(BrowserLocalization.text("Live folder plugins"))
            SettingsCard {
                if registry.packages.isEmpty {
                    SettingsCardRow {
                        Text(BrowserLocalization.text("No plugins installed.")).font(.system(size: 13)).foregroundStyle(.secondary)
                    } trailing: { EmptyView() }
                }
                ForEach(Array(registry.packages.sorted { $0.manifest.name < $1.manifest.name }.enumerated()), id: \.element.manifest.id) { index, package in
                    if index > 0 { SettingsCardDivider() }
                    SettingsCardRow {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(package.manifest.name) \(package.manifest.version)").font(.system(size: 13))
                            Text(registry.isBundled(package) ? BrowserLocalization.text("Built-in") : BrowserLocalization.text("Installed plugin"))
                                .font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                    } trailing: {
                        HStack(spacing: 12) {
                            if !registry.isBundled(package) { Button(BrowserLocalization.text("Remove…")) { remove(package) } }
                            Toggle(BrowserLocalization.format("Enable %1$@", "\(package.manifest.name)"), isOn: Binding(
                                get: { registry.isEnabled(package.manifest.id) },
                                set: { enabled in Task { await registry.setEnabled(enabled, id: package.manifest.id) } }
                            )).labelsHidden().toggleStyle(.arcSwitch)
                        }
                    }
                }
            }
            HStack {
                Button(BrowserLocalization.text("Add Plugin…")) { add() }
                Spacer()
                if registry.reloading { ProgressView().controlSize(.small) }
                Button(BrowserLocalization.text("Reload Plugins")) {
                    Task {
                        await registry.reload()
                        await LiveFolderManager.shared.migrateFolders()
                        LiveFolderManager.shared.refreshStale()
                    }
                }
            }.padding(.top, 7.5)
            SettingsFootnote(BrowserLocalization.text("Create folders from the sidebar’s Live Folders menu. Disabling or removing a plugin keeps its existing folders and tabs."))
            if let error { SettingsFootnote(error).foregroundStyle(.red) }
            ForEach(Array(registry.failures.enumerated()), id: \.offset) { _, message in
                SettingsFootnote(message).foregroundStyle(.red)
            }
        }
        .disabled(registry.reloading || preparing)
    }

    private func add() {
        guard let window = AppDialog.parentWindow else { return }
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.zip]
        panel.allowsMultipleSelection = false
        panel.prompt = BrowserLocalization.text("Choose Plugin")
        panel.message = BrowserLocalization.text("Choose a ZIP archive containing a live folder plugin.")
        panel.beginSheetModal(for: window) { response in
            guard response == .OK, let url = panel.url else { return }
            preparing = true
            Task {
                defer { preparing = false }
                do {
                    let archive = try await Task.detached { try LiveFolderPluginArchive(url: url) }.value
                    let package = archive.package
                    var permissions = package.manifest.sessionOrigins.map { "• " + $0 }
                    if package.manifest.sessionSetting != nil { permissions.append("• The address you enter when you add its folder") }
                    // A plugin reads these sites signed in as you, and can pass what it read from one to
                    // another in an address: say so, since that is what the user is trusting it with.
                    let message = permissions.isEmpty
                        ? BrowserLocalization.text("This plugin doesn’t use your browser session. It can’t read files or reach the network.")
                        : BrowserLocalization.text("This plugin can load pages from these sites signed in as you, with the profile of the Space its folder is in, ")
                            + "and can send what it reads to any of them:\n\n" + permissions.joined(separator: "\n")
                            + "\n\nOnly add plugins from people you trust."
                    AppDialog(title: BrowserLocalization.format("Add “%1$@”?", "\(package.manifest.name)"), message: message,
                        actions: [DialogAction(BrowserLocalization.text("Add Plugin")), .cancel]).present(over: window) { result in
                        guard result == .alertFirstButtonReturn else { return }
                        Task {
                            do { try await registry.install(archive.package.directory); error = nil }
                            catch { self.error = error.localizedDescription }
                        }
                    }
                } catch { self.error = error.localizedDescription }
            }
        }
    }

    private func remove(_ package: LiveFolderPluginPackage) {
        guard let window = AppDialog.parentWindow else { return }
        AppDialog(title: BrowserLocalization.format("Remove “%1$@”?", "\(package.manifest.name)"),
            message: BrowserLocalization.text("The plugin will move to the Trash. Its existing folders and tabs will stay in the sidebar."),
            actions: [DialogAction(BrowserLocalization.text("Remove Plugin"), role: .destructive), .cancel]).present(over: window) { response in
            guard response == .alertFirstButtonReturn else { return }
            Task {
                do { try await registry.remove(package); error = nil }
                catch { self.error = error.localizedDescription }
            }
        }
    }
}
