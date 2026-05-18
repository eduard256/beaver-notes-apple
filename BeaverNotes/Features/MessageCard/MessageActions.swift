import SwiftUI

struct MessageActions: View {
    let message: Message
    let onCopy: () -> Void
    let onPin: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Space.s2) {
            iconButton(Symbols.copy, action: onCopy)
            iconButton(message.pinned ? Symbols.pinFill : Symbols.pin, color: message.pinned ? Palette.pin : Palette.textSecondary, action: onPin)
            iconButton(Symbols.pencil, action: onEdit)
            iconButton(Symbols.trash, color: Palette.danger, action: onDelete)
        }
    }

    @ViewBuilder
    private func iconButton(_ symbol: String, color: Color = Palette.textSecondary, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.callout)
                .foregroundStyle(color)
                .frame(width: 30, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
