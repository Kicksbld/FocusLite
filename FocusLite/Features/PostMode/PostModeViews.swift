import SwiftUI

/// Post Mode in the browser's top bar: the start button, or the countdown and a stop button while it runs.
/// The countdown is plain text, since a toolbar shows only the icon of a button's or menu's label.
/// Stopping goes through a menu, so a stray tap doesn't end Post Mode.
struct PostModeToolbarItem: View {
    @Environment(PostModeModel.self) private var postMode

    var body: some View {
        Group {
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
        .sensoryFeedback(.success, trigger: postMode.endsAt) { old, new in old == nil && new != nil }
    }
}

/// Post Mode in Settings: the start button, or the countdown and a stop button while it runs.
struct PostModeSection: View {
    @Environment(PostModeModel.self) private var postMode

    var body: some View {
        Section {
            if let endsAt = postMode.endsAt {
                LabeledContent("Temps restant") {
                    Countdown(endsAt: endsAt)
                }
                StopButton()
            } else {
                StartButton(title: "Activer le Mode Poster")
            }
        } header: {
            Text("Mode Poster")
        } footer: {
            Text("Débloque l'app Instagram pendant 15 minutes, le temps de publier un post ou une story. Les apps en blocage total restent bloquées.")
        }
        .sensoryFeedback(.success, trigger: postMode.endsAt) { old, new in old == nil && new != nil }
    }
}

private struct Countdown: View {
    let endsAt: Date

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
            Text(endsAt, style: .timer).monospacedDigit()
        }
        .fontDesign(.rounded)
        .foregroundStyle(.tint)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Mode Poster, temps restant \(Text(endsAt, style: .timer))"))
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
            "Impossible d'activer le Mode Poster",
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
