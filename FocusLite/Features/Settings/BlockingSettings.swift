import FamilyControls
import Observation

/// UI state for the blocking section. Every change is persisted, then the shields are re-applied.
@MainActor
@Observable
final class BlockingSettings {
    private(set) var redirect = SelectionStore.selection(for: .redirect)
    private(set) var hardBlock = SelectionStore.selection(for: .hardBlock)
    private(set) var isEnabled = SelectionStore.blockingEnabled

    func selection(for group: SelectionGroup) -> FamilyActivitySelection {
        switch group {
        case .redirect: redirect
        case .hardBlock: hardBlock
        }
    }

    func setSelection(_ selection: FamilyActivitySelection, for group: SelectionGroup) {
        switch group {
        case .redirect: redirect = selection
        case .hardBlock: hardBlock = selection
        }
        SelectionStore.save(selection, for: group)
        BlockingManager.applyExpectedState()
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        SelectionStore.blockingEnabled = enabled
        BlockingManager.applyExpectedState()
    }
}
