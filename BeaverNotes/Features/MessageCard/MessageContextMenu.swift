import SwiftUI

struct MessageContextMenu: View {
    let message: Message
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Group {
            Button { onCopy() } label: { Label("Copy", systemImage: Symbols.copy) }
            Button { onEdit() } label: { Label("Edit", systemImage: Symbols.pencil) }
            Button { onPin() } label: {
                Label(message.pinned ? "Unpin" : "Pin", systemImage: message.pinned ? Symbols.pin : Symbols.pinFill)
            }
            Divider()
            Button(role: .destructive) { onDelete() } label: {
                Label("Delete", systemImage: Symbols.trash)
            }
        }
    }
}
