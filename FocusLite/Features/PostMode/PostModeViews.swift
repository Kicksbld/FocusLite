import SwiftUI

/// Post Mode in the browser's top bar: the start button, or the countdown and a stop button while it runs.
/// The countdown is plain text, since a toolbar shows only the icon of a button's or menu's label.
/// Stopping goes through a menu, so a stray tap doesn't end Post Mode.
struct PostModeToolbarItem: View {
    @Environment(PostModeModel.self) private var postMode

    var body: some View {
        if let endsAt = postMode.endsAt {
            HStack(spacing: 12) {
                Countdown(endsAt: endsAt)
                Menu {
                    StopButton()
                } label: {
                    Image(systemName: "stop.circle")
                        .accessibilityLabel("Terminer le Mode Poster")
                }
            }
        } else {
            StartButton(title: "Mode Poster")
        }
    }
}

/// Post Mode in Settings: the start button, or the countdown and a stop button while it runs.
struct PostModeSection: View {
    @Environment(PostModeModel.self) private var postMode

    var body: some View {
        Section {
            if let endsAt = postMode.endsAt {
                LabeledContent("Fin dans") {
                    Countdown(endsAt: endsAt)
                }
                StopButton()
            } else {
                StartButton(title: "Activer le Mode Poster")
            }
        } header: {
            Text("Mode Poster")
        } footer: {
            Text("Débloque Instagram 15 minutes pour publier depuis l'app. Le blocage dur reste actif.")
        }
    }
}

private struct Countdown: View {
    let endsAt: Date

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
            Text(endsAt, style: .timer).monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Mode Poster, fin dans \(Text(endsAt, style: .timer))"))
    }
}

/// Also shows the alert when starting fails.
private struct StartButton: View {
    let title: String

    @Environment(PostModeModel.self) private var postMode
    @Environment(AuthorizationManager.self) private var auth
    @Environment(BlockingSettings.self) private var blocking

    var body: some View {
        Button { postMode.start() } label: {
            Label(title, systemImage: "plus.app")
        }
        // Nothing to unlock when blocking is off.
        .disabled(auth.screenTime != .granted || !blocking.isEnabled)
        .alert(
            "Mode Poster impossible",
            isPresented: Binding(
                get: { postMode.errorMessage != nil },
                set: { if !$0 { postMode.errorMessage = nil } }
            )
        ) {
            Button("OK") {}
        } message: {
            Text(postMode.errorMessage ?? "")
        }
    }
}

private struct StopButton: View {
    @Environment(PostModeModel.self) private var postMode

    var body: some View {
        Button("Terminer maintenant", systemImage: "stop.circle") { postMode.stop() }
    }
}
