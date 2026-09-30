import UIKit
import WebKit

/// Navigation, window and script-message delegate of the Instagram WebView.
/// Applies `URLPolicy` to full page loads; the injected script covers in-page navigation.
@MainActor
final class WebViewCoordinator: NSObject {
    /// `window.webkit.messageHandlers.focuslite` on the JS side.
    static let messageHandlerName = "focuslite"

    /// Weak: the WebView's content controller retains this coordinator.
    weak var model: BrowserModel?

    @objc func pullToRefresh(_ sender: UIRefreshControl) {
        model?.reload()
    }

    private func endRefreshing(_ webView: WKWebView) {
        webView.scrollView.refreshControl?.endRefreshing()
    }
}

extension WebViewCoordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard let model, let url = navigationAction.request.url else { return .cancel }

        switch navigationAction.targetFrame {
        case .none:
            // target="_blank": no second WebView, open it here or in Safari.
            model.open(url)
            return .cancel
        case .some(let frame) where !frame.isMainFrame:
            // Sub-frames (captchas, embeds) are not pages the user navigates to.
            return .allow
        default:
            break
        }

        switch model.decision(for: url) {
        case .allow:
            return .allow
        case .block:
            model.showBlockedToast()
            // Nothing to stay on (blocked first load): fall back to the home page.
            if webView.url == nil {
                model.open(URLPolicy.home)
            }
            return .cancel
        case .openExternally:
            await UIApplication.shared.open(url)
            return .cancel
        case .redirect(let target):
            webView.load(URLRequest(url: target))
            return .cancel
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        endRefreshing(webView)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        endRefreshing(webView)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        endRefreshing(webView)
    }
}

extension WebViewCoordinator: WKUIDelegate {
    /// `window.open()`: same handling as target="_blank".
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let url = navigationAction.request.url {
            model?.open(url)
        }
        return nil
    }
}

extension WebViewCoordinator: WKScriptMessageHandler {
    /// Messages from `web/src/instagram-filter.ts`: `{ type: "navigation" | "blocked", url }`.
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let model,
              message.frameInfo.isMainFrame,
              let body = message.body as? [String: Any],
              let type = body["type"] as? String,
              let url = (body["url"] as? String).flatMap(URL.init(string:))
        else { return }

        switch type {
        case "blocked":
            model.showBlockedToast()
        case "navigation":
            // The script already filters; if the two policies ever disagree, native wins.
            switch model.decision(for: url) {
            case .block:
                model.showBlockedToast()
                model.open(URLPolicy.home)
            case .redirect:
                model.open(url)
            case .allow, .openExternally:
                break
            }
        default:
            break
        }
    }
}
