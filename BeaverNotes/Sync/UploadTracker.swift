import Foundation
import Observation

@MainActor
@Observable
final class UploadTracker {
    static let shared = UploadTracker()

    private(set) var fileProgress: [UUID: Double] = [:]
    private(set) var messageProgress: [UUID: Double] = [:]
    private(set) var activeMessages: Set<UUID> = []

    func begin(messageID: UUID, fileIDs: [UUID]) {
        activeMessages.insert(messageID)
        for id in fileIDs { fileProgress[id] = 0 }
        messageProgress[messageID] = 0
    }

    func update(fileID: UUID, progress: Double) {
        fileProgress[fileID] = max(0, min(1, progress))
    }

    func update(messageID: UUID, progress: Double) {
        messageProgress[messageID] = max(0, min(1, progress))
    }

    func finish(messageID: UUID, fileIDs: [UUID]) {
        activeMessages.remove(messageID)
        messageProgress.removeValue(forKey: messageID)
        for id in fileIDs { fileProgress.removeValue(forKey: id) }
    }

    func cancel(messageID: UUID, fileIDs: [UUID]) {
        finish(messageID: messageID, fileIDs: fileIDs)
    }

    func progressForFile(_ fileID: UUID) -> Double? {
        fileProgress[fileID]
    }

    func progressForMessage(_ messageID: UUID) -> Double? {
        messageProgress[messageID]
    }

    func isActive(messageID: UUID) -> Bool {
        activeMessages.contains(messageID)
    }
}
