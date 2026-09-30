import SwiftUI

@main
struct FocusLiteApp: App {
    @State private var auth = AuthorizationManager()
    @State private var blocking = BlockingSettings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .environment(blocking)
        }
    }
}
