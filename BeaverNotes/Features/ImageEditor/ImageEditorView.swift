import SwiftUI

#if canImport(PencilKit) && canImport(UIKit)
import PencilKit
#endif

struct ImageEditorView: View {
    let original: PlatformImageBridge
    let originalBytes: Int64
    let onDone: (Data, String) -> Void   // (data, mime)
    let onCancel: () -> Void

    @State private var mode: EditorMode = .crop
    @State private var cropRect: CGRect = .zero
    @State private var rotation: Angle = .zero
    @State private var filterKey: String?
    #if canImport(PencilKit) && canImport(UIKit)
    @State private var drawing: PKDrawing = .init()
    #else
    @State private var drawing: Data = .init()
    #endif
    @State private var optimize: Bool = true
    @State private var estimatedBytes: Int64?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                canvas
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)

                if mode == .filters {
                    FiltersStrip(original: original, selectedKey: $filterKey)
                }

                OptimizeToggle(optimize: $optimize, originalBytes: originalBytes, estimatedBytes: estimatedBytes)
                    .padding(.horizontal, Space.s4)
                    .padding(.top, Space.s2)

                EditorToolbarBottom(mode: $mode)
            }
            .navigationTitle("Edit Image")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { finish() }.fontWeight(.semibold)
                }
                #if os(iOS)
                ToolbarItem(placement: .principal) {
                    if mode == .rotate {
                        Button {
                            rotation = rotation + .degrees(90)
                        } label: {
                            Image(systemName: SF.rotate)
                        }
                    }
                }
                #endif
            }
            .task { await refreshEstimate() }
            .onChange(of: optimize) { _, _ in Task { await refreshEstimate() } }
        }
    }

    private var canvas: some View {
        ZStack {
            #if canImport(UIKit)
            Image(uiImage: original)
                .resizable()
                .scaledToFit()
                .rotationEffect(rotation)
            #elseif canImport(AppKit)
            Image(nsImage: original)
                .resizable()
                .scaledToFit()
                .rotationEffect(rotation)
            #endif

            if mode == .crop {
                CropView(cropRect: $cropRect, imageSize: original.size)
                    .onAppear {
                        if cropRect == .zero {
                            cropRect = CGRect(origin: .zero, size: original.size)
                        }
                    }
            }
            if mode == .draw {
                DrawingCanvas(drawing: $drawing)
            }
        }
    }

    private func refreshEstimate() async {
        guard optimize else { estimatedBytes = nil; return }
        #if canImport(UIKit)
        guard let data = original.pngData() else { return }
        if let res = ImageOptimizer.optimize(data: data) {
            estimatedBytes = Int64(res.data.count)
        }
        #elseif canImport(AppKit)
        guard let tiff = original.tiffRepresentation else { return }
        if let res = ImageOptimizer.optimize(data: tiff) {
            estimatedBytes = Int64(res.data.count)
        }
        #endif
    }

    private func finish() {
        #if canImport(UIKit)
        guard let data = original.pngData() else { return }
        #elseif canImport(AppKit)
        guard let data = original.tiffRepresentation else { return }
        #else
        let data = Data()
        #endif
        if optimize, let res = ImageOptimizer.optimize(data: data) {
            onDone(res.data, res.mime)
        } else {
            onDone(data, "image/png")
        }
    }
}

#if canImport(UIKit)
import UIKit
extension UIImage {
    var size: CGSize { CGSize(width: cgImage?.width ?? 0, height: cgImage?.height ?? 0) }
}
#elseif canImport(AppKit)
import AppKit
#endif
