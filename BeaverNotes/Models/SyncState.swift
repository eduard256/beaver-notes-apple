import Foundation

enum SyncState: String, Codable, CaseIterable {
    case local      // created offline, not yet queued
    case pending    // queued in outbox
    case syncing    // active network call
    case synced     // committed on server
    case failed     // exceeded retries
}
