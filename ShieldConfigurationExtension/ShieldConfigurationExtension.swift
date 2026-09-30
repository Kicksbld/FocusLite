import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Shield appearance, chosen by the group of the blocked app (spec F3, DESIGN.md §8).
/// The buttons' behavior lives in ShieldActionExtension and must match these labels.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        configuration(for: application.token.flatMap(SelectionStore.group(of:)), appName: application.localizedDisplayName)
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        let group = application.token.flatMap(SelectionStore.group(of:))
            ?? category.token.flatMap(SelectionStore.group(of:))
        return configuration(for: group, appName: application.localizedDisplayName)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        ShieldConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        ShieldConfiguration()
    }

    /// An app found in no group gets the hard-block shield: no way out is the safe default.
    /// The regular material (not thick) lets the blocked app show through, still behind a readable blur.
    /// One orange focal point per shield: the primary button for redirect, the icon for hard block.
    private func configuration(for group: SelectionGroup?, appName: String?) -> ShieldConfiguration {
        switch group {
        case .redirect:
            ShieldConfiguration(
                backgroundBlurStyle: .systemMaterial,
                icon: UIImage(systemName: "hourglass"),
                title: label("\(appName ?? "Instagram") est en pause", .label),
                subtitle: label("Tes messages, posts et stories t'attendent dans FocusLite, sans les Reels.", .secondaryLabel),
                primaryButtonLabel: label("Ouvrir FocusLite", Self.ink),
                primaryButtonBackgroundColor: Self.accent,
                secondaryButtonLabel: label("Fermer", Self.accent)
            )
        case .hardBlock, nil:
            ShieldConfiguration(
                backgroundBlurStyle: .systemMaterial,
                icon: UIImage(systemName: "nosign")?.withTintColor(Self.accent, renderingMode: .alwaysOriginal),
                title: label("App bloquée", .label),
                subtitle: label(Self.hardBlockMessage(appName: appName), .secondaryLabel),
                primaryButtonLabel: label("Fermer", .white),
                primaryButtonBackgroundColor: .systemGray
            )
        }
    }

    /// "de TikTok", but "d'Uber Eats": French elides "de" before a vowel.
    private static func hardBlockMessage(appName: String?) -> String {
        guard let appName, let first = appName.first else { return "Tu as choisi de t'en passer. Tiens bon." }
        let de = "aeiouyàâéèêîôû".contains(first.lowercased()) ? "d'" : "de "
        return "Tu as choisi de te passer \(de)\(appName). Tiens bon."
    }

    private static let accent = UIColor(named: "AccentColor") ?? .systemOrange
    private static let ink = UIColor(named: "Ink") ?? .black

    private func label(_ text: String, _ color: UIColor) -> ShieldConfiguration.Label {
        ShieldConfiguration.Label(text: text, color: color)
    }
}
