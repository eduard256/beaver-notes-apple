import Foundation
import AVFoundation

enum VideoTrimmer {
    @discardableResult
    static func trim(source: URL, start: CMTime, end: CMTime, to destination: URL) async throws -> URL {
        let range = CMTimeRange(start: start, end: end)
        return try await VideoOptimizer.export(source: source, to: destination, preset: .p1080, timeRange: range)
    }
}
