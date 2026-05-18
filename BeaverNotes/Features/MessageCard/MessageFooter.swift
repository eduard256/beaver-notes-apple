import SwiftUI

struct MessageFooter: View {
    let message: Message
    let onCopy: () -> Void
    let onPin: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Space.s3) {
            Text(message.createdAt, format: .dateTime.hour().minute())
                .font(.caption)
                .foregroundStyle(Palette.textTertiary)
            SyncStateBadge(state: message.syncState)
            Spacer()
            MessageActions(message: message, onCopy: onCopy, onPin: onPin, onEdit: onEdit, onDelete: onDelete)
        }
        .padding(.top, Space.s1)
    }
}
