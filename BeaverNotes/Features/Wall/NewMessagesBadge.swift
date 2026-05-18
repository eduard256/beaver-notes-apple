import SwiftUI

struct NewMessagesBadge: View {
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.s2) {
                Image(systemName: Symbols.chevronUp)
                Text("\(count) new")
                    .font(.callout.weight(.medium))
            }
            .padding(.horizontal, Space.s4)
            .padding(.vertical, Space.s2)
            .background(Palette.accent)
            .foregroundStyle(Palette.bgPrimary)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }
}
