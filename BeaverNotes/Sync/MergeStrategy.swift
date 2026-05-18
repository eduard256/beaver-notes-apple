import Foundation
import SwiftData

// Last-write-wins reconciliation between a server-side message DTO and the local store.
enum MergeStrategy {
    static func upsert(dto: MessageDTO, server: Server, context: ModelContext) {
        let localServerID = server.id

        // Find existing local message by serverID
        let descriptor = FetchDescriptor<Message>(predicate: #Predicate { $0.serverID == dto.id })
        let candidates = (try? context.fetch(descriptor)) ?? []
        let existing = candidates.first { $0.server?.id == localServerID }

        if let tomb = dto.deleted_at {
            if let m = existing {
                m.deletedAt = tomb
                m.serverUpdatedAt = dto.updated_at
            }
            try? context.save()
            return
        }

        if let m = existing {
            // LWW: server wins if its updatedAt is strictly newer than what we last saw.
            if let last = m.serverUpdatedAt, dto.updated_at <= last { return }
            m.content = dto.content
            m.pinned = dto.pinned
            m.updatedAt = dto.updated_at
            m.serverUpdatedAt = dto.updated_at
            m.tags = dto.tags ?? []
            m.syncState = .synced
            applyFiles(dto.files ?? [], to: m)
        } else {
            let m = Message(
                server: server,
                serverID: dto.id,
                content: dto.content,
                pinned: dto.pinned,
                createdAt: dto.created_at,
                tags: dto.tags ?? [],
                syncState: .synced
            )
            m.updatedAt = dto.updated_at
            m.serverUpdatedAt = dto.updated_at
            context.insert(m)
            applyFiles(dto.files ?? [], to: m)
        }
        try? context.save()
    }

    private static func applyFiles(_ files: [FileDTO], to msg: Message) {
        let serverIDs = Set(files.map(\.id))
        msg.files.removeAll { $0.serverID.map { !serverIDs.contains($0) } ?? false }

        for f in files where !msg.files.contains(where: { $0.serverID == f.id }) {
            let local = LocalFile(
                serverID: f.id,
                filename: f.filename,
                mimeType: f.mime_type,
                size: f.size,
                transferState: .none
            )
            msg.files.append(local)
        }
    }
}
