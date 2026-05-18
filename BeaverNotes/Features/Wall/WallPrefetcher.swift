import SwiftUI

// Triggers downloads for visible message attachments so they appear instantly.
@MainActor
final class WallPrefetcher {
    static let shared = WallPrefetcher()
    private var inflight: Set<String> = []

    func prefetch(file: LocalFile, server: Server) {
        guard let sid = file.serverID, file.size < 2_000_000 else { return }
        guard let url = server.url else { return }
        if inflight.contains(sid) { return }
        inflight.insert(sid)

        Task.detached {
            let cached = await FileCache.shared.cachedURL(serverID: sid)
            if cached != nil { return }
            let client = APIClient(serverURL: url, cookieIdentifier: server.cookieStorageIdentifier)
            let dst = AppGroup.fileCacheDir.appendingPathComponent(sid)
            try? await client.downloadFile(serverID: sid, to: dst)
        }
    }
}
