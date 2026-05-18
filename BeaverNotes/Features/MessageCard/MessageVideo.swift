import SwiftUI
import AVKit

struct MessageVideo: View {
    let message: Message
    @State private var playerURL: URL?
    @State private var presenting = false

    private var videos: [LocalFile] { message.files.filter { $0.isVideo } }

    var body: some View {
        if !videos.isEmpty {
            VStack(spacing: Space.s2) {
                ForEach(videos) { v in
                    posterFor(v)
                }
            }
            .sheet(isPresented: $presenting) {
                if let url = playerURL {
                    VideoPlayer(player: AVPlayer(url: url))
                        #if os(iOS)
                        .ignoresSafeArea()
                        #endif
                }
            }
        }
    }

    private func posterFor(_ file: LocalFile) -> some View {
        ZStack {
            Palette.bgTertiary
            Image(systemName: Symbols.play)
                .font(.system(size: 40))
                .foregroundStyle(.white)
                .padding(Space.s4)
                .background(Color.black.opacity(0.4), in: Circle())
        }
        .aspectRatio(16/9, contentMode: .fit)
        .frame(maxWidth: 420)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .contentShape(Rectangle())
        .onTapGesture { Task { await present(file) } }
    }

    private func present(_ file: LocalFile) async {
        if let local = file.localPath {
            playerURL = URL(fileURLWithPath: local)
            presenting = true
            return
        }
        if let source = file.sourcePath {
            playerURL = URL(fileURLWithPath: source)
            presenting = true
            return
        }
        guard let sid = file.serverID, let server = message.server, let url = server.url else { return }
        if let cached = await FileCache.shared.cachedURL(serverID: sid) {
            playerURL = cached
            presenting = true
            return
        }
        let client = APIClient(serverURL: url, cookieIdentifier: server.cookieStorageIdentifier)
        let dst = AppGroup.fileCacheDir.appendingPathComponent(sid)
        do {
            try await client.downloadFile(serverID: sid, to: dst)
            playerURL = dst
            presenting = true
        } catch {}
    }
}
