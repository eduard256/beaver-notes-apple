import SwiftUI

struct MessageContextMenu: View {
    let message: Message
    let onCopy: () -> Void
    let onPin: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Group {
            Button { onCopy() } label: { Label("Copy text", systemImage: SF.copy) }
            Button { onPin() }  label: {
                Label(message.pinned ? "Unpin" : "Pin",
                      systemImage: message.pinned ? SF.pin : SF.pinFill)
            }
            Button { onEdit() } label: { Label("Edit", systemImage: SF.pencil) }
            Divider()
            Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: SF.trash) }
        }
    }
}
