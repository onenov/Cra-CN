import AppKit
import SwiftUI

struct PrivacyPane: View {
    @Environment(SidebarStore.self) private var store
    let actions: SettingsActions

    var body: some View {
        @Bindable var store = store
        SettingsCardPane {
            SettingsHeader(BrowserLocalization.text("Content blocking"))
            SettingsFeatureCard {
                SettingsToggleRow(BrowserLocalization.text("Block ads and trackers"),
                                  detail: BrowserLocalization.text("Requests to known ad and tracker domains are cancelled, unless the domain belongs to the site you’re on. To let one site load everything, turn it off in that site’s menu in the address bar."),
                                  isOn: $store.settings.blocksAdsAndTrackers)
                if store.settings.blocksAdsAndTrackers {
                    SettingsCardDivider()
                    SettingsPlainRow(BrowserLocalization.text("Blocking"),
                                       detail: store.settings.adBlockingLevel == .strict
                                           ? BrowserLocalization.text("Strict also blocks the ads and trackers EasyList and EasyPrivacy know about. It catches more, and now and then a page needs ads turned off for it.")
                                           : BrowserLocalization.text("Standard blocks well-known ad and tracker servers and rarely gets in a page’s way."),
                                       trailing: {
                        Picker("Blocking", selection: $store.settings.adBlockingLevel) {
                            Text("Standard").tag(AdBlockingLevel.standard)
                            Text("Strict").tag(AdBlockingLevel.strict)
                        }
                        .pickerStyle(.segmented).labelsHidden().fixedSize()
                    })
                }
                SettingsCardDivider()
                // Arc: Settings ▸ General "Block Cookie Banners", off by default.
                SettingsToggleRow(BrowserLocalization.text("Block cookie banners"),
                                  detail: BrowserLocalization.text("Cookie banners from the common consent tools are hidden. Pages load again with the change."),
                                  isOn: $store.settings.blockCookieBanners)
                SettingsCardDivider()
                // Not in Arc: Cra's Chromium (fingerprinting-protection.patch).
                SettingsToggleRow(BrowserLocalization.text("Fingerprinting protection"),
                                  detail: BrowserLocalization.text("Sites that tell browsers apart by reading back drawings, 3D graphics or sound get faint noise in what they read, different for each site and each time Cra opens. Sites also see 8 processor cores."),
                                  isOn: $store.settings.fingerprintingProtection)
                SettingsCardDivider()
                SettingsPlainRow(BrowserLocalization.text("Block lists"),
                                   detail: BrowserLocalization.text("Pick lists one by one, add a list by its address or write your own filters.")
                                       + (BlockLists.shared.inUse.map { " " + BlockListCount.inUse(rules: $0.rules, lists: $0.lists) } ?? ""),
                                   trailing: { Button(BrowserLocalization.text("Advanced…")) { showsBlockLists = true } })
            }

            SettingsHeader(BrowserLocalization.text("Connection security")).padding(.top, 20)
            SettingsFeatureCard {
                SettingsToggleRow(BrowserLocalization.text("Always use secure connections"),
                                  detail: BrowserLocalization.text("Pages load over HTTPS. Before opening a public site that doesn’t support it, Cra warns you first. Addresses on your own network, such as 192.168… or a .local name, load as they are."),
                                  isOn: $store.settings.httpsOnly)
                SettingsCardDivider()
                SecureDNSRows(error: $dnsError, footnote: dnsFootnote)
            }
            if let dnsError { SettingsFootnote(dnsError).foregroundStyle(.red) }

            SettingsHeader(BrowserLocalization.text("Data")).padding(.top, 20)
            SettingsFeatureCard {
                SettingsPlainRow(BrowserLocalization.text("Clear browsing data"),
                                   detail: BrowserLocalization.text("Delete history, cookies and cached files for the current space’s profile. History you delete also leaves the command bar."),
                                   trailing: { Button(BrowserLocalization.text("Clear…")) { actions.openURL(BrowsingDataClear.pageURL) } })
                SettingsCardDivider()
                SettingsToggleRow(BrowserLocalization.text("Share anonymous usage stats"),
                                  detail: BrowserLocalization.text("Once a day: your Cra and macOS versions, the kind of Mac, rough counts of spaces, tabs and extensions, and which settings you changed. Never the sites you visit, what you search or anything on a page. Each report has a new random ID, so reports can’t be tied together or to you."),
                                  isOn: $store.settings.shareUsageStats) {
                    HStack(spacing: 12) {
                        Button(BrowserLocalization.text("Show What’s Sent")) { SharingService.shared.showStats() }
                        Link(BrowserLocalization.text("How Cra handles your data"), destination: URL(string: SiteLinks.tagged("https://crabrowser.app/privacy", from: .privacy))!)
                    }
                }
                SettingsCardDivider()
                SettingsPlainRow(BrowserLocalization.text("Crash reports"),
                                   detail: BrowserLocalization.text("A report shows what Cra was doing when it crashed, without your name, file paths or anything that identifies this Mac."),
                                   trailing: { EmptyView() }) {
                    Picker(BrowserLocalization.text("Crash reports"), selection: $store.settings.crashReports) {
                        Text(BrowserLocalization.text("Ask each time")).tag(CrashReportChoice.ask)
                        Text(BrowserLocalization.text("Send automatically")).tag(CrashReportChoice.send)
                        Text(BrowserLocalization.text("Never send")).tag(CrashReportChoice.never)
                    }
                    .labelsHidden()
                    .fixedSize()
                }
            }
        }
        .sheet(isPresented: $showsBlockLists) { BlockListsSheet().environment(store) }
    }

