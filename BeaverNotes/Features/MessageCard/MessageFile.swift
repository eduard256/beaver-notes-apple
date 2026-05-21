import SwiftUI

struct MessageFileRow: View {
    let file: LocalFile
    let server: Server?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
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
                        Text(rowSubtitle)
                            .font(.caption2)
                            .foregroundStyle(file.transferState == .failed ? Palette.danger : Palette.textTertiary)
                    }
                    Spacer()
                    statusIcon
                }
                TransferProgressOverlay(file: file, style: .row)
            }
            .padding(Space.s3)
            .background(Palette.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch file.transferState {
        case .transferring, .queued:
            Image(systemName: SF.arrowsClock)
                .foregroundStyle(Palette.textTertiary)
                .symbolEffect(.pulse, options: .repeating)
        case .failed:
            Image(systemName: SF.warning)
                .foregroundStyle(Palette.danger)
        default:
            Image(systemName: SF.download)
                .foregroundStyle(Palette.textTertiary)
        }
    }

    private var rowSubtitle: String {
        switch file.transferState {
        case .transferring, .queued:
            return "Uploading… \(formatBytes(file.size))"
        case .failed:
            return "Upload failed · \(formatBytes(file.size))"
        default:
            return formatBytes(file.size)
        }
    }
}

func formatBytes(_ bytes: Int64) -> String {
    let fmt = ByteCountFormatter()
    fmt.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
    fmt.countStyle = .file
    return fmt.string(fromByteCount: bytes)
}
