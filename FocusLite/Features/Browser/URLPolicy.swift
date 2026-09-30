import Foundation

/// URL rules of the Instagram browser (spec F4), applied to full page loads.
/// Keep in sync with `web/src/policy.ts`, which applies the same rules to in-page navigation.
enum URLPolicy {
    enum Decision: Equatable {
        case allow
        /// Reels or Explore: cancel and show the "Reels bloqués" toast.
        case block
        /// Not instagram.com: open in Safari.
        case openExternally
    }

    static let home = URL(string: "https://www.instagram.com/")!
    static let inbox = URL(string: "https://www.instagram.com/direct/inbox/")!
    static let search = URL(string: "https://www.instagram.com/explore/search/")!

    /// `/reels/` also covers `/reels/<id>/`, which opens a reel inside the scrollable Reels feed.
    private static let blockedPrefixes = ["/reels/", "/explore/"]
    /// Exceptions to `blockedPrefixes`: account search lives under Explore on mobile.
    private static let allowedPrefixes = ["/explore/search/"]
    private static let singleReelPrefix = "/reel/"

    static func decision(for url: URL, allowSingleReels: Bool) -> Decision {
        switch url.scheme?.lowercased() {
        case "http", "https":
            break
        case "about", "blob", "data":
            return .allow
        default:
            return .openExternally
        }
        guard let host = url.host()?.lowercased(), isInstagramHost(host) else {
            return .openExternally
        }
        return isBlockedPath(url.path(percentEncoded: false), allowSingleReels: allowSingleReels) ? .block : .allow
    }

    private static func isInstagramHost(_ host: String) -> Bool {
        host == "instagram.com" || host.hasSuffix(".instagram.com")
    }

    private static func isBlockedPath(_ rawPath: String, allowSingleReels: Bool) -> Bool {
        let lowercased = rawPath.lowercased()
        // Trailing slash so `/reels` matches `/reels/`.
        let path = lowercased.hasSuffix("/") ? lowercased : lowercased + "/"
        if allowedPrefixes.contains(where: path.hasPrefix) { return false }
        if blockedPrefixes.contains(where: path.hasPrefix) { return true }
        return !allowSingleReels && path.hasPrefix(singleReelPrefix)
    }
}
