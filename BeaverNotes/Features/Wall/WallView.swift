import SwiftUI
import SwiftData

struct WallView: View {
    @Environment(AppState.self) private var appState
    @Environment(SyncCoordinatorRegistry.self) private var registry
    @Environment(\.modelContext) private var modelContext

    @Query private var messages: [Message]
    @State private var isAtTop = true
    @State private var newMessagesCount = 0
    @State private var lastSeenTopID: UUID?
    @State private var editingMessage: Message?

    init() {
        // We can't capture appState in @Query initializer; fetch all messages, filter in view.
        _messages = Query(sort: \Message.createdAt, order: .reverse)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Palette.bgPrimary.ignoresSafeArea()

            if filteredMessages.isEmpty {
                EmptyWallView(isFiltered: appState.activeSearch != nil)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: Space.s2) {
                            ForEach(items, id: \.id) { item in
                                row(for: item)
                            }
                        }
                        .padding(.horizontal, Space.s4)
                        .padding(.bottom, 80)
                    }
                    .scrollIndicators(.hidden)
                    .refreshable {
                        await refresh()
                    }
                    .overlay(alignment: .top) {
                        if newMessagesCount > 0 {
                            NewMessagesBadge(count: newMessagesCount) {
                                withAnimation { proxy.scrollTo(items.first?.id, anchor: .top) }
                                newMessagesCount = 0
                            }
                            .padding(.top, Space.s2)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if currentServer != nil {
                QuickInputView(onEdit: { editingMessage = $0 })
            }
        }
        .toolbar { toolbarContent }
        .sheet(isPresented: Binding(get: { editingMessage != nil }, set: { if !$0 { editingMessage = nil } })) {
            if let msg = editingMessage {
                EditorView(initialContent: msg.content, isEdit: true) { newText in
                    applyEdit(message: msg, content: newText)
                }
            }
        }
        .onChange(of: filteredMessages.first?.localID) { _, newID in
            handleTopChange(newID: newID)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .principal) {
            Text(currentServer?.name ?? "Beaver Notes")
                .font(.headline)
                .foregroundStyle(Palette.textPrimary)
        }
        #endif
        ToolbarItem(placement: .primaryAction) {
            NavigationLink {
                SearchView()
            } label: {
                Image(systemName: SF.search)
            }
        }
    }

    // MARK: - Derived

    private var currentServer: Server? {
        guard let id = appState.currentServerID else { return nil }
        return messages.first { $0.server?.id == id }?.server
    }

    private var filteredMessages: [Message] {
        guard let serverID = appState.currentServerID else { return [] }
        return messages.filter { m in
            guard m.deletedAt == nil, m.server?.id == serverID else { return false }
            switch appState.currentFolder {
            case .pinned: if !m.pinned { return false }
            case .tag(let t): if !m.tags.contains(t) { return false }
            default: break
            }
            if let q = appState.activeSearch?.search, !q.isEmpty,
               !m.content.localizedCaseInsensitiveContains(q) {
                return false
            }
            return true
        }
    }

    private var items: [WallItem] {
        var out: [WallItem] = []
        var lastDay: Date?
        for m in filteredMessages {
            let day = DateLabels.dayKey(m.createdAt)
            if day != lastDay {
                out.append(.separator(day: day))
                lastDay = day
            }
            out.append(.message(m))
        }
        return out
    }

    // MARK: - Actions

    private func row(for item: WallItem) -> some View {
        switch item {
        case .separator(let day):
            return AnyView(DateSeparator(label: DateLabels.label(for: day)).id(item.id))
        case .message(let m):
            return AnyView(MessageCardView(message: m, onEdit: { editingMessage = $0 }).id(item.id))
        }
    }

    private func refresh() async {
        guard let server = currentServer else { return }
        let coord = registry.coordinator(for: server, context: modelContext)
        await coord.triggerImmediatePull()
    }

    private func applyEdit(message: Message, content: String) {
        message.content = content
        message.tags = HashtagExtractor.extract(from: content)
        message.updatedAt = Date()
        message.syncState = .pending
        if let server = message.server {
            let op = OutboxOp(server: server, kind: .edit, messageLocalID: message.localID)
            modelContext.insert(op)
        }
        try? modelContext.save()
        editingMessage = nil
    }

    private func handleTopChange(newID: UUID?) {
        guard let newID, lastSeenTopID != newID else { return }
        if !isAtTop, let _ = lastSeenTopID {
            newMessagesCount += 1
        }
        lastSeenTopID = newID
    }
}

enum WallItem: Identifiable {
    case separator(day: Date)
    case message(Message)

    var id: String {
        switch self {
        case .separator(let d): return "sep-\(d.timeIntervalSinceReferenceDate)"
        case .message(let m):   return "msg-\(m.localID.uuidString)"
        }
    }
}
