import SwiftUI

#if canImport(PencilKit) && os(iOS)
import PencilKit

struct DrawingCanvas: UIViewRepresentable {
    @Binding var drawingPNG: Data?

    func makeUIView(context: Context) -> PKCanvasView {
        let v = PKCanvasView()
        v.backgroundColor = .clear
        v.isOpaque = false
        v.drawingPolicy = .anyInput
        v.delegate = context.coordinator
        return v
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}

    func makeCoordinator() -> Coord { Coord(self) }

    final class Coord: NSObject, PKCanvasViewDelegate {
        var parent: DrawingCanvas
        init(_ p: DrawingCanvas) { parent = p }
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let img = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
            parent.drawingPNG = img.pngData()
        }
    }
}

#else

struct DrawingCanvas: View {
    @Binding var drawingPNG: Data?

    var body: some View {
        ZStack {
            Color.clear
            VStack {
                Image(systemName: Symbols.draw)
                    .font(.largeTitle)
                    .foregroundStyle(Palette.textTertiary)
                Text("Drawing requires iOS or iPadOS")
                    .font(.callout)
                    .foregroundStyle(Palette.textSecondary)
            }
            .padding()
            .background(Palette.bgCard.opacity(0.9), in: RoundedRectangle(cornerRadius: Radius.md))
        }
    }
}

#endif
