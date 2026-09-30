import SwiftUI

/// Main screen after onboarding: blocking toggle, the two app pickers and the permissions.
struct SettingsView: View {
    @Environment(AuthorizationManager.self) private var auth
    @Environment(BlockingSettings.self) private var blocking

    var body: some View {
        NavigationStack {
            List {
                if auth.screenTime != .granted {
                    Section {
                        Label(
                            "Temps d'écran n'est pas autorisé : aucune app ne peut être bloquée.",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(.orange)
                    }
                }

                Section {
                    Toggle("Blocage actif", isOn: Binding(
                        get: { blocking.isEnabled },
                        set: { blocking.setEnabled($0) }
                    ))
                } footer: {
                    Text("Désactiver retire tous les blocages.")
                }
                .disabled(auth.screenTime != .granted)

                Group {
                    SelectionSection(
                        group: .redirect,
                        title: "Redirection",
                        footer: "Mets Instagram ici. L'écran de blocage proposera d'ouvrir FocusLite."
                    )
                    SelectionSection(
                        group: .hardBlock,
                        title: "Blocage dur",
                        footer: "Mets TikTok et les autres apps à bloquer sans échappatoire."
                    )
                }
                .disabled(auth.screenTime != .granted)

                Section("Autorisations") {
                    PermissionsList()
                }
            }
            .navigationTitle("FocusLite")
        }
    }
}
