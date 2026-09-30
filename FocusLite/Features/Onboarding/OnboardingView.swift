import SwiftUI

/// First-launch flow: explains how FocusLite works, then asks for both permissions.
struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var showsPermissions = false

    var body: some View {
        NavigationStack {
            IntroPage { showsPermissions = true }
                .navigationDestination(isPresented: $showsPermissions) {
                    PermissionsPage(onFinish: onFinish)
                }
        }
    }
}

private struct IntroPage: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 8) {
                Text("FocusLite")
                    .font(.largeTitle.bold())
                Text("Garde l'essentiel d'Instagram et de YouTube, sans Reels ni Shorts.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            FeatureRow(
                systemImage: "camera",
                title: "Instagram sans Reels",
                detail: "L'app Instagram est bloquée. FocusLite t'ouvre à la place Instagram sans Reels ni Explorer : messages, profils, posts et stories restent accessibles."
            )
            FeatureRow(
                systemImage: "play.rectangle",
                title: "YouTube sans Shorts",
                detail: "Regarde des vidéos, suis tes chaînes et fais des recherches, sans jamais tomber sur un Short."
            )
            FeatureRow(
                systemImage: "nosign",
                title: "Blocage total",
                detail: "TikTok et les apps de ton choix sont bloquées, sans échappatoire."
            )
            FeatureRow(
                systemImage: "square.and.arrow.up",
                title: "Mode Poster",
                detail: "Besoin de publier ? L'app Instagram se débloque 15 minutes, puis se rebloque toute seule."
            )

            Spacer()

            Button(action: onContinue) {
                Text("Continuer").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
    }
}

private struct FeatureRow: View {
    let systemImage: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: systemImage)
                .font(.title2)
                .frame(width: 32)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct PermissionsPage: View {
    let onFinish: () -> Void

    @Environment(AuthorizationManager.self) private var auth

    var body: some View {
        List {
            Section {
                PermissionsList()
            } footer: {
                Text("Tu pourras modifier ces autorisations plus tard dans les réglages de FocusLite.")
            }
        }
        .navigationTitle("Autorisations")
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                if auth.screenTime != .granted {
                    Text("Sans Temps d'écran, FocusLite ne peut bloquer aucune app. Les versions filtrées d'Instagram et de YouTube restent disponibles.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                Button(action: onFinish) {
                    Text(auth.screenTime == .granted ? "Commencer" : "Continuer sans bloquer")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .background(.bar)
        }
    }
}