    @State private var dnsError: String?
    @State private var showsBlockLists = false

    private var dnsFootnote: String? {
        let dns = SecureDNSSetting.shared
        guard let summary = dns.inEffect?.summary, !summary.isEmpty else { return nil }
        return dns.isManaged ? BrowserLocalization.text("Your organization sets secure DNS. ") + summary : summary
    }
}

/// Settings ▸ Privacy ▸ Block lists ▸ Advanced…: every list one by one (#507, #791), for people who know
/// them. The pane itself keeps one switch and Standard/Strict.
private struct BlockListsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(BrowserLocalization.text("Block lists")).font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 24).padding(.top, 18).padding(.bottom, 10)
            Divider()
            ScrollView { BlockListRows().padding(24) }
            Divider()
            HStack {
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 560, height: 480)
    }
}

/// Catalog entries stay visible when switched off. A custom subscription stays until removed.
private struct BlockListRows: View {
    @Environment(SidebarStore.self) private var store
    private let lists = BlockLists.shared
    @State private var adding = false
    @State private var editingRules = false
    @State private var draft = ""
    @State private var text = ""
    @State private var error: String?

    var body: some View {
        @Bindable var store = store
        VStack(alignment: .leading, spacing: 0) {
            SettingsHeader(BrowserLocalization.text("Built-in lists"))
            SettingsFeatureCard {
                SettingsToggleRow(BrowserLocalization.text("AdAway"), detail: BrowserLocalization.text("Built in. Blocks third-party ad and tracker domains, including in-app advertising networks."), isOn: $store.settings.adAwayEnabled) {
                    RuleCountLine(count: lists.builtInCounts["adaway"])
                }
                SettingsCardDivider()
                SettingsToggleRow(BrowserLocalization.text("Anudeep’s Blacklist"), detail: BrowserLocalization.text("Built in. Blocks third-party connections to known advertising and tracking servers."), isOn: $store.settings.anudeepEnabled) {
                    RuleCountLine(count: lists.builtInCounts["anudeep"])
                }
            }
            SettingsHeader(BrowserLocalization.text("Filter lists")).padding(.top, 14)
            ForEach(DesktopFilterList.groups(selected: Set(store.settings.customBlocklists))) { group in
                FilterListGroupCard(title: group.category.title, selected: group.selectedCount, total: group.entries.count,
                                    isExpanded: [.ads, .tracking, .security].contains(group.category)) {
                    ForEach(group.entries) { list in
                        SettingsCardDivider()
                        listRow(list.address, name: list.name, detail: list.detail)
                    }
                }.padding(.bottom, 6)
            }
            SettingsFootnote(BrowserLocalization.text("These lists block connections to third-party domains on pages you visit. Opening a listed address directly does not show a warning."))
            HStack {
                SettingsHeader(BrowserLocalization.text("Manage lists"))
                Spacer()
                Button(BrowserLocalization.text("Update Enabled Lists")) { store.settings.customBlocklists.forEach { lists.fetch($0) } }
                    .disabled(store.settings.customBlocklists.isEmpty || !lists.fetching.isEmpty)
                Button(BrowserLocalization.text("Add List…")) { error = nil; text = ""; adding = true }.disabled(adding)
            }.padding(.top, 14)
            if !store.settings.customFilterAddresses.isEmpty || adding {
                SettingsHeader(BrowserLocalization.text("Your lists")).padding(.top, 14)
                SettingsFeatureCard {
                    ForEach(store.settings.customFilterAddresses, id: \.self) { address in
                        listRow(address, name: lists.cached[address]?.name ?? address, detail: address, removable: true)
                        if address != store.settings.customFilterAddresses.last || adding { SettingsCardDivider() }
                    }
                    if adding { addListRow }
                }
            }
            if let failure = lists.networkFailure { SettingsFootnote(failure).foregroundStyle(.red) }
            if let error { SettingsFootnote(error).foregroundStyle(.red) }
            SettingsFootnote(BrowserLocalization.text("Enabled lists update automatically. Downloads contact each list’s host, which can see your IP address. Filtering happens on this Mac."))
            SettingsHeader(BrowserLocalization.text("Custom filters")).padding(.top, 14)
            SettingsFeatureCard {
                SettingsToggleRow(BrowserLocalization.text("Use my filters"), detail: BrowserLocalization.text("Apply your saved rules."), isOn: $store.settings.personalFiltersEnabled)
                SettingsCardDivider()
                SettingsPlainRow(BrowserLocalization.text("My filters"), detail: BrowserLocalization.text("One domain, network rule, exception or element filter per line."), trailing: {
                    Button(BrowserLocalization.text("Edit…")) { draft = store.settings.personalBlockFilters ?? ""; editingRules = true }
                        .disabled(editingRules)
                }) {
                    RuleCountLine(count: lists.personalCount(store.settings.personalBlockFilters))
                    if editingRules {
                        TextEditor(text: $draft)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 84)
                            .accessibilityLabel(BrowserLocalization.text("Custom filters"))
                        Text(BrowserLocalization.text("To allow network requests on a site, enter @@||example.org^$document."))
                            .font(.caption).foregroundStyle(.secondary)
                        HStack {
                            Button("Cancel") { editingRules = false }
                            Button(BrowserLocalization.text("Save Changes")) {
                                store.settings.personalBlockFilters = draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : draft
                                editingRules = false
                            }
                            .disabled(draft == (store.settings.personalBlockFilters ?? ""))
                        }
                    }
                }
            }
        }
    }

    private func listRow(_ address: String, name: String, detail: String, removable: Bool = false) -> some View {
        SettingsPlainRow(name, detail: name == detail ? "" : detail, trailing: {
            if lists.fetching.contains(address) { ProgressView().controlSize(.mini) }
            if removable {
                Button { store.settings.forgetFilterList(address) } label: { Image(systemName: "minus.circle") }
                    .buttonStyle(.borderless).help(BrowserLocalization.text("Remove this list")).accessibilityLabel("Remove " + name)
            }
            Toggle(name, isOn: Binding(
                get: { store.settings.customBlocklists.contains(address) },
                set: { store.settings.setFilterList(address, enabled: $0) }
            ))
            .toggleStyle(.arcSwitch).labelsHidden()
            .accessibilityLabel(Text(verbatim: name == detail ? name : name + ", " + detail))
            .help(address)
        }) {
            if let failure = lists.failures[address] { Text(failure).font(.caption).foregroundStyle(.red) }
            if store.settings.customBlocklists.contains(address) { RuleCountLine(count: lists.count(address)) }
        }
    }

    private var addListRow: some View {
        SettingsCardRow {
            TextField(BrowserLocalization.text("List address"), text: $text, prompt: Text("https://example.com/list.txt"))
                .textFieldStyle(.roundedBorder).onSubmit(addTyped)
        } trailing: {
            Button(BrowserLocalization.text("Choose File…"), action: chooseFile)
            Button("Cancel") { adding = false; error = nil }
            Button("Add", action: addTyped).keyboardShortcut(.defaultAction)
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func addTyped() {
        apply(CustomBlocklist.adding(text, to: store.settings.customBlocklists, httpsOnly: false))
    }

    private func chooseFile() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = BrowserLocalization.text("Choose a block list: a hosts file, a list of domains or an Adblock Plus list.")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        apply(CustomBlocklist.adding(url, to: store.settings.customBlocklists))
    }

    private func apply(_ addition: CustomBlocklist.Addition) {
        switch addition {
        case .invalid:
            error = BrowserLocalization.text("Enter the list’s web address, like https://example.com/list.txt.")
            return
        case .added(let next):
            if let address = next.last { store.settings.setFilterList(address, enabled: true) }
        case .alreadyAdded:
            break
        }
        error = nil
        adding = false
    }

}

