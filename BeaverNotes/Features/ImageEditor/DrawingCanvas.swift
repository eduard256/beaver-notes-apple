import SwiftUI

#if canImport(PencilKit) && canImport(UIKit)
import PencilKit
import UIKit

struct DrawingCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing

    func makeUIView(context: Context) -> PKCanvasView {
        let v = PKCanvasView()
        v.drawingPolicy = .anyInput
        v.backgroundColor = .clear
        v.isOpaque = false
        v.drawing = drawing
        v.delegate = context.coordinator
        return v
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != drawing { uiView.drawing = drawing }
    }

    func makeCoordinator() -> Coord { Coord(self) }

    @MainActor
    final class Coord: NSObject, PKCanvasViewDelegate {
        var parent: DrawingCanvas
        init(_ p: DrawingCanvas) { parent = p }
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
        }
    }
}

#else

struct DrawingCanvas: View {
    @Binding var drawing: Data

    var body: some View {
        VStack(spacing: Space.s3) {
            Image(systemName: SF.draw)
                .font(.system(size: 40))
                .foregroundStyle(Palette.textTertiary)
            Text("Drawing requires iOS or iPadOS")
                .font(.callout)
                .foregroundStyle(Palette.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#endif
