import SwiftUI

struct RootView: View {
    @AppStorage("onboarding.completed") private var onboardingCompleted = false
    @Environment(AuthorizationManager.self) private var auth
    @Environment(\.scenePhase) private var scenePhase
    /// Service shown full screen; `nil` shows the home screen.
    @State private var openService: Service?

    var body: some View {
        Group {
            if !onboardingCompleted {
                OnboardingView { onboardingCompleted = true }
            } else if let service = openService {
                switch service {
                case .instagram: BrowserView { openService = nil }
                }
            } else {
                HomeView { openService = $0 }
            }
        }
        .animation(.default, value: openService)
        // Permissions can be revoked in Settings while the app is in the background,
        // and the shields must match the stored state (safety net).
        .onChange(of: scenePhase, initial: true) { _, phase in
            guard phase == .active else { return }
            Task {
                await auth.refresh()
                if auth.screenTime == .granted {
                    BlockingManager.applyExpectedState()
                }
            }
        }
    }
}

#Preview {
    RootView()
        .environment(AuthorizationManager())
        .environment(BlockingSettings())
        .environment(BrowserModel())
}
