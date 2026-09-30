import Observation
import UIKit
import UserNotifications

/// Collects deep links from both sources (the `focuslite://` URL scheme and notification taps)
/// until `RootView` handles them. Also works on a cold start, before any view exists.
@MainActor
@Observable
final class DeepLinkRouter {
    /// Latest deep link not yet handled.
    var pending: URL?
}

/// Receives notification taps. It must be the notification center's delegate before
/// launch ends, or a tap that launches the app is lost.
final class AppDelegate: NSObject, UIApplicationDelegate {
    let router = DeepLinkRouter()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
}

/// Main-actor conformance with the completion-handler variant: UIKit requires the handler
/// on the main thread. The `async` variant calls it from a background thread and crashes.
extension AppDelegate: @preconcurrency UNUserNotificationCenterDelegate {
    /// The Shield Action extension (F3) puts the deep link in `userInfo[DeepLink.userInfoKey]`.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }
        guard let link = response.notification.request.content.userInfo[DeepLink.userInfoKey] as? String,
              let url = URL(string: link)
        else { return }
        router.pending = url
    }
}
