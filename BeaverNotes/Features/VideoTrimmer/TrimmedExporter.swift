import Foundation
import AVFoundation

enum TrimmedExporter {
    static func export(source: URL, start: CMTime, end: CMTime, optimize: Bool) async throws -> URL {
        let trimmed = AppGroup.outboxFilesDir.appendingPathComponent("trim-\(UUID().uuidString).mp4")
        try await VideoTrimmer.trim(source: source, start: start, end: end, to: trimmed)
        if optimize {
            let final = AppGroup.outboxFilesDir.appendingPathComponent("opt-\(UUID().uuidString).mp4")
            try await VideoOptimizer.export(source: trimmed, to: final, preset: .p1080)
            try? FileManager.default.removeItem(at: trimmed)
            return final
        }
        return trimmed
    }
}
