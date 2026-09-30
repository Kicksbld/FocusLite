import Foundation

/// `focuslite://open?path=<path>` opens the Instagram browser on `https://www.instagram.com<path>` (spec F6).
/// Built by the Shield Action extension (F3), parsed by the app.
enum DeepLink {
    static let scheme = "focuslite"
    /// Key of the deep link, as a URL string, in a local notification's `userInfo`.
    static let userInfoKey = "deepLink"
    /// Default target of the shield redirect: the DM inbox.
    static let inboxPath = "/direct/inbox/"

    private static let openHost = "open"
    private static let pathItem = "path"
    private static let instagramHost = "www.instagram.com"

    static func open(path: String) -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = openHost
        components.queryItems = [URLQueryItem(name: pathItem, value: path)]
        return components.url!
    }

    /// The instagram.com page `url` points to, or `nil` if `url` is not a valid FocusLite deep link.
    /// A missing path means the home page. The caller still applies `URLPolicy`.
    static func instagramURL(from url: URL) -> URL? {
        guard url.scheme?.lowercased() == scheme, url.host()?.lowercased() == openHost else { return nil }
        let path = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == pathItem }?.value ?? "/"
        // Require an absolute path, so the path can't change the host (e.g. "@evil.com" as user info).
        guard path.hasPrefix("/"), !path.hasPrefix("//"),
              let target = URL(string: "https://\(instagramHost)\(path)"),
              target.host() == instagramHost
        else { return nil }
        return target
    }
}
