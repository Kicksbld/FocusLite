import SwiftUI

/// Main screen after onboarding. App pickers and blocking toggle come with F2.
struct SettingsView: View {
    @Environment(AuthorizationManager.self) private var auth

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
                Section("Autorisations") {
                    PermissionsList()
                }
            }
            .navigationTitle("FocusLite")
        }
    }
}
