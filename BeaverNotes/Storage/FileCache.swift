import Foundation

actor FileCache {
    static let shared = FileCache()

    private let baseDir = AppGroup.fileCacheDir
    private let fm = FileManager.default

    func cachedURL(serverID: String) -> URL? {
        let url = baseDir.appendingPathComponent(serverID)
        return fm.fileExists(atPath: url.path) ? url : nil
    }

    func store(_ data: Data, serverID: String) throws -> URL {
        let url = baseDir.appendingPathComponent(serverID)
        try data.write(to: url, options: .atomic)
        touch(url: url)
        return url
    }

    func storeFile(at source: URL, serverID: String) throws -> URL {
        let dst = baseDir.appendingPathComponent(serverID)
        if fm.fileExists(atPath: dst.path) {
            try fm.removeItem(at: dst)
        }
        try fm.copyItem(at: source, to: dst)
        touch(url: dst)
        return dst
    }

    func delete(serverID: String) {
        let url = baseDir.appendingPathComponent(serverID)
        try? fm.removeItem(at: url)
    }

    func currentSize() -> Int64 {
        let keys: Set<URLResourceKey> = [.fileSizeKey]
        guard let it = fm.enumerator(at: baseDir, includingPropertiesForKeys: Array(keys)) else { return 0 }
        var total: Int64 = 0
        for case let f as URL in it {
            let s = (try? f.resourceValues(forKeys: keys))?.fileSize ?? 0
            total += Int64(s)
        }
        return total
    }

    func evictDownTo(limitBytes: Int64) {
        var current = currentSize()
        if current <= limitBytes { return }

        let keys: Set<URLResourceKey> = [.contentAccessDateKey, .fileSizeKey]
        guard let it = fm.enumerator(at: baseDir, includingPropertiesForKeys: Array(keys)) else { return }
        var files: [(URL, Date, Int64)] = []
        for case let f as URL in it {
            let v = try? f.resourceValues(forKeys: keys)
            files.append((f, v?.contentAccessDate ?? .distantPast, Int64(v?.fileSize ?? 0)))
        }
        files.sort { $0.1 < $1.1 }

        for (url, _, size) in files {
            if current <= limitBytes { break }
            try? fm.removeItem(at: url)
            current -= size
        }
    }

    func clear() {
        try? fm.removeItem(at: baseDir)
        try? fm.createDirectory(at: baseDir, withIntermediateDirectories: true)
    }

    private func touch(url: URL) {
        var values = URLResourceValues()
        values.contentAccessDate = Date()
        var mutable = url
        try? mutable.setResourceValues(values)
    }
}
