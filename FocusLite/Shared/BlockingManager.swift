import FamilyControls
import ManagedSettings

/// Applies the shields to the named `ManagedSettingsStore`, from the state stored in the App Group.
enum BlockingManager {
    /// Shields the union of both groups when blocking is enabled, clears every shield otherwise.
    /// Idempotent: call it after any change and on every launch / return to foreground.
    static func applyExpectedState() {
        let store = ManagedSettingsStore(named: .focusLite)
        guard SelectionStore.blockingEnabled else {
            store.clearAllSettings()
            return
        }

        let redirect = SelectionStore.selection(for: .redirect)
        let hardBlock = SelectionStore.selection(for: .hardBlock)

        let applications = redirect.applicationTokens.union(hardBlock.applicationTokens)
        store.shield.applications = applications.isEmpty ? nil : applications

        let categories = redirect.categoryTokens.union(hardBlock.categoryTokens)
        store.shield.applicationCategories = categories.isEmpty ? nil : .specific(categories)
    }
}
