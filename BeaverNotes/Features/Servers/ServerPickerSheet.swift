import SwiftUI
import SwiftData

struct ServerPickerSheet: View {
    let onDone: () -> Void
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Server.sortOrder) private var servers: [Server]
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(servers) { s in
                    Button {
                        appState.currentServerID = s.id
                        onDone()
                    } label: {
                        ServerRow(server: s, isActive: s.id == appState.currentServerID, pendingCount: s.outboxOps.count)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            delete(s)
                        } label: {
                            Label("Delete", systemImage: SF.trash)
                        }
                    }
                }
                Button {
                    showAdd = true
                } label: {
                    Label("Add Server", systemImage: SF.add)
                        .foregroundStyle(Palette.accent)
                }
            }
            .navigationTitle("Servers")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDone)
                }
            }
            .sheet(isPresented: $showAdd) {
                AddServerSheet(onDone: { showAdd = false })
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func delete(_ s: Server) {
        let id = s.id
        Keychain.deletePassword(forServer: id)
        modelContext.delete(s)
        try? modelContext.save()
        if appState.currentServerID == id {
            appState.currentServerID = servers.first(where: { $0.id != id })?.id
        }
    }
}
