import Foundation
import SwiftData

struct OutboxPayload: Codable, Sendable {
    var content: String?
}

enum OutboxProcessor {
    @MainActor
    static func processOnce(server: Server, client: APIClient, context: ModelContext) async {
        let now = Date.now
        let descriptor = FetchDescriptor<OutboxOp>(sortBy: [SortDescriptor(\.createdAt)])
        let all = (try? context.fetch(descriptor)) ?? []
        let ops = all.filter { $0.server?.id == server.id && $0.nextRetryAt <= now }

        for op in ops {
            await process(op: op, server: server, client: client, context: context)
        }
    }

    @MainActor
    private static func process(op: OutboxOp, server: Server, client: APIClient, context: ModelContext) async {
        let targetID = op.messageLocalID
        let msgDescriptor = FetchDescriptor<Message>(predicate: #Predicate { $0.localID == targetID })
        let message = try? context.fetch(msgDescriptor).first

        do {
            switch op.kind {
            case .create:
                guard let message else { context.delete(op); break }
                message.syncState = .syncing
                try context.save()

                let fileURLs = uploadableFiles(in: message)
                let dto: MessageDTO
                if fileURLs.isEmpty {
                    dto = try await client.createMessage(content: message.content)
                } else {
                    dto = try await client.createMessage(content: message.content, fileURLs: fileURLs)
                }
                message.serverID = dto.id
                message.serverUpdatedAt = dto.updated_at
                message.syncState = .synced
                for (i, f) in (dto.files ?? []).enumerated() where i < message.files.count {
                    message.files[i].serverID = f.id
                    message.files[i].transferState = .done
                }
                context.delete(op)

            case .edit:
                guard let message, let sid = message.serverID else { context.delete(op); break }
                let dto = try await client.editMessage(serverID: sid, content: message.content)
                message.serverUpdatedAt = dto.updated_at
                message.syncState = .synced
                context.delete(op)

            case .pin:
                guard let message, let sid = message.serverID else { context.delete(op); break }
                _ = try await client.setPinned(serverID: sid, pinned: true)
                message.syncState = .synced
                context.delete(op)

            case .unpin:
                guard let message, let sid = message.serverID else { context.delete(op); break }
                _ = try await client.setPinned(serverID: sid, pinned: false)
                message.syncState = .synced
                context.delete(op)

            case .delete:
                if let message, let sid = message.serverID {
                    try await client.deleteMessage(serverID: sid)
                    context.delete(message)
                }
                context.delete(op)

            case .deleteFile:
                if let payload = String(data: op.payloadData, encoding: .utf8), !payload.isEmpty {
                    try await client.deleteFile(serverID: payload)
                }
                context.delete(op)
            }
            try context.save()
        } catch {
            recordFailure(op: op, error: error, context: context)
        }
    }

    private static func recordFailure(op: OutboxOp, error: Error, context: ModelContext) {
        op.attempts += 1
        op.lastError = String(describing: error)
        let backoff = min(600.0, pow(2.0, Double(op.attempts)) * 5.0)
        op.nextRetryAt = Date.now.addingTimeInterval(backoff)
        let targetID = op.messageLocalID
        if op.attempts >= 50, let descriptor = try? context.fetch(FetchDescriptor<Message>(predicate: #Predicate { $0.localID == targetID })).first {
            descriptor.syncState = .failed
        }
        try? context.save()
    }

    private static func uploadableFiles(in message: Message) -> [URL] {
        message.files.compactMap { f -> URL? in
            if let path = f.sourcePath { return URL(fileURLWithPath: path) }
            if let path = f.localPath { return URL(fileURLWithPath: path) }
            return nil
        }
    }
}
