import Foundation

enum Drafts {
    private static func key(_ serverID: UUID) -> String { "draft.\(serverID.uuidString)" }

    static func load(forServer id: UUID) -> String {
        AppGroup.userDefaults.string(forKey: key(id)) ?? ""
    }

    static func save(_ text: String, forServer id: UUID) {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            AppGroup.userDefaults.removeObject(forKey: key(id))
        } else {
            AppGroup.userDefaults.set(text, forKey: key(id))
        }
    }
}
