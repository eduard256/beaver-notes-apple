import Foundation
import SwiftData

enum OutboxOpKind: String, Codable {
    case create
    case edit
    case pin
    case unpin
    case delete
    case deleteFile
}

@Model
final class OutboxOp {
    @Attribute(.unique) var id: UUID
    var kindRaw: String
    var messageLocalID: UUID
    var payloadData: Data
    var createdAt: Date
    var attempts: Int
    var nextRetryAt: Date
    var lastError: String?

    var server: Server?

    init(
        id: UUID = UUID(),
        server: Server,
        kind: OutboxOpKind,
        messageLocalID: UUID,
        payload: Data = Data()
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.messageLocalID = messageLocalID
        self.payloadData = payload
        self.createdAt = Date()
        self.attempts = 0
        self.nextRetryAt = Date()
        self.server = server
    }

    var kind: OutboxOpKind {
        get { OutboxOpKind(rawValue: kindRaw) ?? .create }
        set { kindRaw = newValue.rawValue }
    }
}
