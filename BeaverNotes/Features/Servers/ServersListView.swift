import SwiftUI
import SwiftData

struct ServersListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \Server.sortOrder) private var servers: [Server]
    @State private var showAdd = false
    @State private var editing: Server?

    var body: some View {
        Form {
            ForEach(servers) { s in
                Button {
                    editing = s
                } label: {
                    HStack {
                        ServerRow(server: s, isActive: s.id == appState.currentServerID, pendingCount: s.outboxOps.count)
                        Image(systemName: SF.chevronRight)
                            .font(.caption)
                            .foregroundStyle(Palette.textTertiary)
                    }
                }
                .buttonStyle(.plain)
            }
            .onDelete(perform: delete)

            Button {
                showAdd = true
            } label: {
                Label("Add Server", systemImage: SF.add)
                    .foregroundStyle(Palette.accent)
            }
        }
        .navigationTitle("Servers")
        .sheet(isPresented: $showAdd) {
            AddServerSheet(onDone: { showAdd = false })
        }
        .sheet(isPresented: Binding(get: { editing != nil }, set: { if !$0 { editing = nil } })) {
            if let s = editing {
                ServerEditorSheet(server: s, onDone: { editing = nil })
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets {
            let s = servers[i]
            Keychain.deletePassword(forServer: s.id)
            modelContext.delete(s)
        }
        try? modelContext.save()
    }
}
