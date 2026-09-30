import SwiftUI

/// Settings sheet, opened from the home screen: blocking, app pickers, Post Mode, browser and permissions.
struct SettingsView: View {
    @Environment(AuthorizationManager.self) private var auth
    @Environment(BlockingSettings.self) private var blocking
    @Environment(BrowserStore.self) private var browsers
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if auth.screenTime != .granted {
                    Section {
                        Label(
                            "FocusLite n'a pas accès à Temps d'écran. Autorise-le plus bas pour pouvoir bloquer des apps.",
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
                    Text("Désactivé, toutes tes apps redeviennent accessibles.")
                }
                .disabled(auth.screenTime != .granted)

                Group {
                    SelectionSection(
                        group: .redirect,
                        title: "Redirection",
                        footer: "Ajoute Instagram ici. Quand tu l'ouvres, l'écran de blocage te propose de continuer dans FocusLite, sans les Reels."
                    )
                    SelectionSection(
                        group: .hardBlock,
                        title: "Blocage total",
                        footer: "Ajoute TikTok et les apps dont tu veux te passer complètement. L'écran de blocage ne propose que « Fermer »."
                    )
                }
                .disabled(auth.screenTime != .granted)

                PostModeSection()

                Section {
                    Toggle("Ouvrir les reels reçus en message", isOn: Binding(
                        get: { browsers.instagram.allowSingleReels },
                        set: { browsers.instagram.setAllowSingleReels($0) }
                    ))
                } header: {
                    Text("Instagram")
                } footer: {
                    Text("Un reel partagé en message s'ouvre seul. Le fil des Reels reste bloqué.")
                }

                Section("Autorisations") {
                    PermissionsList()
                }
            }
            .navigationTitle("Réglages")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
    }
}
