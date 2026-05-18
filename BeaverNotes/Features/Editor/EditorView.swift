import SwiftUI
import SwiftData

struct EditorView: View {
    let message: Message
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var content: String = ""
    @State private var showingPreview = false
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                EditorToolbar { action in
                    let lower = content.startIndex
                    let upper = content.endIndex
                    let (newText, _) = MarkdownToolbar.apply(action, text: content, selection: lower..<upper)
                    content = newText
                }
                Divider()
                if showingPreview {
                    ScrollView { EditorPreview(content: content).padding(Space.s4) }
                } else {
                    EditorTextView(text: $content)
                        .focused($focused)
                        .padding(Space.s2)
                }
            }
            .background(Palette.bgPrimary)
            .navigationTitle("Edit")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showingPreview.toggle() } label: {
                        Image(systemName: Symbols.preview)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear {
                content = message.content
                focused = true
            }
        }
    }

    private func save() {
        guard let server = message.server else { dismiss(); return }
        message.content = content
        message.updatedAt = Date()
        message.tags = HashtagExtractor.extract(from: content)
        let op = OutboxOp(server: server, kind: .edit, messageLocalID: message.localID)
        modelContext.insert(op)
        message.syncState = .pending
        try? modelContext.save()
        dismiss()
    }
}
