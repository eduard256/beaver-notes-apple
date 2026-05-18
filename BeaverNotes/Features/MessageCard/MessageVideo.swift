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
                    Text(formatBytes(file.size))
                        .font(.caption2)
                        .foregroundStyle(Palette.textTertiary)
                }
                Spacer()
            }
            .padding(Space.s3)
            .background(Palette.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $presentingPlayer) {
            if let url = videoURL() {
                VideoPlayer(player: AVPlayer(url: url))
                    .ignoresSafeArea()
            }
        }
    }

    private func videoURL() -> URL? {
        if let local = file.localPath { return URL(fileURLWithPath: local) }
        guard let server, let base = server.url, let sid = file.serverID else { return nil }
        return base.appendingPathComponent("api/files/\(sid)")
    }
}
