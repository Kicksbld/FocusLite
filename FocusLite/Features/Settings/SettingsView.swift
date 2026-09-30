import SwiftUI

/// Settings sheet, opened from the home screen: blocking, app pickers, Post Mode, browser and permissions.
struct SettingsView: View {
    @Environment(AuthorizationManager.self) private var auth
    @Environment(BlockingSettings.self) private var blocking
    @Environment(BrowserModel.self) private var browser
    @Environment(\.dismiss) private var dismiss

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

                Section {
                    PostModeButton()
                } footer: {
                    Text("Débloque Instagram 15 minutes pour publier depuis l'app. Le blocage dur reste actif.")
                }

                Section {
                    Toggle("Autoriser les reels uniques", isOn: Binding(
                        get: { browser.allowSingleReels },
                        set: { browser.setAllowSingleReels($0) }
                    ))
                } header: {
                    Text("Navigateur")
                } footer: {
                    Text("Un reel reçu en message s'ouvre, mais le feed des Reels reste bloqué.")
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
