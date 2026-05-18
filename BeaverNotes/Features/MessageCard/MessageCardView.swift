import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct MessageCardView: View {
    let message: Message
    var onEdit: () -> Void = {}
    @Environment(\.modelContext) private var modelContext
    @State private var confirmingDelete = false

    var body: some View {
        BeaverCard(pinned: message.pinned) {
            VStack(alignment: .leading, spacing: Space.s3) {
                MessageBody(content: message.content)
                MessageImages(message: message)
                MessageVideo(message: message)
                MessageFiles(message: message)
                MessageTags(tags: message.tags)
                MessageFooter(message: message, onCopy: copy, onPin: togglePin, onEdit: onEdit, onDelete: { confirmingDelete = true })
            }
        }
        .contextMenu { MessageContextMenu(message: message, onCopy: copy, onEdit: onEdit, onPin: togglePin, onDelete: { confirmingDelete = true }) }
        .swipeActions(edge: .leading) {
            Button { togglePin() } label: {
                Label(message.pinned ? "Unpin" : "Pin", systemImage: message.pinned ? Symbols.pin : Symbols.pinFill)
            }
            .tint(Palette.pin)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { confirmingDelete = true } label: {
                Label("Delete", systemImage: Symbols.trash)
            }
        }
        .confirmationDialog("Delete this note?", isPresented: $confirmingDelete) {
            Button("Delete", role: .destructive) { performDelete() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func copy() {
        Pasteboard.set(message.content)
        Haptics.success()
    }

    private func togglePin() {
        guard let server = message.server else { return }
        message.pinned.toggle()
        message.updatedAt = Date()
        let op = OutboxOp(server: server, kind: message.pinned ? .pin : .unpin, messageLocalID: message.localID)
        modelContext.insert(op)
        message.syncState = .pending
        try? modelContext.save()
        Haptics.tap()
    }

    private func performDelete() {
        guard let server = message.server else { return }
        message.deletedAt = Date()
        if message.serverID != nil {
            let op = OutboxOp(server: server, kind: .delete, messageLocalID: message.localID)
            modelContext.insert(op)
        } else {
            modelContext.delete(message)
        }
        try? modelContext.save()
        Haptics.warning()
    }
}

enum Pasteboard {
    static func set(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}
