import SwiftUI

/// A filtered service. The site's own bottom bar handles navigation inside it;
/// the thin top bar only holds FocusLite actions (home screen, and Post Mode next to Instagram).
struct BrowserView: View {
    let model: BrowserModel
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            BrowserWebView(model: model)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(model.service.title)
                .navigationBarTitleDisplayMode(.inline)
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
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .glassEffect(.regular, in: .capsule)
                            .padding(.top, 8)
                            // Enters and leaves by the same edge; a plain fade with Reduce Motion.
                            .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.snappy, value: model.toast)
                .sensoryFeedback(.warning, trigger: model.toast) { _, toast in toast != nil }
                .onChange(of: model.toast) { _, toast in
                    if let toast { AccessibilityNotification.Announcement(toast).post() }
                }
        }
    }
}
