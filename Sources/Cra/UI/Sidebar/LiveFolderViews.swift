import AppKit
import SwiftUI

/// A live folder row's warning button, from `LiveFolderData.alert`.
struct LiveFolderWarning: Equatable {
    var symbol: String
    var help: String
    var signInURL: String?
}

@MainActor
enum LiveFolderText {
    private static let relative: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return f
    }()

    static func lastUpdate(_ live: LiveFolderData) -> String {
        if let error = live.lastError { return status(error, live: live) }
        guard let last = live.lastFetch else { return BrowserLocalization.text("Not updated yet") }
        if Date().timeIntervalSince(last) < 60 { return BrowserLocalization.text("Updated just now") }
        return "Updated \(relative.localizedString(for: last, relativeTo: Date()))"
    }

    static func refreshHelp(_ live: LiveFolderData?) -> String {
        guard let live, live.lastFetch != nil else { return "Refresh" }
        return "Refresh · \(lastUpdate(live))"
    }

    /// The folder's warning button: Arc's glyph (a key for single sign-on, #521) and tip, and where a
    /// click signs in (nil: it tries again).
    static func warning(_ live: LiveFolderData) -> LiveFolderWarning? {
        guard let alert = live.alert else { return nil }
        if case .failed(let error) = alert {
            return LiveFolderWarning(symbol: alert.symbol, help: BrowserLocalization.format("%1$@. Click to try again.", "\(status(error, live: live))"), signInURL: nil)
        }
        return LiveFolderWarning(symbol: alert.symbol, help: alert.help ?? "", signInURL: alert.url)
    }

    static func status(_ error: LiveFolderError, live: LiveFolderData) -> String {
        LiveFolderPluginStore.shared.entry(for: live)?.presentation.statusMessages[error.rawValue] ?? BrowserLocalization.text("Failed to update")
    }
}
