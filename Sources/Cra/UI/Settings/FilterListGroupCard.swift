import SwiftUI

struct FilterListGroupCard<Rows: View>: View {
    let title: String
    let selected: Int
    let total: Int
    @State var isExpanded: Bool
    @ViewBuilder let rows: () -> Rows

    var body: some View {
        let summary = BrowserLocalization.format("%1$@ of %2$@ selected", String(selected), String(total))
        SettingsFeatureCard {
            Button { isExpanded.toggle() } label: {
                SettingsCardRow {
                    Text(BrowserLocalization.text(title)).fontWeight(.medium)
                } trailing: {
                    Text(summary).foregroundStyle(.secondary).monospacedDigit()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.forward")
                        .font(.caption).foregroundStyle(.secondary).accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(BrowserLocalization.text(title))
            .accessibilityValue(BrowserLocalization.format(isExpanded ? "Expanded, %1$@" : "Collapsed, %1$@", summary))
            if isExpanded { rows() }
        }
    }
}
