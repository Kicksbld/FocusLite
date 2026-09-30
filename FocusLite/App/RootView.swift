import SwiftUI

struct RootView: View {
    @AppStorage("onboarding.completed") private var onboardingCompleted = false
    @Environment(AuthorizationManager.self) private var auth
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if onboardingCompleted {
                SettingsView()
            } else {
                OnboardingView { onboardingCompleted = true }
            }
        }
        // Permissions can be revoked in Settings while the app is in the background.
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active {
                Task { await auth.refresh() }
            }
        }
    }
}

#Preview {
    RootView()
        .environment(AuthorizationManager())
}
