import SwiftUI

/// Filtered Instagram. The site's own bottom bar handles navigation inside Instagram;
/// the thin top bar only holds FocusLite actions (home screen, and Post Mode with F5).
struct BrowserView: View {
    let onClose: () -> Void

    @Environment(BrowserModel.self) private var browser

    var body: some View {
        NavigationStack {
            InstagramWebView(model: browser)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(Service.instagram.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: onClose) {
                            Label("Accueil", systemImage: "square.grid.2x2")
                        }
                    }
                }
                .overlay(alignment: .top) {
                    if let toast = browser.toast {
                        Label(toast, systemImage: "hand.raised.fill")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.regularMaterial, in: Capsule())
                            .padding(.top, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.snappy, value: browser.toast)
        }
    }
}
