import SwiftUI
import CoreImage

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct ImageEditorView: View {
    let sourceURL: URL
    let onDone: (URL, Int64) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var mode: EditorMode = .crop
    @State private var crop: CGRect?
    @State private var rotation: Angle = .zero
    @State private var selectedFilter: String?
    @State private var drawingPNG: Data?
    @State private var optimize = PreferencesStore.shared.defaultOptimize
    @State private var working = false

    private var originalCG: CGImage? {
        loadCGImage(sourceURL)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                preview
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Palette.bgSecondary)

                if mode == .filters {
                    FiltersStrip(sourceURL: sourceURL, selected: $selectedFilter)
                }

                OptimizeToggle(enabled: $optimize, sourceURL: sourceURL)

                EditorToolbarBottom(mode: $mode, onReset: reset)
            }
            .background(Palette.bgPrimary)
            .navigationTitle("Edit image")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(working ? "Working…" : "Done") { Task { await finish() } }
                        .disabled(working)
                }
            }
        }
    }

    @ViewBuilder
    private var preview: some View {
        ZStack {
            if let cg = processedPreview {
                #if canImport(UIKit)
                Image(uiImage: UIImage(cgImage: cg)).resizable().scaledToFit()
                #elseif canImport(AppKit)
                Image(nsImage: NSImage(cgImage: cg, size: .zero)).resizable().scaledToFit()
                #endif
            }
            if mode == .draw {
                DrawingCanvas(drawingPNG: $drawingPNG)
            }
        }
    }

    private var processedPreview: CGImage? {
        guard let original = originalCG else { return nil }
        let filter = selectedFilter.flatMap { ImageFilters.filter(named: $0) }
        return ImageProcessor.apply(original: original, crop: crop, rotation: rotation, filter: filter, drawingPNG: drawingPNG)
    }

    private func reset() {
        crop = nil
        rotation = .zero
        selectedFilter = nil
        drawingPNG = nil
    }

    private func finish() async {
        working = true
        defer { working = false }
        guard let original = originalCG else { dismiss(); return }
        let filter = selectedFilter.flatMap { ImageFilters.filter(named: $0) }
        guard let final = ImageProcessor.apply(original: original, crop: crop, rotation: rotation, filter: filter, drawingPNG: drawingPNG) else {
            dismiss(); return
        }

        let data: Data
        let ext: String
        if optimize, let result = optimizeCGImage(final) {
            data = result.data
            ext = result.mime == "image/heic" ? "heic" : "jpg"
        } else if let raw = pngData(final) {
            data = raw
            ext = "png"
        } else {
            dismiss(); return
        }

        let dst = AppGroup.outboxFilesDir.appendingPathComponent("\(UUID().uuidString).\(ext)")
        do {
            try data.write(to: dst)
            onDone(dst, Int64(data.count))
            dismiss()
        } catch {
            dismiss()
        }
    }

    private func loadCGImage(_ url: URL) -> CGImage? {
        #if canImport(UIKit)
        return UIImage(contentsOfFile: url.path)?.cgImage
        #elseif canImport(AppKit)
        return NSImage(contentsOfFile: url.path)?.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #else
        return nil
        #endif
    }

    private func optimizeCGImage(_ cg: CGImage) -> ImageOptimizer.Result? {
        guard let data = pngData(cg) else { return nil }
        return ImageOptimizer.optimize(data: data)
    }

    private func pngData(_ cg: CGImage) -> Data? {
        #if canImport(UIKit)
        return UIImage(cgImage: cg).pngData()
        #elseif canImport(AppKit)
        let rep = NSBitmapImageRep(cgImage: cg)
        return rep.representation(using: .png, properties: [:])
        #else
        return nil
        #endif
    }
}

enum EditorMode: String, CaseIterable, Identifiable {
    case crop, rotate, filters, draw
    var id: String { rawValue }
}
