import Foundation
import SwiftData

// Pulls fresh messages and tombstones from a server and reconciles them into the local store.
// Uses ?since= for incremental sync and ETag/If-None-Match for cheap polling.
enum PullEngine {
    @MainActor
    static func pull(server: Server, client: APIClient, context: ModelContext) async {
        do {
            let query = MessageQuery(limit: 200)
            let since = server.lastSyncAt
            let etag = server.lastETag

            let result = try await client.fetchMessages(query: query, since: since, ifNoneMatch: etag)

            if result.notModified {
                return
            }

            guard let resp = result.response else { return }

            var maxUpdated = since ?? .distantPast
            for dto in resp.messages {
                MergeStrategy.upsert(dto: dto, server: server, context: context)
                if dto.updated_at > maxUpdated { maxUpdated = dto.updated_at }
            }

            server.lastSyncAt = maxUpdated
            server.lastETag = result.etag
            try context.save()
        } catch APIError.unauthorized {
            // re-auth handled by SyncCoordinator
        } catch {
            // swallow, next tick will retry
        }
    }
}
