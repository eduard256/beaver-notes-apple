import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \Server.sortOrder) private var servers: [Server]
    @State private var showingAddServer = false
    @State private var showingSettings = false

    var body: some View {
        List {
            Section("Servers") {
                ForEach(servers) { server in
                    ServerRow(server: server, selected: server.id == appState.currentServerID)
                        .contentShape(Rectangle())
                        .onTapGesture { appState.switchTo(server: server.id) }
                }
                Button {
                    showingAddServer = true
                } label: {
                    Label("Add server", systemImage: Symbols.add)
                        .foregroundStyle(Palette.textSecondary)
                }
            }

            if let server = currentServer {
                Section("Folders") {
                    FolderRow(icon: Symbols.folder, label: "All", count: server.messages.filter { $0.deletedAt == nil }.count)
                    FolderRow(icon: Symbols.pinFill, label: "Pinned", count: server.messages.filter { $0.pinned && $0.deletedAt == nil }.count)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Beaver Notes")
        .toolbar {
            ToolbarItem {
                Button { showingSettings = true } label: {
                    Image(systemName: Symbols.settings)
                }
            }
        }
        .sheet(isPresented: $showingAddServer) { AddServerSheet() }
        .sheet(isPresented: $showingSettings) {
            NavigationStack { SettingsView() }
        }
    }

    private var currentServer: Server? {
        servers.first { $0.id == appState.currentServerID }
    }
}
