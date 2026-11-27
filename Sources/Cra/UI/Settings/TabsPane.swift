import SwiftUI

/// Settings ▸ Tabs. Dia draws this pane as a two-column form of checkboxes, whose titles didn't
/// say what each one did. Cra gives every setting a line saying what it changes, and the ones
/// that change how Cra looks a picture of it, the way Arc's Max pane draws a feature. The address
/// bar picks between onboarding's two layout pictures. Links have a pane of their own, as in Arc.
struct TabsPane: View {
    @Environment(SidebarStore.self) private var store
    @State private var showsKeepActiveSites = false

    var body: some View {
        @Bindable var store = store
        SettingsCardPane {
            // #305: onboarding's "Choose where the address bar goes". Arc keeps it in View ▸ Show Toolbar.
            SettingsHeader(BrowserLocalization.text("Address bar"))
            SettingsFeatureCard {
                HStack(spacing: 12) {
                    ForEach(AddressBarPlacement.allCases, id: \.self) { placement in
                        AddressBarTile(placement: placement, selection: $store.settings.addressBarPlacement)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
            }
            SettingsFootnote(BrowserLocalization.format("%1$@ in any window, or the View menu’s Show Toolbar, switches it too.", "\(KeyBindingRegistry.shared.action("toggleToolbar")?.primary?.display ?? "⇧⌘D")"))
            SettingsFeatureCard {
                // GitHub #344, not in Arc: Arc's address opens its address panel on a click (#663).
                // It applies to the toolbar's address as well (Discord #help, 25 Nov).
                SettingsToggleRow(BrowserLocalization.text("Edit the address in place"),
                                  detail: BrowserLocalization.format("Clicking the address, at the top of the sidebar or in the toolbar, lets you edit it right there instead of opening the command bar. %1$@ still opens the command bar.", "\(KeyBindingRegistry.shared.action("editURL")?.primary?.display ?? "⌘L")"),
                                  isOn: $store.settings.editAddressInPlace)
            }
            .padding(.top, 12)

            // Settings that change how Cra looks carry a picture of the change.
            SettingsHeader(BrowserLocalization.text("Sidebar")).padding(.top, 20)
            SettingsFeatureCard {
                SettingsSwitchRow(BrowserLocalization.text("New tabs at the top"),
                                  detail: BrowserLocalization.text("A new tab goes above your other tabs instead of below them."),
                                  isOn: $store.settings.newTabsAtTop) { SettingsArt.newTabsAtTop }
                SettingsCardDivider()
                SettingsSwitchRow(BrowserLocalization.text("New Tab button above tabs"),
                                  detail: BrowserLocalization.text("The + New Tab row sits at the top of the tab list, where you can always reach it."),
                                  isOn: $store.settings.newTabButtonAtTop) { SettingsArt.newTabButtonAtTop }
                SettingsCardDivider()
                SettingsSwitchRow(BrowserLocalization.text("Colorful favorite outline"),
                                  detail: BrowserLocalization.text("The open favorite gets a rim in its logo’s colors instead of a plain one."),
                                  isOn: $store.settings.favoriteLogoOutline) { SettingsArt.favoriteLogoOutline }
                SettingsCardDivider()
                // Arc's single-space mode ("Hide Space Header" on the space's menu), for people who
                // don't use spaces.
                SettingsSwitchRow(BrowserLocalization.text("Space header with one space"),
                                  detail: BrowserLocalization.text("Show the space’s name at the top and its icon at the bottom of the sidebar, even while you have only one space."),
                                  isOn: $store.settings.showSpaceHeaderOnSingleSpace) { SettingsArt.spaceHeader }
                SettingsCardDivider()
                // GitHub #464, not in Arc: the window's layout in a mirror (SidebarSide).
                SettingsSwitchRow(BrowserLocalization.text("Sidebar on the right"),
                                  detail: BrowserLocalization.text("The sidebar, with the window’s close, minimize and zoom buttons, sits on the right of the window. Hidden, it slides in from the right edge."),
                                  isOn: Binding(get: { store.settings.sidebarSide == .right },
                                                set: { store.settings.sidebarSide = $0 ? .right : .left })) { SettingsArt.sidebarOnRight }
                SettingsCardDivider()
                // Ideas #366, not in Arc: the space's colours thin over a glass (SidebarGlass).
                SettingsSwitchRow(BrowserLocalization.text("Translucent sidebar"),
                                  detail: BrowserLocalization.text("The sidebar and the window around your pages turn to glass, so what’s behind the window shows through, darkened on a dark theme. The floating sidebar lets the page under it show through."),
                                  isOn: $store.settings.translucentSidebar) { SettingsArt.translucentSidebar }
                SettingsCardDivider()
                // Ideas #366, not in Arc: the now-playing cards in the sidebar's colour (NowPlayingTint).
                SettingsSwitchRow(BrowserLocalization.text("Player in the space’s colour"),
                                  detail: BrowserLocalization.text("The now-playing player at the bottom of the sidebar takes your space’s colour, like a selected tab, instead of Arc’s white or black."),
                                  isOn: Binding(get: { store.settings.nowPlayingTint == .theme },
                                                set: { store.settings.nowPlayingTint = $0 ? .theme : .arc })) { SettingsArt.nowPlayingTint }
            }

            SettingsHeader(BrowserLocalization.text("Pages")).padding(.top, 20)
            SettingsFeatureCard {
                // Ideas #366, not in Arc: the room round the pages (PageMargin); Edge to edge is its zero.
                SettingsFeatureRow(BrowserLocalization.text("Margin"),
                                   detail: BrowserLocalization.text("How much room is left around your pages, from 1 pt to Arc’s 10 pt. Edge to edge takes it away."),
                                   picture: { SettingsArt.pageMargin(store.settings.pageMargin) },
                                   trailing: { SettingsMarginSlider(margin: $store.settings.pageMargin, enabled: !store.settings.edgeToEdgeContent) })
                SettingsCardDivider()
                SettingsSwitchRow(BrowserLocalization.text("Edge to edge"),
                                  detail: BrowserLocalization.text("Pages fill the window, with no margin around them and square corners, unless Rounded corners is on."),
                                  isOn: $store.settings.edgeToEdgeContent) { SettingsArt.edgeToEdge }
                SettingsCardDivider()
                // Ideas #582, not in Arc: edge to edge keeps the round (CardFill.cornerRadius).
                SettingsSwitchRow(BrowserLocalization.text("Rounded corners"),
                                  detail: BrowserLocalization.text("Edge to edge, pages keep rounded corners, still with no margin or shadow around them. In a split every page is rounded."),
                                  isOn: $store.settings.edgeToEdgeRoundedCorners,
                                  enabled: store.settings.edgeToEdgeContent) { SettingsArt.edgeToEdgeRounded }
                SettingsCardDivider()
                // Not in Arc (#404): the toolbar floats over the page (ToolbarAutoHide).
                SettingsSwitchRow(BrowserLocalization.text("Hide the toolbar until you need it"),
                                  detail: BrowserLocalization.text("The page takes the toolbar’s room. Move the pointer to the top of the page and the toolbar slides in over it."),
                                  isOn: $store.settings.autoHideToolbar,
                                  enabled: store.settings.addressBarPlacement == .toolbar) { SettingsArt.autoHideToolbar }
            }

            SettingsHeader(BrowserLocalization.text("Tabs and Favorites")).padding(.top, 20)
            SettingsFeatureCard {
                // #154: Arc's favorites, one set per profile.
                SettingsToggleRow(BrowserLocalization.text("Share Favorites across Spaces"),
                                  detail: BrowserLocalization.text("Spaces on the same profile show the same Favorites, as in Arc. Turning it on combines their Favorites; turning it off gives each Space its own copy."),
                                  isOn: Binding(get: { store.settings.sharedFavorites }, set: { store.setFavoritesShared($0) }))
                SettingsCardDivider()
                // GitHub #601, not in Arc: Arc's ⇧⌘T switches to the space of the tab closed last.
                SettingsToggleRow(BrowserLocalization.text("Reopen tabs from this Space only"),
                                  detail: BrowserLocalization.text("Restore Last Closed Tab (⇧⌘T) brings back the tab you closed last in the Space you’re in, instead of switching to another Space."),
                                  isOn: $store.settings.reopenClosedTabCurrentSpaceOnly)
            }

            SettingsHeader(BrowserLocalization.text("Memory")).padding(.top, 20)
            SettingsFeatureCard {
                // Tab sleeping (GitHub #153): Arc's 4 hours and nothing more unless you ask.
                SettingsToggleRow(BrowserLocalization.text("Free memory from unused tabs"),
                                  detail: BrowserLocalization.text("A tab you haven’t used for a while is forced out of memory and reloads when you open it."),
                                  isOn: $store.settings.tabSleepTimerEnabled) {
                    SettingsInlinePicker(label: BrowserLocalization.text("After"), selection: $store.settings.tabSleepAfter, enabled: store.settings.tabSleepTimerEnabled) {
                        ForEach(TabSleepThreshold.allCases) { Text(BrowserLocalization.text($0.label)).tag($0) }
                    }
                }
                SettingsCardDivider()
                SettingsToggleRow(BrowserLocalization.text("Free memory when the Mac runs short"),
                                  detail: BrowserLocalization.text("While macOS is short of memory, the tabs hidden longest are forced out of it, a few at a time."),
                                  isOn: $store.settings.tabSleepOnMemoryPressure)
                SettingsCardDivider()
                // #458: Arc's (and Chrome's) list at arc://settings/performance.
                SettingsPlainRow(BrowserLocalization.text("Always keep these sites active"), detail: keepActiveDetail) {
                    Button(BrowserLocalization.text("Sites…")) { showsKeepActiveSites = true }
                }
            }
            SettingsFootnote(tabSleepNote)
        }
        .sheet(isPresented: $showsKeepActiveSites) {
            KeepActiveSitesView().environment(store)
        }
    }

    private var keepActiveDetail: String {
        let lead = BrowserLocalization.text("Tabs on these sites stay in memory and keep running, however long they’re hidden.")
        switch store.settings.keepActiveSites.count {
        case 0: return lead
        case 1: return lead + " 1 site listed."
        case let n: return lead + " \(n) sites listed."
        }
    }

    /// Says which tabs stay in memory, before the user finds out.
    private var tabSleepNote: String {
        let s = store.settings
        var note = BrowserLocalization.text("Tabs playing sound, recording or holding text you typed stay in memory.")
        if s.tabSleepTimerEnabled, TabSleepPolicy.timer(s.tabSleepAfter).keepsRecentTabs {
            note += s.tabSleepOnMemoryPressure ? " So do the 10 tabs you used last, unless the Mac is short of memory." : " So do the 10 tabs you used last."
        }
        // #458: Chrome's urgent discarding takes kept sites after every other tab; say so where it applies.
        if !s.keepActiveSites.isEmpty, s.tabSleepOnMemoryPressure {
            note += " Sites you keep active are the last to go when the Mac is short of memory."
        }
        return note
    }
}

/// One of the two address bar layouts: onboarding's picture (Dia's TabLayout artwork) with a
/// ring when picked, its name and where that puts the address bar underneath.
private struct AddressBarTile: View {
    let placement: AddressBarPlacement
    @Binding var selection: AddressBarPlacement
    @Environment(\.colorScheme) private var scheme

    private static let width: CGFloat = 150

    var body: some View {
        let selected = selection == placement
        let k = Self.width / 230
        VStack(spacing: 4) {
            LayoutArt(toolbar: placement == .toolbar, selected: selected, dark: scheme == .dark)
                .frame(width: 230, height: 180)
                .scaleEffect(k, anchor: .topLeading)
                .frame(width: 230 * k, height: 180 * k, alignment: .topLeading)
            Text(placement.title).font(.system(size: 13, weight: selected ? .semibold : .regular))
            Text(placement.detail).font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture { withAnimation(.easeOut(duration: 0.15)) { selection = placement } }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(BrowserLocalization.format("%1$@: the address bar %2$@", "\(placement.title)", "\(placement.detail.lowercased())"))
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction { selection = placement }
    }
}
