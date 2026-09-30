import SwiftUI

/// A filtered service. The site's own bottom bar handles navigation inside it;
/// the thin top bar only holds FocusLite actions (home screen, and Post Mode next to Instagram).
struct BrowserView: View {
    let model: BrowserModel
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            BrowserWebView(model: model)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(model.service.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: onClose) {
                            Label("Accueil", systemImage: "square.grid.2x2")
                        }
                    }
                    if model.service.offersPostMode {
                        ToolbarItem(placement: .topBarTrailing) {
                            PostModeToolbarItem()
                        }
                    }
                }
                .overlay(alignment: .top) {
                    if let toast = model.toast {
                        Label(toast, systemImage: "hand.raised.fill")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.regularMaterial, in: Capsule())
                            .padding(.top, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.snappy, value: model.toast)
        }
    }
}