/// A block list's rules under its row: "48,210 rules · 3,102 Cra can’t use" (BlockListCount).
private struct RuleCountLine: View {
    let count: BlockListCount?

    var body: some View {
        if let summary = count?.summary, !summary.isEmpty {
            Text(summary).font(.caption).foregroundStyle(.secondary).monospacedDigit()
                .accessibilityIdentifier("ruleCount")
        }
    }
}

/// Chromium's secure DNS setting (chrome://settings/security) as a menu, under "Always use
/// secure connections": the lookup before the page (#133). Custom adds a row for the template.
private struct SecureDNSRows: View {
    @Binding var error: String?
    /// What the current setting does, or that the organization sets it.
    let footnote: String?
    private let dns = SecureDNSSetting.shared
    @State private var editingCustom = false
    @State private var customText = ""

    var body: some View {
        SettingsPlainRow(BrowserLocalization.text("DNS over HTTPS"),
                         detail: BrowserLocalization.text("Before a page loads, the site’s address is looked up over an encrypted connection, so the network you’re on can’t see or change it.") + (footnote.map { " " + $0 } ?? ""),
                         trailing: { EmptyView() }) {
            DNSProviderMenu(choice: choice)
            .fixedSize()
            .disabled(dns.prefs == nil || dns.isManaged)
            .onAppear { dns.refresh() }
            .onChange(of: liveCustom, initial: true) { if let liveCustom { customText = liveCustom } }
        }
        if showsCustom {
            SettingsCardDivider()
            SettingsCardRow {
                TextField(BrowserLocalization.text("Custom provider"), text: $customText, prompt: Text("https://dns.example/dns-query{?dns}"))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
                    .onSubmit(saveCustom)
                    .disabled(dns.isManaged)
            } trailing: {
                Button("Use", action: saveCustom)
                    .disabled(dns.isManaged || customText.trimmingCharacters(in: .whitespacesAndNewlines) == liveCustom)
            }
        }
    }

    private var current: SecureDNSChoice { dns.prefs?.choice ?? .automatic }
    private var liveCustom: String? { current == .custom ? dns.prefs?.templates : nil }
    private var showsCustom: Bool { editingCustom || current == .custom }

    private var choice: Binding<SecureDNSChoice> {
        Binding(get: { editingCustom ? .custom : current }, set: { new in
            error = nil
            if new == .custom {
                if !showsCustom { customText = "" }
                editingCustom = true
                return
            }
            editingCustom = false
            if let prefs = SecureDNSPrefs(new), !dns.apply(prefs) { error = BrowserLocalization.text("Cra couldn’t change secure DNS.") }
        })
    }

    private func saveCustom() {
        guard let prefs = SecureDNSPrefs(.custom, custom: customText) else {
            error = "Enter one or more https:// templates, like https://dns.example/dns-query{?dns}."
            return
        }
        error = nil
        if dns.apply(prefs) {
            editingCustom = false
            customText = prefs.templates
        } else {
            error = BrowserLocalization.text("Cra couldn’t change secure DNS.")
        }
    }
}
