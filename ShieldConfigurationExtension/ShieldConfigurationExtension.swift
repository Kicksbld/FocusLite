import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Shield appearance, chosen by the group of the blocked app (spec F3).
/// The buttons' behavior lives in ShieldActionExtension and must match these labels.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        configuration(for: application.token.flatMap(SelectionStore.group(of:)))
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        let group = application.token.flatMap(SelectionStore.group(of:))
            ?? category.token.flatMap(SelectionStore.group(of:))
        return configuration(for: group)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        ShieldConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        ShieldConfiguration()
    }

    /// An app found in no group gets the hard-block shield: no way out is the safe default.
    private func configuration(for group: SelectionGroup?) -> ShieldConfiguration {
        switch group {
        case .redirect:
            ShieldConfiguration(
                backgroundBlurStyle: .systemThickMaterial,
                icon: UIImage(systemName: "hourglass"),
                title: label("Instagram est en pause", .label),
                subtitle: label("Tes messages, posts et stories t'attendent dans FocusLite, sans les Reels.", .secondaryLabel),
                primaryButtonLabel: label("Ouvrir FocusLite", .white),
                primaryButtonBackgroundColor: .systemBlue,
                secondaryButtonLabel: label("Fermer", .systemBlue)
            )
        case .hardBlock, nil:
            ShieldConfiguration(
                backgroundBlurStyle: .systemThickMaterial,
                icon: UIImage(systemName: "nosign"),
                title: label("App bloquée", .label),
                subtitle: label("Tu as choisi de t'en passer. Tiens bon.", .secondaryLabel),
                primaryButtonLabel: label("Fermer", .white),
                primaryButtonBackgroundColor: .systemGray
            )
        }
    }

    private func label(_ text: String, _ color: UIColor) -> ShieldConfiguration.Label {
        ShieldConfiguration.Label(text: text, color: color)
    }
}
