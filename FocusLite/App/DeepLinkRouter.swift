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
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    let router = DeepLinkRouter()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    /// The Shield Action extension (F3) puts the deep link in `userInfo[DeepLink.userInfoKey]`.
    /// Nonisolated because the notification objects aren't `Sendable`: only the link string crosses to the main actor.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard let link = response.notification.request.content.userInfo[DeepLink.userInfoKey] as? String,
              let url = URL(string: link)
        else { return }
        await MainActor.run { router.pending = url }
    }
}
