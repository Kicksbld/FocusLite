import SwiftUI

/// Status and request buttons for both permissions. Used by the onboarding and by Settings.
struct PermissionsList: View {
    @Environment(AuthorizationManager.self) private var auth
    @Environment(\.openURL) private var openURL

    var body: some View {
        PermissionRow(
            title: "Temps d'écran",
            detail: "Nécessaire pour bloquer des apps comme Instagram ou TikTok.",
            systemImage: "hourglass",
            state: auth.screenTime,
            requestLabel: "Autoriser",
            retryLabel: "Réessayer"
        ) {
            Task { await auth.requestScreenTime() }
        }
        if let error = auth.screenTimeError {
            Text(error)
                .font(.footnote)
                .foregroundStyle(.red)
        }

        PermissionRow(
            title: "Notifications",
            detail: "Servent à ouvrir FocusLite depuis l'écran de blocage.",
            systemImage: "bell.badge",
            state: auth.notifications,
            requestLabel: "Autoriser",
            retryLabel: "Ouvrir Réglages"
        ) {
            if auth.notifications == .denied {
                if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                    openURL(url)
                }
            } else {
                Task { await auth.requestNotifications() }
            }
        }
    }
}

private struct PermissionRow: View {
    let title: String
    let detail: String
    let systemImage: String
    let state: PermissionState
    let requestLabel: String
    let retryLabel: String
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // At accessibility sizes the button moves under the text instead of squeezing it.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
        layout {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .frame(width: 32)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if state == .denied {
                        Text("Refusée")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.red)
                    }
                }
            }
            Spacer(minLength: 0)
            switch state {
            case .granted:
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                    .accessibilityLabel("Autorisée")
            case .notDetermined:
                // Tinted, not filled: the screen's one prominent button is the one at the bottom.
                Button(requestLabel, action: action)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
            case .denied:
                Button(retryLabel, action: action)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .tint(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
