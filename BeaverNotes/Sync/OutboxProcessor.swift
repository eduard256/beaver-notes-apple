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

                let uploads = uploadFiles(for: message)
                let dto: MessageDTO
                if uploads.isEmpty {
                    dto = try await client.createMessage(content: message.content)
                } else {
                    dto = try await uploadWithProgress(message: message, uploads: uploads, server: server)
                }
                message.serverID = dto.id
                message.serverUpdatedAt = dto.updated_at
                message.syncState = .synced
                for (i, f) in (dto.files ?? []).enumerated() where i < message.files.count {
                    message.files[i].serverID = f.id
                    message.files[i].transferState = .done
                    message.files[i].bytesTransferred = message.files[i].size
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

    private static func uploadFiles(for message: Message) -> [UploadFile] {
        message.files.compactMap { f -> UploadFile? in
            let url: URL
            if let path = f.sourcePath {
                url = URL(fileURLWithPath: path)
            } else if let path = f.localPath {
                url = URL(fileURLWithPath: path)
            } else {
                return nil
            }
            return UploadFile(localID: f.localID, url: url, filename: f.filename, mimeType: f.mimeType, size: f.size)
        }
    }

    @MainActor
    private static func uploadWithProgress(message: Message, uploads: [UploadFile], server: Server) async throws -> MessageDTO {
        let tracker = UploadTracker.shared
        let messageID = message.localID
        let fileIDs = uploads.map(\.localID)
        tracker.begin(messageID: messageID, fileIDs: fileIDs)
        for f in message.files where fileIDs.contains(f.localID) {
            f.transferState = .transferring
            f.bytesTransferred = 0
        }
        try? message.modelContext?.save()

        guard let baseURL = server.url else { throw APIError.invalidResponse }
        let uploader = MessageUploader(serverURL: baseURL, cookieIdentifier: server.cookieStorageIdentifier)

        do {
            let dto = try await uploader.uploadCreate(content: message.content, files: uploads) { event in
                Task { @MainActor in
                    switch event {
                    case .file(let id, let progress):
                        tracker.update(fileID: id, progress: progress)
                    case .total(let progress):
                        tracker.update(messageID: messageID, progress: progress)
                    }
                }
            }
            tracker.finish(messageID: messageID, fileIDs: fileIDs)
            return dto
        } catch {
            tracker.cancel(messageID: messageID, fileIDs: fileIDs)
            for f in message.files where fileIDs.contains(f.localID) {
                f.transferState = .failed
            }
            try? message.modelContext?.save()
            throw error
        }
    }
}
