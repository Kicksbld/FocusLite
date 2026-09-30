import Foundation

/// Filtered web services opened from the home screen.
enum Service: String, CaseIterable, Identifiable {
    case instagram
    case youtube

    var id: Self { self }

    var title: String {
        switch self {
        case .instagram: "Instagram"
        case .youtube: "YouTube"
        }
    }

    var detail: String {
        switch self {
        case .instagram: "Messages, profils, posts et stories, sans Reels ni Explorer."
        case .youtube: "Vidéos, chaînes et recherche, sans Shorts."
        }
    }

    var systemImage: String {
        switch self {
        case .instagram: "camera"
        case .youtube: "play.rectangle"
        }
    }

    /// First page, and the fallback after a blocked first load. m.youtube.com is YouTube's mobile site.
    var home: URL {
        switch self {
        case .instagram: URL(string: "https://www.instagram.com/")!
        case .youtube: URL(string: "https://m.youtube.com/")!
        }
    }

    /// Toast shown when a navigation is blocked.
    var blockedMessage: String {
        switch self {
        case .instagram: "Reels bloqués"
        case .youtube: "Shorts bloqués"
        }
    }

    /// Built from `web/src/<name>.ts`, in the app bundle.
    var filterScriptName: String {
        switch self {
        case .instagram: "instagram-filter"
        case .youtube: "youtube-filter"
        }
    }

    /// Post Mode unlocks the native Instagram app, so it only makes sense next to Instagram.
    var offersPostMode: Bool { self == .instagram }
}
