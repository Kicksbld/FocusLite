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
            Image(systemName: service.systemImage)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(.tint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(service.title).font(.headline)
                Text(service.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.forward")
                .font(.footnote.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
    }
}
