import FamilyControls
import Foundation
import ManagedSettings

/// Applies the shields to the named `ManagedSettingsStore`, from the state stored in the App Group.
enum BlockingManager {
    /// Shields the union of both groups when blocking is enabled, clears every shield otherwise.
    /// During Post Mode the redirect group is left out, but a token also in the hard block group stays shielded.
    /// A Post Mode whose end has passed is cleared first, in case the Monitor extension missed it (safety net).
    /// Idempotent: call it after any change and on every launch / return to foreground.
    static func applyExpectedState() {
        if let endsAt = SelectionStore.postModeEndsAt, endsAt <= .now {
            SelectionStore.postModeEndsAt = nil
        }

        let store = ManagedSettingsStore(named: .focusLite)
        guard SelectionStore.blockingEnabled else {
            store.clearAllSettings()
            return
        }

        let hardBlock = SelectionStore.selection(for: .hardBlock)
        var applications = hardBlock.applicationTokens
        var categories = hardBlock.categoryTokens
        if SelectionStore.postModeEndsAt == nil {
            let redirect = SelectionStore.selection(for: .redirect)
            applications.formUnion(redirect.applicationTokens)
            categories.formUnion(redirect.categoryTokens)
        }

        store.shield.applications = applications.isEmpty ? nil : applications
        store.shield.applicationCategories = categories.isEmpty ? nil : .specific(categories)
    }
}
