import SwiftUI

struct BeaverChip: View {
    let text: String
    var active: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        let label = Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, Space.s3)
            .padding(.vertical, 5)
            .background(active ? Palette.accent.opacity(0.12) : Palette.bgSecondary)
            .foregroundStyle(active ? Palette.textPrimary : Palette.textSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.xl)
                    .stroke(active ? Palette.accent : Palette.borderSecondary, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.xl))

        if let action {
            Button(action: action) { label }.buttonStyle(.plain)
        } else {
            label
        }
    }
}
