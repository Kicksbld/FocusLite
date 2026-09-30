import SwiftUI

@main
struct FocusLiteApp: App {
    @State private var auth = AuthorizationManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
        }
    }
}
