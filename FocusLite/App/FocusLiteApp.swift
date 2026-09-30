import SwiftUI

@main
struct FocusLiteApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var auth = AuthorizationManager()
    @State private var blocking = BlockingSettings()
    @State private var browsers = BrowserStore()
    @State private var postMode = PostModeModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .environment(blocking)
                .environment(browsers)
                .environment(postMode)
                .environment(appDelegate.router)
        }
    }
}
