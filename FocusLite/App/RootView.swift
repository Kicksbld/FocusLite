import SwiftUI

struct RootView: View {
    @AppStorage("onboarding.completed") private var onboardingCompleted = false
    @Environment(AuthorizationManager.self) private var auth
    @Environment(BrowserModel.self) private var browser
    @Environment(PostModeModel.self) private var postMode
    @Environment(DeepLinkRouter.self) private var router
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
        .onOpenURL { router.pending = $0 }
        .onChange(of: router.pending, initial: true) { _, link in
            if let link { handleDeepLink(link) }
        }
        // Permissions can be revoked in Settings while the app is in the background,
        // and the shields must match the stored state (safety net). This also ends a Post Mode
        // whose end has passed, if the Monitor extension missed it.
        .onChange(of: scenePhase, initial: true) { _, phase in
            guard phase == .active else { return }
            Task {
                await auth.refresh()
                if auth.screenTime == .granted {
                    BlockingManager.applyExpectedState()
                }
                postMode.refresh()
            }
        }
    }

    /// Opens Instagram directly, skipping the home screen. `BrowserModel.open` applies `URLPolicy`:
    /// a blocked path only shows the toast. Invalid links, or links before onboarding, are dropped.
    private func handleDeepLink(_ link: URL) {
        router.pending = nil
        guard onboardingCompleted, let target = DeepLink.instagramURL(from: link) else { return }
        openService = .instagram
        browser.open(target)
    }
}

#Preview {
    RootView()
        .environment(AuthorizationManager())
        .environment(BlockingSettings())
        .environment(BrowserModel())
        .environment(PostModeModel())
        .environment(DeepLinkRouter())
}
