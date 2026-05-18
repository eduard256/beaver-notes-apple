import Foundation
import ImageIO
import UniformTypeIdentifiers
import CoreGraphics

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

// Re-encodes images via ImageIO to HEIC (preferred) or JPEG with downscaling.
enum ImageOptimizer {
    struct Result {
        let data: Data
        let mime: String
        let pixelSize: CGSize
    }

    static let defaultMaxDimension: CGFloat = 2560
    static let defaultQuality: CGFloat = 0.6

    static func optimize(fileURL: URL, maxDimension: CGFloat = defaultMaxDimension, quality: CGFloat = defaultQuality) -> Result? {
        guard let src = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else { return nil }
        return encode(source: src, maxDimension: maxDimension, quality: quality)
    }

    static func optimize(data: Data, maxDimension: CGFloat = defaultMaxDimension, quality: CGFloat = defaultQuality) -> Result? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return encode(source: src, maxDimension: maxDimension, quality: quality)
    }

    private static func encode(source: CGImageSource, maxDimension: CGFloat, quality: CGFloat) -> Result? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }

        let preferHEIC = (CGImageDestinationCopyTypeIdentifiers() as? [String])?.contains(UTType.heic.identifier) ?? false
        let utType: UTType = preferHEIC ? .heic : .jpeg
        let mime = preferHEIC ? "image/heic" : "image/jpeg"

        let outData = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(outData, utType.identifier as CFString, 1, nil) else { return nil }
        let props: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: quality]
        CGImageDestinationAddImage(dest, cgImage, props as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return nil }

        let size = CGSize(width: cgImage.width, height: cgImage.height)
        return Result(data: outData as Data, mime: mime, pixelSize: size)
    }
}
