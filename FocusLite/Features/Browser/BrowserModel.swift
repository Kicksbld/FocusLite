import Observation
import UIKit
import WebKit

/// Owns the Instagram WebView for the app's whole lifetime, so the page survives
/// going back to the home screen.
@MainActor
@Observable
final class BrowserModel {
    let webView: WKWebView
    /// Message of the toast currently shown, if any.
    private(set) var toast: String?
    private(set) var allowSingleReels: Bool

    @ObservationIgnored private let coordinator = WebViewCoordinator()
    @ObservationIgnored private let filterScript: String
    @ObservationIgnored private var toastTask: Task<Void, Never>?

    init() {
        allowSingleReels = AppGroup.defaults.object(forKey: AppGroup.Key.browserAllowSingleReels) as? Bool ?? true
        filterScript = Self.loadFilterScript()

        let configuration = WKWebViewConfiguration()
        // Persistent cookies: the Instagram session survives app restarts.
        configuration.websiteDataStore = .default()
        configuration.applicationNameForUserAgent = Self.safariApplicationName
        webView = WKWebView(frame: .zero, configuration: configuration)

        coordinator.model = self
        configuration.userContentController.add(coordinator, name: WebViewCoordinator.messageHandlerName)
        installUserScripts()

        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        // Back is the edge swipe, reload is pull-to-refresh: no native buttons for either.
        webView.allowsBackForwardNavigationGestures = true
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(coordinator, action: #selector(WebViewCoordinator.pullToRefresh(_:)), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl
        #if DEBUG
        // Lets desktop Safari's Web Inspector attach to the WebView.
        webView.isInspectable = true
        #endif

        webView.load(URLRequest(url: URLPolicy.home))
    }

    func decision(for url: URL) -> URLPolicy.Decision {
        URLPolicy.decision(for: url, allowSingleReels: allowSingleReels)
    }

    /// Opens `url` according to `URLPolicy`: in the WebView, in Safari, or not at all.
    func open(_ url: URL) {
        switch decision(for: url) {
        case .allow: webView.load(URLRequest(url: url))
        case .block: showBlockedToast()
        case .openExternally: UIApplication.shared.open(url)
        case .redirect(let target): webView.load(URLRequest(url: target))
        }
    }

    func reload() {
        webView.reload()
    }

    func showBlockedToast() {
        toast = "Reels bloqués"
        toastTask?.cancel()
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            toast = nil
        }
    }

    func setAllowSingleReels(_ allow: Bool) {
        allowSingleReels = allow
        AppGroup.defaults.set(allow, forKey: AppGroup.Key.browserAllowSingleReels)
        installUserScripts()
        // Current page: update the config, then re-run the idempotent filter so it re-checks the URL.
        webView.evaluateJavaScript(configScript + "\n" + filterScript, completionHandler: nil)
    }

    // MARK: - Injected scripts

    /// Read by the filter script on every check (`window.__focusLiteConfig`).
    private var configScript: String {
        "window.__focusLiteConfig = { allowSingleReels: \(allowSingleReels) };"
    }

    /// The config must come first: both run at document start, in insertion order.
    private func installUserScripts() {
        let controller = webView.configuration.userContentController
        controller.removeAllUserScripts()
        for source in [configScript, filterScript] {
            controller.addUserScript(WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        }
    }

    private static func loadFilterScript() -> String {
        guard let url = Bundle.main.url(forResource: "instagram-filter", withExtension: "js"),
              let source = try? String(contentsOf: url, encoding: .utf8)
        else {
            fatalError("instagram-filter.js is missing from the app bundle. Run `npm run build` in web/.")
        }
        return source
    }

    /// Appended to WebKit's own prefix, gives the exact iOS Safari User-Agent,
    /// so instagram.com serves its mobile site.
    private static var safariApplicationName: String {
        let version = UIDevice.current.systemVersion.split(separator: ".").prefix(2).joined(separator: ".")
        return "Version/\(version) Mobile/15E148 Safari/604.1"
    }
}
