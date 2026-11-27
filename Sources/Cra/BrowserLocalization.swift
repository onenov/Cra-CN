import Foundation

/// Looks up browser-owned interface strings in the app's selected language.
enum BrowserLocalization {
    static func text(_ english: String) -> String {
        Bundle.main.localizedString(forKey: english, value: english, table: nil)
    }

    /// Numbered placeholders let each language order display values independently.
    static func format(_ english: String, _ values: String...) -> String {
        String(format: text(english), arguments: values)
    }
}
