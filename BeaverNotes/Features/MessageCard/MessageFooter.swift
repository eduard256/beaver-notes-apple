import SwiftUI

struct MessageFooter: View {
    let message: Message
    let onCopy: () -> Void
    let onPin: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: Space.s2) {
            Text(DateLabels.time(message.createdAt))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(Palette.textTertiary)
            SyncStateBadge(state: message.syncState, onRetry: onRetry)
            Spacer()
            MessageActions(message: message, onCopy: onCopy, onPin: onPin, onEdit: onEdit, onDelete: onDelete)
        }
        .padding(.top, Space.s2)
    }
}
