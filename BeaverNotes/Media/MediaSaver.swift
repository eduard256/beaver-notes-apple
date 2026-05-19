import Foundation
import Photos

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum SaveDestination {
    case photos
    case files
}

enum MediaSaveError: Error {
    case noPermission
    case ioFailure
    case cancelled
}

enum MediaSaver {

    // MARK: - Photos (iOS / macOS Photos)

    static func saveToPhotos(fileURL: URL, suggestedName: String? = nil) async throws {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        let granted: Bool
        switch status {
        case .authorized, .limited:
            granted = true
        case .notDetermined:
            let s = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            granted = (s == .authorized || s == .limited)
        default:
            granted = false
        }
        guard granted else { throw MediaSaveError.noPermission }

        let ext = (suggestedName.flatMap { (URL(fileURLWithPath: $0).pathExtension.isEmpty ? nil : URL(fileURLWithPath: $0).pathExtension) })
            ?? fileExtensionByProbing(url: fileURL)
            ?? "jpg"

        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("save-\(UUID().uuidString).\(ext)")
        if FileManager.default.fileExists(atPath: tmp.path) {
            try? FileManager.default.removeItem(at: tmp)
        }
        try FileManager.default.copyItem(at: fileURL, to: tmp)
        defer { try? FileManager.default.removeItem(at: tmp) }

        try await PHPhotoLibrary.shared().performChanges {
            let req = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            options.originalFilename = suggestedName ?? tmp.lastPathComponent
            options.shouldMoveFile = false
            req.addResource(with: .photo, fileURL: tmp, options: options)
        }
    }

    private static func fileExtensionByProbing(url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        guard let head = try? handle.read(upToCount: 16) else { return nil }
        let bytes = [UInt8](head)
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) { return "jpg" }
        if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return "png" }
        if bytes.starts(with: [0x47, 0x49, 0x46]) { return "gif" }
        if bytes.count >= 12,
           bytes[0] == 0x52, bytes[1] == 0x49, bytes[2] == 0x46, bytes[3] == 0x46,
           bytes[8] == 0x57, bytes[9] == 0x45, bytes[10] == 0x42, bytes[11] == 0x50 {
            return "webp"
        }
        if bytes.count >= 12,
           bytes[4] == 0x66, bytes[5] == 0x74, bytes[6] == 0x79, bytes[7] == 0x70 {
            // ftyp box → likely heic/heif
            return "heic"
        }
        return nil
    }

    // MARK: - Files

#if canImport(UIKit)
    @MainActor
    static func exportToFiles(fileURL: URL, suggestedName: String, from presenter: UIViewController) async throws -> URL? {
        // Copy to tmp with desired name first
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(suggestedName)
        if FileManager.default.fileExists(atPath: tmp.path) {
            try? FileManager.default.removeItem(at: tmp)
        }
        try FileManager.default.copyItem(at: fileURL, to: tmp)

        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL?, Error>) in
            let picker = UIDocumentPickerViewController(forExporting: [tmp], asCopy: true)
            let delegate = DocumentPickerDelegate { url in
                cont.resume(returning: url)
            } onCancel: {
                cont.resume(throwing: MediaSaveError.cancelled)
            }
            picker.delegate = delegate
            objc_setAssociatedObject(picker, &DocumentPickerDelegate.assocKey, delegate, .OBJC_ASSOCIATION_RETAIN)
            presenter.present(picker, animated: true)
        }
    }
#endif

#if canImport(AppKit)
    static func saveToDownloads(fileURL: URL, suggestedName: String) throws -> URL {
        let downloads = try FileManager.default.url(
            for: .downloadsDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true
        )
        var target = downloads.appendingPathComponent(suggestedName)
        target = uniqueURL(for: target)
        if FileManager.default.fileExists(atPath: target.path) {
            try FileManager.default.removeItem(at: target)
        }
        try FileManager.default.copyItem(at: fileURL, to: target)
        return target
    }

    static func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private static func uniqueURL(for url: URL) -> URL {
        let fm = FileManager.default
        if !fm.fileExists(atPath: url.path) { return url }
        let dir = url.deletingLastPathComponent()
        let stem = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        var i = 2
        while true {
            let candidate = dir.appendingPathComponent("\(stem) (\(i))").appendingPathExtension(ext)
            if !fm.fileExists(atPath: candidate.path) { return candidate }
            i += 1
        }
    }
#endif
}

#if canImport(UIKit)
final class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
    static var assocKey: UInt8 = 0
    let onPick: (URL?) -> Void
    let onCancel: () -> Void
    init(onPick: @escaping (URL?) -> Void, onCancel: @escaping () -> Void) {
        self.onPick = onPick
        self.onCancel = onCancel
    }
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        onPick(urls.first)
    }
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        onCancel()
    }
}
#endif
