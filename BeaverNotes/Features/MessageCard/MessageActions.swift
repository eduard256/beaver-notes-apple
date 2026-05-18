import SwiftUI

struct MessageActions: View {
    let message: Message
    let onCopy: () -> Void
    let onPin: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var copied = false
    @State private var confirmDelete = false

    var body: some View {
        HStack(spacing: 2) {
            actionButton(symbol: copied ? SF.copyDone : SF.copy, danger: false, success: copied) {
                onCopy()
                copied = true
                Haptics.success()
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    copied = false
                }
            }
            actionButton(symbol: message.pinned ? SF.pinFill : SF.pin, danger: false, success: false) {
                onPin()
                Haptics.tap()
            }
            actionButton(symbol: SF.pencil, danger: false, success: false, action: onEdit)
            if confirmDelete {
                Button {
                    onDelete()
                    Haptics.warning()
                    confirmDelete = false
                } label: {
                    Text("Delete?")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.danger)
                        .padding(.horizontal, 6)
                        .frame(height: 24)
                        .background(Palette.danger.opacity(0.1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else {
                actionButton(symbol: SF.trash, danger: true, success: false) {
                    confirmDelete = true
                    Task {
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        confirmDelete = false
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func actionButton(symbol: String, danger: Bool, success: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.caption.weight(.medium))
                .foregroundStyle(success ? Palette.success : (danger ? Palette.danger : Palette.textTertiary))
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
    }
}
