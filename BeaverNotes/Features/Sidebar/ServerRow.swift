import SwiftUI

struct ServerRow: View {
    let server: Server
    let isActive: Bool
    let pendingCount: Int

    var body: some View {
        HStack(spacing: Space.s3) {
            Avatar(letter: String(server.name.prefix(1)).uppercased(), active: isActive)

            VStack(alignment: .leading, spacing: 2) {
                Text(server.name)
                    .font(.callout.weight(isActive ? .semibold : .regular))
                    .foregroundStyle(Palette.textPrimary)
                Text(hostString)
                    .font(.caption2)
                    .foregroundStyle(Palette.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            if pendingCount > 0 {
                Text("\(pendingCount)")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Palette.danger.opacity(0.15))
                    .foregroundStyle(Palette.danger)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }

    private var hostString: String {
        server.url?.host ?? server.urlString
    }

    struct Avatar: View {
        let letter: String
        let active: Bool
        var body: some View {
            ZStack {
                Circle()
                    .fill(active ? Palette.accent : Palette.bgTertiary)
                    .frame(width: 28, height: 28)
                Text(letter)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(active ? Palette.bgPrimary : Palette.textSecondary)
            }
        }
    }
}
