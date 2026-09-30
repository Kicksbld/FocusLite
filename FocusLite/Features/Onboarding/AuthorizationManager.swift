import FamilyControls
import Observation
import UserNotifications

/// Permission state shown in the UI, shared by Screen Time and notifications.
enum PermissionState {
    case notDetermined
    case denied
    case granted
}

/// Tracks and requests the two permissions FocusLite needs (spec F1):
/// Screen Time in individual mode, and local notifications (used by the shield redirect, F3).
@MainActor
@Observable
final class AuthorizationManager {
    private(set) var screenTime: PermissionState
    private(set) var notifications: PermissionState = .notDetermined
    /// Set when the last Screen Time request failed, cleared on the next request.
    private(set) var screenTimeError: String?

    init() {
        screenTime = Self.state(of: AuthorizationCenter.shared.authorizationStatus)
    }

    /// Re-reads both statuses. Call on launch and on every return to foreground,
    /// since the user can revoke either permission in Settings.
    func refresh() async {
        screenTime = Self.state(of: AuthorizationCenter.shared.authorizationStatus)
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notifications = Self.state(of: settings.authorizationStatus)
    }

    func requestScreenTime() async {
        screenTimeError = nil
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
            screenTimeError = "L'autorisation Temps d'écran a été refusée ou n'est pas disponible."
        }
        screenTime = Self.state(of: AuthorizationCenter.shared.authorizationStatus)
    }

    /// Once denied, iOS no longer shows the prompt: the user must go through Settings.
    func requestNotifications() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        await refresh()
    }

    private static func state(of status: AuthorizationStatus) -> PermissionState {
        switch status {
        case .approved: .granted
        case .denied: .denied
        default: .notDetermined
        }
    }

    private static func state(of status: UNAuthorizationStatus) -> PermissionState {
        switch status {
        case .authorized, .provisional, .ephemeral: .granted
        case .denied: .denied
        default: .notDetermined
        }
    }
}
