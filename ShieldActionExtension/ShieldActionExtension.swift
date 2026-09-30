import ManagedSettings
import UserNotifications

/// Shield button handling (spec F3). An extension can't open an app, so "Ouvrir FocusLite"
/// posts a local notification carrying a deep link; tapping it opens FocusLite on the DMs.
class ShieldActionExtension: ShieldActionDelegate {
    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handle(action, group: SelectionStore.group(of: application), completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(.close)
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handle(action, group: SelectionStore.group(of: category), completionHandler: completionHandler)
    }

    /// Only the redirect group's primary button ("Ouvrir FocusLite") does more than close.
    private func handle(_ action: ShieldAction, group: SelectionGroup?, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        guard group == .redirect, action == .primaryButtonPressed else {
            completionHandler(.close)
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "FocusLite"
        content.body = "Touche pour ouvrir tes messages Instagram, sans les Reels."
        content.sound = .default
        content.userInfo = [DeepLink.userInfoKey: DeepLink.open(path: DeepLink.inboxPath).absoluteString]
        // Fixed identifier: pressing the button again replaces the notification instead of stacking.
        let request = UNNotificationRequest(identifier: "shield.redirect", content: content, trigger: nil)
        // Close only once the notification is scheduled: the extension may be stopped right after.
        // The SDK doesn't mark the handler Sendable; calling it from the notification callback is safe.
        nonisolated(unsafe) let respond = completionHandler
        UNUserNotificationCenter.current().add(request) { _ in
            respond(.close)
        }
    }
}
