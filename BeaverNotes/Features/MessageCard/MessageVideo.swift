import SwiftUI
import AVKit

struct MessageVideoRow: View {
    let file: LocalFile
    let server: Server?

    @State private var presentingPlayer = false

    var body: some View {
        Button {
            presentingPlayer = true
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: Space.s3) {
                    ZStack {
                        RoundedRectangle(cornerRadius: Radius.sm)
                            .fill(Palette.bgTertiary)
                            .frame(width: 56, height: 56)
                        Image(systemName: SF.play)
                            .font(.title3)
                            .foregroundStyle(Palette.textSecondary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(file.filename)
                            .font(.callout.weight(.medium))
                            .foregroundStyle(Palette.textPrimary)
                            .lineLimit(1)
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(file.transferState == .failed ? Palette.danger : Palette.textTertiary)
                    }
                    Spacer()
                    if file.transferState == .transferring || file.transferState == .queued {
                        Image(systemName: SF.arrowsClock)
                            .foregroundStyle(Palette.textTertiary)
                            .symbolEffect(.pulse, options: .repeating)
                    } else if file.transferState == .failed {
                        Image(systemName: SF.warning)
                            .foregroundStyle(Palette.danger)
                    }
                }
                TransferProgressOverlay(file: file, style: .row)
            }
            .padding(Space.s3)
            .background(Palette.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
        .buttonStyle(.plain)
        .disabled(file.transferState == .transferring || file.transferState == .queued)
        .sheet(isPresented: $presentingPlayer) {
            if let url = videoURL() {
                VideoPlayer(player: AVPlayer(url: url))
                    .ignoresSafeArea()
            }
        }
    }

    private var subtitle: String {
        switch file.transferState {
        case .transferring, .queued:
            return "Uploading… \(formatBytes(file.size))"
        case .failed:
            return "Upload failed · \(formatBytes(file.size))"
        default:
            return formatBytes(file.size)
        }
    }

    private func videoURL() -> URL? {
        if let local = file.localPath { return URL(fileURLWithPath: local) }
        guard let server, let base = server.url, let sid = file.serverID else { return nil }
        return base.appendingPathComponent("api/files/\(sid)")
    }
}
