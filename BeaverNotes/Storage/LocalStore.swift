import Foundation
import SwiftData

@ModelActor
actor LocalStore {
    func server(byID id: UUID) -> Server? {
        let descriptor = FetchDescriptor<Server>(predicate: #Predicate { $0.id == id })
        return try? modelContext.fetch(descriptor).first
    }

    func allServers() -> [Server] {
        let descriptor = FetchDescriptor<Server>(sortBy: [SortDescriptor(\.sortOrder)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func saveContext() {
        try? modelContext.save()
    }

    // Outbox

    func pendingOutboxOps(forServer serverID: UUID, limit: Int = 20) -> [OutboxOp] {
        let now = Date.now
        let d = FetchDescriptor<OutboxOp>(sortBy: [SortDescriptor(\.createdAt)])
        let all = (try? modelContext.fetch(d)) ?? []
        return all
            .filter { $0.server?.id == serverID && $0.nextRetryAt <= now }
            .prefix(limit)
            .map { $0 }
    }

    func enqueueOutbox(_ op: OutboxOp) {
        modelContext.insert(op)
        try? modelContext.save()
    }

    func deleteOutboxOp(_ op: OutboxOp) {
        modelContext.delete(op)
        try? modelContext.save()
    }

    func recordOutboxFailure(_ op: OutboxOp, error: String) {
        op.attempts += 1
        op.lastError = error
        let backoff = min(600.0, pow(2.0, Double(op.attempts)) * 5.0)
        op.nextRetryAt = Date.now.addingTimeInterval(backoff)
        try? modelContext.save()
    }

    // Messages

    func message(localID: UUID) -> Message? {
        let d = FetchDescriptor<Message>(predicate: #Predicate { $0.localID == localID })
        return try? modelContext.fetch(d).first
    }

    func message(serverID: String, inServer serverUUID: UUID) -> Message? {
        let d = FetchDescriptor<Message>(predicate: #Predicate { $0.serverID == serverID })
        let candidates = (try? modelContext.fetch(d)) ?? []
        return candidates.first { $0.server?.id == serverUUID }
    }

    func upsert(_ msg: Message) {
        modelContext.insert(msg)
        try? modelContext.save()
    }

    func delete(_ msg: Message) {
        modelContext.delete(msg)
        try? modelContext.save()
    }
}
