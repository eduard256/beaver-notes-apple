import SwiftUI
import SwiftData

struct MessageCardView: View {
    @Bindable var message: Message
    let onEdit: (Message) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var previewIndex: Int?
    @State private var previewImages: [LocalFile] = []

    private var previewBinding: Binding<Bool> {
        Binding(get: { previewIndex != nil }, set: { if !$0 { previewIndex = nil } })
    }

    var body: some View {
        BeaverCard(pinned: message.pinned) {
            VStack(alignment: .leading, spacing: Space.s3) {
                if message.pinned {
                    HStack(spacing: 4) {
                        Image(systemName: SF.pinFill)
                            .font(.caption2)
                        Text("PINNED")
                            .font(.caption2.weight(.semibold))
                            .tracking(0.5)
                    }
                    .foregroundStyle(Palette.pin)
                }

                if !message.content.isEmpty {
                    MessageBody(content: message.content)
                        .textSelection(.enabled)
                }

                let images = message.files.filter(\.isImage)
                let videos = message.files.filter(\.isVideo)
                let docs   = message.files.filter { !$0.isImage && !$0.isVideo }

                if !images.isEmpty {
                    MessageImages(files: images, server: message.server) { f in
                        previewImages = images
                        previewIndex = images.firstIndex(where: { $0.localID == f.localID }) ?? 0
                    }
                }
                ForEach(videos, id: \.localID) { f in
                    MessageVideoRow(file: f, server: message.server)
                }
                ForEach(docs, id: \.localID) { f in
                    MessageFileRow(file: f, server: message.server, onTap: { /* QuickLook later */ })
                }

                if !message.tags.isEmpty {
                    MessageTags(tags: message.tags) { _ in /* filter by tag later */ }
                }

                MessageFooter(message: message, onCopy: copyContent, onPin: togglePin, onEdit: { onEdit(message) }, onDelete: deleteMessage, onRetry: retrySync)
            }
        }
        .contextMenu {
            MessageContextMenu(message: message, onCopy: copyContent, onPin: togglePin, onEdit: { onEdit(message) }, onDelete: deleteMessage)
        }
        .swipeActions(edge: .leading) {
            Button { togglePin() } label: {
                Label(message.pinned ? "Unpin" : "Pin", systemImage: SF.pin)
            }
            .tint(Palette.pin)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { deleteMessage() } label: {
                Label("Delete", systemImage: SF.trash)
            }
        }
        .modifier(ImagePreviewPresenter(
            isPresented: previewBinding,
            files: previewImages,
            server: message.server,
            index: Binding(get: { previewIndex ?? 0 }, set: { previewIndex = $0 }),
            onClose: { previewIndex = nil }
        ))
    }

    private func copyContent() {
        #if canImport(UIKit)
        UIPasteboard.general.string = message.content
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(message.content, forType: .string)
        #endif
    }

    private func togglePin() {
        message.pinned.toggle()
        message.updatedAt = Date()
        if let server = message.server {
            let op = OutboxOp(server: server,
                              kind: message.pinned ? .pin : .unpin,
                              messageLocalID: message.localID)
            modelContext.insert(op)
            message.syncState = .pending
        }
        try? modelContext.save()
    }

    private func deleteMessage() {
        message.deletedAt = Date()
        if let server = message.server {
            let op = OutboxOp(server: server, kind: .delete, messageLocalID: message.localID)
            modelContext.insert(op)
        }
        try? modelContext.save()
    }

    private func retrySync() {
        // Simple retry: reset attempts on the outbox op for this message.
        guard let server = message.server else { return }
        for op in server.outboxOps where op.messageLocalID == message.localID {
            op.attempts = 0
            op.nextRetryAt = Date()
        }
        message.syncState = .pending
        try? modelContext.save()
    }
}

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
