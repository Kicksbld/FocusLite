import SwiftUI
import WebKit

/// Hosts the long-lived WebView owned by `BrowserModel`.
struct BrowserWebView: UIViewRepresentable {
    let model: BrowserModel

    func makeUIView(context: Context) -> WKWebView {
        model.webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}
}
