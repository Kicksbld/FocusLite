import DeviceActivity
import Foundation
import Observation

/// Post Mode (spec F5): unlocks the redirect group for 15 minutes, so a post or story can be published
/// from the native app. The Monitor extension re-applies the shields at the end, even if FocusLite is closed.
@MainActor
@Observable
final class PostModeModel {
    /// End of the running Post Mode, `nil` when it isn't running.
    private(set) var endsAt: Date?
    /// Why the last start failed, shown in an alert.
    var errorMessage: String?

    @ObservationIgnored private var expiryTask: Task<Void, Never>?

    init() {
        refresh()
    }

    /// The monitor is registered before any shield comes off: if it fails, nothing was ever unlocked.
    func start() {
        guard endsAt == nil else { return }
        let interval = PostModeInterval.starting(at: .now)
        SelectionStore.postModeEndsAt = interval.end
        let schedule = DeviceActivitySchedule(
            intervalStart: PostModeInterval.components(of: interval.start),
            intervalEnd: PostModeInterval.components(of: interval.end),
            repeats: false
        )
        do {
            try DeviceActivityCenter().startMonitoring(.postMode, during: schedule)
        } catch {
            SelectionStore.postModeEndsAt = nil
            BlockingManager.applyExpectedState()
            errorMessage = Self.message(for: error)
            return
        }
        BlockingManager.applyExpectedState()
        refresh()
    }

    /// Reloads the end from the App Group, where the Monitor extension clears it.
    /// While the app is open, it also ends Post Mode itself when the countdown reaches zero.
    func refresh() {
        expiryTask?.cancel()
        endsAt = SelectionStore.postModeEndsAt.flatMap { $0 > .now ? $0 : nil }
        guard let endsAt else { return }
        expiryTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(endsAt.timeIntervalSinceNow))
            guard !Task.isCancelled else { return }
            BlockingManager.applyExpectedState()
            self?.refresh()
        }
    }

    private static func message(for error: any Error) -> String {
        reason(for: error) + " Instagram reste bloqué."
    }

    private static func reason(for error: any Error) -> String {
        guard let error = error as? DeviceActivityCenter.MonitoringError else { return error.localizedDescription }
        return switch error {
        case .intervalTooShort: "iOS refuse un intervalle de moins de 15 minutes."
        case .intervalTooLong: "iOS refuse un intervalle aussi long."
        case .invalidDateComponents: "iOS refuse les dates de l'intervalle."
        case .unauthorized: "Temps d'écran n'est pas autorisé."
        case .excessiveActivities: "Trop de surveillances Temps d'écran sont déjà actives."
        @unknown default: error.localizedDescription
        }
    }
}
