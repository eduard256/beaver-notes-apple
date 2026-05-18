import Foundation
import CoreGraphics
import CoreImage
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if canImport(PencilKit)
import PencilKit
#endif

enum ImageProcessor {
    // Applies crop + rotation + optional drawing overlay + optional filter to an image.
    // Returns the resulting CGImage; callers can wrap into PlatformImage.
    static func apply(original: CGImage, crop: CGRect?, rotation: Angle = .zero, filter: CIFilter? = nil, drawingPNG: Data? = nil) -> CGImage? {
        var image = original

        if rotation.degrees != 0 {
            image = rotated(image, angle: rotation) ?? image
        }
        if let crop = crop?.integral, crop.size.width > 0, crop.size.height > 0,
           let cropped = image.cropping(to: crop) {
            image = cropped
        }
        if let filter {
            image = applyFilter(filter, to: image) ?? image
        }
        if let drawing = drawingPNG {
            image = composite(base: image, overlayPNG: drawing) ?? image
        }
        return image
    }

    private static func rotated(_ image: CGImage, angle: Angle) -> CGImage? {
        let radians = CGFloat(angle.radians)
        let w = CGFloat(image.width)
        let h = CGFloat(image.height)
        let rotatedSize = CGRect(x: 0, y: 0, width: w, height: h)
            .applying(CGAffineTransform(rotationAngle: radians)).integral.size

        guard let ctx = CGContext(
            data: nil,
            width: Int(rotatedSize.width),
            height: Int(rotatedSize.height),
            bitsPerComponent: image.bitsPerComponent,
            bytesPerRow: 0,
            space: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: image.bitmapInfo.rawValue
        ) else { return nil }

        ctx.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        ctx.rotate(by: radians)
        ctx.draw(image, in: CGRect(x: -w / 2, y: -h / 2, width: w, height: h))
        return ctx.makeImage()
    }

    private static func applyFilter(_ filter: CIFilter, to image: CGImage) -> CGImage? {
        let ci = CIImage(cgImage: image)
        filter.setValue(ci, forKey: kCIInputImageKey)
        guard let out = filter.outputImage else { return nil }
        let ctx = CIContext()
        return ctx.createCGImage(out, from: out.extent)
    }

    private static func composite(base: CGImage, overlayPNG: Data) -> CGImage? {
        #if canImport(UIKit)
        guard let baseImg = UIImage(cgImage: base, scale: 1, orientation: .up).cgImage,
              let overlay = UIImage(data: overlayPNG)?.cgImage else { return base }
        let size = CGSize(width: baseImg.width, height: baseImg.height)
        let cs = baseImg.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return base }
        ctx.draw(baseImg, in: CGRect(origin: .zero, size: size))
        ctx.draw(overlay, in: CGRect(origin: .zero, size: size))
        return ctx.makeImage()
        #else
        return base
        #endif
    }
}

enum ImageFilters {
    static let presets: [(name: String, key: String?)] = [
        ("Original", nil),
        ("Mono",     "CIPhotoEffectMono"),
        ("Noir",     "CIPhotoEffectNoir"),
        ("Tonal",    "CIPhotoEffectTonal"),
        ("Process",  "CIPhotoEffectProcess"),
        ("Sepia",    "CISepiaTone"),
    ]

    static func filter(named key: String) -> CIFilter? {
        let f = CIFilter(name: key)
        if key == "CISepiaTone" { f?.setValue(0.7, forKey: kCIInputIntensityKey) }
        return f
    }
}
