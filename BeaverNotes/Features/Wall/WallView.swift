import SwiftUI
import SwiftData

struct WallView: View {
    @Environment(AppState.self) private var appState
    @Environment(SyncCoordinatorRegistry.self) private var registry
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Server.sortOrder) private var servers: [Server]
    @Query(sort: \Message.createdAt, order: .reverse) private var allMessages: [Message]

    @State private var searchQuery = ""
    @State private var filterPinned = false
    @State private var filterTag: String?
    @State private var showServerPicker = false
    @State private var showSettings = false
    @State private var showEditor = false
    @State private var editingMessage: Message?

    private var currentServer: Server? {
        servers.first { $0.id == appState.currentServerID }
    }

    private var messages: [Message] {
        guard let sid = appState.currentServerID else { return [] }
        return allMessages.filter { m in
            guard m.server?.id == sid, m.deletedAt == nil else { return false }
            if filterPinned, !m.pinned { return false }
            if let tag = filterTag, !m.tags.contains(tag) { return false }
            if !searchQuery.isEmpty {
                return m.content.localizedCaseInsensitiveContains(searchQuery)
            }
            return true
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Space.s4, pinnedViews: []) {
                    if messages.isEmpty {
                        EmptyWallView()
                            .padding(.top, Space.s10)
                    } else {
                        ForEach(messages) { msg in
                            MessageCardView(message: msg, onEdit: { editingMessage = msg })
                                .id(msg.localID)
                        }
                    }
                    Spacer().frame(height: Space.s10)
                }
                .padding(.horizontal, Space.s4)
                .padding(.top, Space.s4)
            }
            .background(Palette.bgPrimary)
            .refreshable { await refresh() }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                if let server = currentServer {
                    QuickInputView(server: server)
                }
            }
            .navigationTitle(currentServer?.name ?? "Beaver Notes")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { WallToolbar(showServerPicker: $showServerPicker, showSettings: $showSettings, searchQuery: $searchQuery) }
            .sheet(isPresented: $showServerPicker) { ServerPickerSheet() }
            .sheet(isPresented: $showSettings) { NavigationStack { SettingsView() } }
            .sheet(item: $editingMessage) { msg in
                EditorView(message: msg)
            }
            .onChange(of: appState.pendingMessageDeepLink) { _, new in
                if let new, let msg = allMessages.first(where: { $0.serverID == new || $0.localID.uuidString == new }) {
                    proxy.scrollTo(msg.localID, anchor: .center)
                    appState.pendingMessageDeepLink = nil
                }
            }
        }
    }

    private func refresh() async {
        guard let server = currentServer else { return }
        let coord = registry.coordinator(for: server, context: modelContext)
        await coord.triggerImmediatePull()
    }
}

struct ServerPickerSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Server.sortOrder) private var servers: [Server]

    var body: some View {
        NavigationStack {
            List(servers) { server in
                Button {
                    appState.switchTo(server: server.id)
                    dismiss()
                } label: {
                    ServerRow(server: server, selected: server.id == appState.currentServerID)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Servers")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
