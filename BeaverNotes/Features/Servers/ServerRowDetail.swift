import SwiftUI

struct ServerRowDetail: View {
    let server: Server

    var body: some View {
        HStack(spacing: Space.s3) {
            ZStack {
                Circle().fill(Palette.accent.opacity(0.15))
                Text(String(server.name.prefix(1)).uppercased())
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Palette.accent)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(server.name).foregroundStyle(Palette.textPrimary)
                Text(server.urlString)
                    .font(.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: Symbols.chevronRight)
                .font(.caption)
                .foregroundStyle(Palette.textTertiary)
        }
    }
}
