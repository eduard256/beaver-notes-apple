import SwiftUI

struct MessageFileRow: View {
    let file: LocalFile
    let server: Server?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Space.s3) {
                Image(systemName: SF.file)
                    .font(.title3)
                    .foregroundStyle(Palette.textSecondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(file.filename)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(1)
                    Text(formatBytes(file.size))
                        .font(.caption2)
                        .foregroundStyle(Palette.textTertiary)
                }
                Spacer()
                Image(systemName: SF.download)
                    .foregroundStyle(Palette.textTertiary)
            }
            .padding(Space.s3)
            .background(Palette.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
        .buttonStyle(.plain)
    }
}

func formatBytes(_ bytes: Int64) -> String {
    let fmt = ByteCountFormatter()
    fmt.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
    fmt.countStyle = .file
    return fmt.string(fromByteCount: bytes)
}
