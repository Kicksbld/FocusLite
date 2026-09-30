import SwiftUI

/// Main screen after onboarding: filtered Instagram with a minimal native toolbar.
struct BrowserView: View {
    @Environment(BrowserModel.self) private var browser
    @State private var showsSettings = false

    var body: some View {
        InstagramWebView(model: browser)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                toolbar
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
            .sheet(isPresented: $showsSettings) {
                SettingsView()
            }
    }

    private var toolbar: some View {
        HStack {
            ToolbarButton(title: "Retour", systemImage: "chevron.backward") { browser.goBack() }
                .disabled(!browser.canGoBack)
            ToolbarButton(title: "Accueil", systemImage: "house") { browser.open(URLPolicy.home) }
            ToolbarButton(title: "Recherche", systemImage: "magnifyingglass") { browser.open(URLPolicy.search) }
            ToolbarButton(title: "Messages", systemImage: "paperplane") { browser.open(URLPolicy.inbox) }
            ToolbarButton(title: "Recharger", systemImage: "arrow.clockwise") { browser.reload() }
            ToolbarButton(title: "Réglages", systemImage: "gearshape") { showsSettings = true }
        }
        .padding(.vertical, 8)
        .background(.bar)
    }
}

private struct ToolbarButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3)
                .frame(maxWidth: .infinity, minHeight: 36)
        }
        .accessibilityLabel(title)
    }
}
