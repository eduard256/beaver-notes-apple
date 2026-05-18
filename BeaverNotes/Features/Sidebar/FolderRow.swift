import SwiftUI

struct FolderRow: View {
    let icon: String
    let label: String
    var count: Int? = nil

    var body: some View {
        HStack(spacing: Space.s3) {
            Image(systemName: icon)
                .foregroundStyle(Palette.textSecondary)
                .frame(width: 22)
            Text(label)
                .foregroundStyle(Palette.textPrimary)
            Spacer()
            if let count, count > 0 {
                Text("\(count)")
                    .font(.caption)
                    .foregroundStyle(Palette.textTertiary)
            }
        }
    }
}
