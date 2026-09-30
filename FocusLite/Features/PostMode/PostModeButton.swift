import SwiftUI

/// "Mode Poster" button, replaced by the countdown while Post Mode runs.
/// Used in the browser's top bar and in Settings.
struct PostModeButton: View {
    @Environment(PostModeModel.self) private var postMode
    @Environment(AuthorizationManager.self) private var auth
    @Environment(BlockingSettings.self) private var blocking

    var body: some View {
        Group {
            if let endsAt = postMode.endsAt {
                Label {
                    Text(endsAt, style: .timer).monospacedDigit()
                } icon: {
                    Image(systemName: "timer")
                }
                .labelStyle(.titleAndIcon)
                .accessibilityLabel(Text("Mode Poster, fin dans \(Text(endsAt, style: .timer))"))
            } else {
                Button { postMode.start() } label: {
                    Label("Mode Poster", systemImage: "plus.app")
                }
                // Nothing to unlock when blocking is off.
                .disabled(auth.screenTime != .granted || !blocking.isEnabled)
            }
        }
        .alert(
            "Mode Poster impossible",
            isPresented: Binding(
                get: { postMode.errorMessage != nil },
                set: { if !$0 { postMode.errorMessage = nil } }
            )
        ) {
            Button("OK") {}
        } message: {
            Text(postMode.errorMessage ?? "")
        }
    }
}
