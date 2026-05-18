import Foundation
import AVFoundation

enum VideoPreset {
    case p720, p1080

    var avPreset: String {
        switch self {
        case .p720:  return AVAssetExportPreset1280x720
        case .p1080: return AVAssetExportPreset1920x1080
        }
    }
}

enum VideoOptimizer {
    @discardableResult
    static func export(source: URL, to destination: URL, preset: VideoPreset = .p1080, timeRange: CMTimeRange? = nil) async throws -> URL {
        let asset = AVURLAsset(url: source)
        guard let session = AVAssetExportSession(asset: asset, presetName: preset.avPreset) else {
            throw NSError(domain: "VideoOptimizer", code: -1)
        }
        if FileManager.default.fileExists(atPath: destination.path) {
            try? FileManager.default.removeItem(at: destination)
        }
        session.outputURL = destination
        session.outputFileType = .mp4
        session.shouldOptimizeForNetworkUse = true
        if let timeRange { session.timeRange = timeRange }

        await session.export()

        if session.status == .completed {
            return destination
        }
        throw session.error ?? NSError(domain: "VideoOptimizer", code: -2)
    }

    static func estimatedSize(source: URL, preset: VideoPreset) async -> Int64? {
        let asset = AVURLAsset(url: source)
        guard let session = AVAssetExportSession(asset: asset, presetName: preset.avPreset) else { return nil }
        let length = (try? await session.estimatedOutputFileLengthInBytes) ?? 0
        return length > 0 ? length : nil
    }
}
