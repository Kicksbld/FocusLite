import FamilyControls
import Foundation

/// The two app groups. A token's behavior comes from the group it belongs to,
/// since `ApplicationToken`s are opaque.
enum SelectionGroup {
    /// Instagram: blocked, the shield offers "Ouvrir FocusLite".
    case redirect
    /// TikTok, etc.: blocked, the shield offers only "Fermer".
    case hardBlock

    fileprivate var key: String {
        switch self {
        case .redirect: AppGroup.Key.selectionRedirect
        case .hardBlock: AppGroup.Key.selectionHardBlock
        }
    }
}

/// Reads and writes the blocking state stored in the App Group.
enum SelectionStore {
    static func selection(for group: SelectionGroup) -> FamilyActivitySelection {
        guard let data = AppGroup.defaults.data(forKey: group.key),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return FamilyActivitySelection() }
        return selection
    }

    static func save(_ selection: FamilyActivitySelection, for group: SelectionGroup) {
        guard let data = try? JSONEncoder().encode(selection) else { return }
        AppGroup.defaults.set(data, forKey: group.key)
    }

    static var blockingEnabled: Bool {
        get { AppGroup.defaults.bool(forKey: AppGroup.Key.blockingEnabled) }
        set { AppGroup.defaults.set(newValue, forKey: AppGroup.Key.blockingEnabled) }
    }
}
