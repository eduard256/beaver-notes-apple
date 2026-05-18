import SwiftUI

struct FolderRow: View {
    let symbol: String
    let title: String
    let count: Int?
    let isActive: Bool

    var body: some View {
        HStack(spacing: Space.s3) {
            Image(systemName: symbol)
                .foregroundStyle(isActive ? Palette.accent : Palette.textSecondary)
                .frame(width: 18)
            Text(title)
                .font(.callout)
                .foregroundStyle(Palette.textPrimary)
            Spacer()
            if let count {
                Text("\(count)").font(.caption).foregroundStyle(Palette.textTertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
