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
        /// Load this URL instead, without a toast.
        case redirect(URL)
    }

    static let home = URL(string: "https://www.instagram.com/")!

    /// `/reels/` also covers `/reels/<id>/`, which opens a reel inside the scrollable Reels feed.
    private static let blockedPrefixes = ["/reels/", "/explore/"]
    /// Exceptions to `blockedPrefixes`: account search lives under Explore on mobile.
    private static let allowedPrefixes = ["/explore/search/"]
    private static let singleReelPrefix = "/reel/"
    /// Instagram's own search button links to `/explore/`: open search rather than the Explore grid.
    private static let redirects = ["/explore/": URL(string: "https://www.instagram.com/explore/search/")!]

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
        let path = normalizedPath(url.path(percentEncoded: false))
        if let target = redirects[path] { return .redirect(target) }
        return isBlockedPath(path, allowSingleReels: allowSingleReels) ? .block : .allow
    }

    private static func isInstagramHost(_ host: String) -> Bool {
        host == "instagram.com" || host.hasSuffix(".instagram.com")
    }

    /// Lowercased, with a trailing slash so `/reels` matches `/reels/`.
    private static func normalizedPath(_ rawPath: String) -> String {
        let path = rawPath.lowercased()
        return path.hasSuffix("/") ? path : path + "/"
    }

    private static func isBlockedPath(_ path: String, allowSingleReels: Bool) -> Bool {
        if allowedPrefixes.contains(where: path.hasPrefix) { return false }
        if blockedPrefixes.contains(where: path.hasPrefix) { return true }
        return !allowSingleReels && path.hasPrefix(singleReelPrefix)
    }
}
