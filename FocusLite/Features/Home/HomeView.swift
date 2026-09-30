import SwiftUI

/// Launch screen after onboarding: pick a service to open. Settings live here.
struct HomeView: View {
    let onOpen: (Service) -> Void

    @State private var showsSettings = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(Service.allCases) { service in
                    Button { onOpen(service) } label: {
                        ServiceRow(service: service)
                    }
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle("FocusLite")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showsSettings = true } label: {
                        Label("Réglages", systemImage: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showsSettings) {
                SettingsView()
            }
        }
    }
}

private struct ServiceRow: View {
    let service: Service

    var body: some View {
        HStack(spacing: 16) {
            // A small echo of the app icon: white glyph on the graphite gradient. Orange is kept for state.
            Image(systemName: service.systemImage)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(.brandGradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(service.title).font(.headline)
                Text(service.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.forward")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
    }
}
