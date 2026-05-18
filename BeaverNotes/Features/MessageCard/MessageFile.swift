import SwiftUI

struct MessageFiles: View {
    let message: Message

    private var others: [LocalFile] {
        message.files.filter { !$0.isImage && !$0.isVideo }
    }

    var body: some View {
        if !others.isEmpty {
            VStack(spacing: Space.s2) {
                ForEach(others) { f in
                    MessageFileRow(file: f, server: message.server)
                }
            }
        }
    }
}

struct MessageFileRow: View {
    let file: LocalFile
    let server: Server?

    var body: some View {
        HStack(spacing: Space.s3) {
            Image(systemName: Symbols.file)
                .foregroundStyle(Palette.textSecondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(file.filename)
                    .font(.callout)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                Text(formatBytes(file.size))
                    .font(.caption)
                    .foregroundStyle(Palette.textTertiary)
            }
            Spacer()
            Image(systemName: Symbols.download)
                .foregroundStyle(Palette.accent)
        }
        .padding(Space.s3)
        .background(Palette.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
        .contentShape(Rectangle())
        .onTapGesture { Task { await download() } }
    }

    private func download() async {
        guard let sid = file.serverID, let server, let url = server.url else { return }
        let client = APIClient(serverURL: url, cookieIdentifier: server.cookieStorageIdentifier)
        let dst = AppGroup.fileCacheDir.appendingPathComponent(sid)
        try? await client.downloadFile(serverID: sid, to: dst)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter().string(fromByteCount: bytes)
    }
}
