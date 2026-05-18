import SwiftUI

struct NewMessagesBadge: View {
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.s2) {
                Text(countText)
                Image(systemName: SF.chevronUp)
                    .font(.caption.weight(.semibold))
            }
            .font(.caption.weight(.medium))
            .padding(.horizontal, Space.s4)
            .padding(.vertical, Space.s2)
            .background(.ultraThinMaterial)
            .overlay(Capsule().stroke(Palette.borderPrimary, lineWidth: 1))
            .clipShape(Capsule())
            .foregroundStyle(Palette.textPrimary)
            .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var countText: String {
        count == 1 ? "1 new message" : "\(count) new messages"
    }
}
