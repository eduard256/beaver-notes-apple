import Foundation

enum ETagStore {
    private static func key(_ serverID: UUID) -> String { "etag.\(serverID.uuidString)" }

    static func load(serverID: UUID) -> String? {
        AppGroup.userDefaults.string(forKey: key(serverID))
    }

    static func save(_ etag: String?, serverID: UUID) {
        if let etag {
            AppGroup.userDefaults.set(etag, forKey: key(serverID))
        } else {
            AppGroup.userDefaults.removeObject(forKey: key(serverID))
        }
    }
}
