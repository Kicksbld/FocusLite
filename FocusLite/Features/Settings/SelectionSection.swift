import FamilyControls
import SwiftUI

/// One app group: the selected apps and categories, and a button that opens the picker.
struct SelectionSection: View {
    let group: SelectionGroup
    let title: String
    let footer: String

    @Environment(BlockingSettings.self) private var settings
    @State private var showsPicker = false

    var body: some View {
        let selection = settings.selection(for: group)
        Section {
            // Label(token) resolves the app name and icon; the app itself never sees them.
            ForEach(Array(selection.applicationTokens), id: \.self) { token in
                Label(token)
            }
            ForEach(Array(selection.categoryTokens), id: \.self) { token in
                Label(token)
            }
            Button(selection.isEmpty ? "Choisir des apps" : "Modifier la sélection") {
                showsPicker = true
            }
            // On the button, not the Section: a List applies a Section's modifiers to every row,
            // so each selected app would get its own picker, and they'd dismiss each other.
            .familyActivityPicker(
                isPresented: $showsPicker,
                selection: Binding(
                    get: { settings.selection(for: group) },
                    set: { settings.setSelection($0, for: group) }
                )
            )
        } header: {
            Text(title)
        } footer: {
            Text(footer)
        }
    }
}

private extension FamilyActivitySelection {
    var isEmpty: Bool {
        applicationTokens.isEmpty && categoryTokens.isEmpty && webDomainTokens.isEmpty
    }
}
