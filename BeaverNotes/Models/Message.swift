import Foundation
import SwiftData

@Model
final class Message {
    @Attribute(.unique) var localID: UUID
    var serverID: String?
    var content: String
    var pinned: Bool
    var createdAt: Date
    var updatedAt: Date
    var serverUpdatedAt: Date?
    var deletedAt: Date?
    var syncStateRaw: String
    var tags: [String]

    var server: Server?

    @Relationship(deleteRule: .cascade)
    var files: [LocalFile] = []

    init(
        localID: UUID = UUID(),
        server: Server,
        serverID: String? = nil,
        content: String,
        pinned: Bool = false,
        createdAt: Date = Date(),
        tags: [String] = [],
        syncState: SyncState = .local
    ) {
        self.localID = localID
        self.serverID = serverID
        self.content = content
        self.pinned = pinned
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.tags = tags
        self.server = server
        self.syncStateRaw = syncState.rawValue
    }

    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .local }
        set { syncStateRaw = newValue.rawValue }
    }
}
