import Foundation

nonisolated enum AppGroup {
    static let identifier = "group.com.webaweba.BeaverNotes"

    static var containerURL: URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) else {
            // sandbox without group entitlement (e.g. preview) — fall back to documents
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        }
        return url
    }

    static var databaseURL: URL {
        let url = containerURL.appendingPathComponent("Database", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url.appendingPathComponent("beaver.sqlite")
    }

    static var fileCacheDir: URL {
        let url = containerURL.appendingPathComponent("FileCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static var outboxFilesDir: URL {
        let url = containerURL.appendingPathComponent("OutboxFiles", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static let userDefaults = UserDefaults(suiteName: identifier) ?? .standard
}
