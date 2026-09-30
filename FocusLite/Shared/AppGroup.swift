import Foundation

/// App Group shared by the app and its three extensions (spec §6).
enum AppGroup {
    static let identifier = "group.com.killianboularand.focuslite"

    /// UserDefaults backed by the App Group container.
    static var defaults: UserDefaults {
        guard let defaults = UserDefaults(suiteName: identifier) else {
            fatalError("App Group \(identifier) is not configured for this target")
        }
        return defaults
    }

    /// Keys stored in `defaults`. Define every shared key here and nowhere else.
    enum Key {
        /// `FamilyActivitySelection` encoded as JSON. Instagram: shield offers "Ouvrir FocusLite".
        static let selectionRedirect = "selection.redirect"
        /// `FamilyActivitySelection` encoded as JSON. TikTok, etc.: shield offers only "Fermer".
        static let selectionHardBlock = "selection.hardBlock"
        /// `Bool`. Global "Blocage actif" toggle.
        static let blockingEnabled = "blocking.enabled"
        /// `Date?`. End of Post Mode, written by the app and the Monitor extension.
        static let postModeEndsAt = "postMode.endsAt"
        /// `Bool`, default `true`. Allows single reels `/reel/<id>/` in the browser.
        static let browserAllowSingleReels = "browser.allowSingleReels"
    }
}
