import SwiftUI
import SwiftData

struct ServersListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \Server.sortOrder) private var servers: [Server]
    @State private var showingAdd = false
    @State private var editing: Server?

    var body: some View {
        List {
            ForEach(servers) { server in
                Button {
                    editing = server
                } label: {
                    ServerRowDetail(server: server)
                }
                .buttonStyle(.plain)
            }
            .onDelete(perform: delete)
            .onMove(perform: move)
        }
        .navigationTitle("Servers")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: Symbols.add)
                }
            }
            #if os(iOS)
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
            #endif
        }
        .sheet(isPresented: $showingAdd) { AddServerSheet() }
        .sheet(item: $editing) { server in
            ServerEditorSheet(server: server)
        }
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets {
            let s = servers[i]
            Keychain.deletePassword(forServer: s.id)
            if appState.currentServerID == s.id {
                appState.currentServerID = servers.first { $0.id != s.id }?.id
            }
            modelContext.delete(s)
        }
        try? modelContext.save()
    }

    private func move(from source: IndexSet, to destination: Int) {
        var arr = servers
        arr.move(fromOffsets: source, toOffset: destination)
        for (idx, s) in arr.enumerated() { s.sortOrder = idx }
        try? modelContext.save()
    }
}
