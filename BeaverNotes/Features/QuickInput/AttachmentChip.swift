import SwiftUI

struct AttachmentChip: View {
    let name: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: SF.file).font(.caption2)
            Text(name)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 160)
            Button(action: onRemove) {
                Image(systemName: SF.close).font(.caption2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Space.s2)
        .padding(.vertical, 4)
        .foregroundStyle(Palette.textSecondary)
        .background(Palette.bgSecondary)
        .clipShape(Capsule())
    }
}
