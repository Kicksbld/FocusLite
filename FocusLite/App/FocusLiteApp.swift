import SwiftUI

@main
struct FocusLiteApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var auth = AuthorizationManager()
    @State private var blocking = BlockingSettings()
    @State private var browser = BrowserModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .environment(blocking)
                .environment(browser)
                .environment(appDelegate.router)
        }
    }
}
