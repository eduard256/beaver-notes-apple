import SwiftUI

struct ServerRow: View {
    let server: Server
    let selected: Bool

    var body: some View {
        HStack(spacing: Space.s3) {
            ZStack {
                Circle().fill(Palette.accent.opacity(0.15))
                Text(String(server.name.prefix(1)).uppercased())
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Palette.accent)
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(server.name)
                    .font(.callout)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                Text(server.urlString)
                    .font(.caption2)
                    .foregroundStyle(Palette.textTertiary)
                    .lineLimit(1)
            }
            Spacer()
            let pending = server.outboxOps.count
            if pending > 0 {
                Text("\(pending)")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Palette.accent.opacity(0.18), in: Capsule())
                    .foregroundStyle(Palette.accent)
            }
        }
        .padding(.vertical, 2)
        .listRowBackground(selected ? Palette.accent.opacity(0.10) : Color.clear)
    }
}
