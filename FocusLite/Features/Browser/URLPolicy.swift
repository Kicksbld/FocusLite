import Foundation

/// URL rules of the filtered browsers (spec F4), applied to full page loads.
/// Keep in sync with `web/src/instagram-policy.ts` and `web/src/youtube-policy.ts`,
/// which apply the same rules to in-page navigation.
enum URLPolicy {
    enum Decision: Equatable {
        case allow
        /// Reels, Explore or Shorts: cancel and show the service's toast.
        case block
        /// Not the service's site: open in Safari.
        case openExternally
        /// Load this URL instead, without a toast.
        case redirect(URL)
    }

    static func decision(for url: URL, service: Service, allowSingleReels: Bool) -> Decision {
        switch url.scheme?.lowercased() {
        case "http", "https":
            break
        case "about", "blob", "data":
            return .allow
        default:
            return .openExternally
        }
        guard let host = url.host()?.lowercased() else { return .openExternally }
        let path = normalizedPath(url.path(percentEncoded: false))
        switch service {
        case .instagram:
            guard Instagram.isHost(host) else { return .openExternally }
            if let target = Instagram.redirects[path] { return .redirect(target) }
            return Instagram.isBlockedPath(path, allowSingleReels: allowSingleReels) ? .block : .allow
        case .youtube:
            guard YouTube.isHost(host) else { return .openExternally }
            return YouTube.isBlockedPath(path) ? .block : .allow
        }
    }

    /// Lowercased, with a trailing slash so `/reels` matches `/reels/`.
    private static func normalizedPath(_ rawPath: String) -> String {
        let path = rawPath.lowercased()
        return path.hasSuffix("/") ? path : path + "/"
    }

    private enum Instagram {
        /// `/reels/` also covers `/reels/<id>/`, which opens a reel inside the scrollable Reels feed.
        static let blockedPrefixes = ["/reels/", "/explore/"]
        /// Exceptions to `blockedPrefixes`: account search lives under Explore on mobile.
        static let allowedPrefixes = ["/explore/search/"]
        static let singleReelPrefix = "/reel/"
        /// Instagram's own search button links to `/explore/`: open search rather than the Explore grid.
        static let redirects = ["/explore/": URL(string: "https://www.instagram.com/explore/search/")!]

        static func isHost(_ host: String) -> Bool {
            host == "instagram.com" || host.hasSuffix(".instagram.com")
        }

        static func isBlockedPath(_ path: String, allowSingleReels: Bool) -> Bool {
            if allowedPrefixes.contains(where: path.hasPrefix) { return false }
            if blockedPrefixes.contains(where: path.hasPrefix) { return true }
            return !allowSingleReels && path.hasPrefix(singleReelPrefix)
        }
    }

    private enum YouTube {
        /// Also Google's domain: sign-in (accounts.google.com) and cookie consent must stay in the WebView,
        /// or the session is created in Safari instead.
        static func isHost(_ host: String) -> Bool {
            ["youtube.com", "google.com"].contains { host == $0 || host.hasSuffix("." + $0) } || host == "youtu.be"
        }

        /// A `shorts` path segment: `/shorts/<id>` (the Shorts player, which swipes to the next Short)
        /// and a channel's Shorts tab (`/@name/shorts`). An exact segment, so `/@name.shorts` stays allowed.
        static func isBlockedPath(_ path: String) -> Bool {
            path.split(separator: "/").contains("shorts")
        }
    }
}
