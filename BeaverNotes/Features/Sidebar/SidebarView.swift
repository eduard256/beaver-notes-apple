import SwiftUI
import SwiftData

enum WallFolder: Hashable {
    case all
    case pinned
    case tag(String)
}

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Server.sortOrder) private var servers: [Server]
    @State private var showAddServer = false
    @State private var showSettings = false
    @State private var editing: Server?
    @State private var pendingDelete: Server?

    var body: some View {
        @Bindable var state = appState
        List(selection: $state.currentFolder) {
            Section("Servers") {
                ForEach(servers) { s in
                    Button {
                        appState.currentServerID = s.id
                    } label: {
                        ServerRow(server: s, isActive: s.id == appState.currentServerID, pendingCount: s.outboxOps.count)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button { editing = s } label: {
                            Label("Edit", systemImage: SF.pencil)
                        }
                        Divider()
                        Button(role: .destructive) {
                            pendingDelete = s
                        } label: {
                            Label("Delete", systemImage: SF.trash)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            pendingDelete = s
                        } label: {
                            Label("Delete", systemImage: SF.trash)
                        }
                    }
                }

                Button {
                    showAddServer = true
                } label: {
                    HStack(spacing: Space.s3) {
                        Image(systemName: SF.add).frame(width: 18)
                        Text("Add Server").font(.callout)
                        Spacer()
                    }
                    .foregroundStyle(Palette.accent)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }

            if let active = servers.first(where: { $0.id == appState.currentServerID }) {
                Section("Folders") {
                    FolderRowSelectable(value: .all, symbol: SF.folder, title: "All", count: liveCount(in: active, filter: { $0.deletedAt == nil }))
                    FolderRowSelectable(value: .pinned, symbol: SF.pinFill, title: "Pinned", count: liveCount(in: active, filter: { $0.deletedAt == nil && $0.pinned }))
                }

                let tags = collectTags(active)
                if !tags.isEmpty {
                    Section("Tags") {
                        ForEach(tags, id: \.self) { tag in
                            FolderRowSelectable(value: .tag(tag), symbol: SF.tag, title: tag, count: nil)
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showSettings = true } label: { Image(systemName: SF.settings) }
            }
        }
        .navigationTitle("Beaver")
        .sheet(isPresented: $showAddServer) {
            AddServerSheet(onDone: { showAddServer = false })
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(onDone: { showSettings = false })
        }
        .sheet(isPresented: Binding(get: { editing != nil }, set: { if !$0 { editing = nil } })) {
            if let s = editing {
                ServerEditorSheet(server: s, onDone: { editing = nil })
            }
        }
        .confirmationDialog(
            pendingDelete.map { "Delete \($0.name)?" } ?? "",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let s = pendingDelete { delete(s) }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text("Removes the server, its locally cached notes, and saved password from this device. Notes on the server itself are not affected.")
        }
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

    private func liveCount(in server: Server, filter: (Message) -> Bool) -> Int {
        server.messages.filter(filter).count
    }

    private func collectTags(_ server: Server) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for m in server.messages where m.deletedAt == nil {
            for t in m.tags where seen.insert(t).inserted {
                out.append(t)
            }
        }
        return out.sorted()
    }
}

private struct FolderRowSelectable: View {
    let value: WallFolder
    let symbol: String
    let title: String
    let count: Int?

    @Environment(AppState.self) private var appState

    var body: some View {
        Button {
            appState.currentFolder = value
        } label: {
            FolderRow(symbol: symbol, title: title, count: count, isActive: appState.currentFolder == value)
        }
        .buttonStyle(.plain)
    }
}
