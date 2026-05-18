import Foundation
import SwiftData

@Model
final class Server {
    @Attribute(.unique) var id: UUID
    var name: String
    var urlString: String
    var sortOrder: Int
    var lastUsedAt: Date
    var lastSyncAt: Date?
    var lastETag: String?
    var pollingIntervalSeconds: Int

    @Relationship(deleteRule: .cascade, inverse: \Message.server)
    var messages: [Message] = []

    @Relationship(deleteRule: .cascade, inverse: \OutboxOp.server)
    var outboxOps: [OutboxOp] = []

    init(
        id: UUID = UUID(),
        name: String,
        urlString: String,
        sortOrder: Int = 0,
        pollingIntervalSeconds: Int = 7
    ) {
        self.id = id
        self.name = name
        self.urlString = urlString
        self.sortOrder = sortOrder
        self.lastUsedAt = Date()
        self.pollingIntervalSeconds = pollingIntervalSeconds
    }

    var url: URL? { URL(string: urlString) }

    var cookieStorageIdentifier: String { "group.com.webaweba.BeaverNotes.\(id.uuidString)" }
}
