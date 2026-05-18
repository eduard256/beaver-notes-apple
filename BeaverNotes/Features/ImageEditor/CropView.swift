import SwiftUI

struct CropView: View {
    @Binding var cropRect: CGRect
    let imageSize: CGSize

    var body: some View {
        GeometryReader { geo in
            let frame = cropRect
            ZStack(alignment: .topLeading) {
                // Dim overlay outside crop area
                Color.black.opacity(0.45)
                    .mask {
                        Rectangle()
                            .overlay(
                                Rectangle()
                                    .frame(width: frame.width, height: frame.height)
                                    .offset(x: frame.minX, y: frame.minY)
                                    .blendMode(.destinationOut)
                            )
                            .compositingGroup()
                    }

                // Crop frame with handles
                Rectangle()
                    .stroke(Palette.bgPrimary, lineWidth: 1)
                    .frame(width: frame.width, height: frame.height)
                    .offset(x: frame.minX, y: frame.minY)

                handle(at: .init(x: frame.minX, y: frame.minY)) { d in
                    var r = cropRect
                    r.origin.x += d.x; r.size.width -= d.x
                    r.origin.y += d.y; r.size.height -= d.y
                    cropRect = clamp(r, in: geo.size)
                }
                handle(at: .init(x: frame.maxX, y: frame.minY)) { d in
                    var r = cropRect
                    r.size.width += d.x
                    r.origin.y += d.y; r.size.height -= d.y
                    cropRect = clamp(r, in: geo.size)
                }
                handle(at: .init(x: frame.minX, y: frame.maxY)) { d in
                    var r = cropRect
                    r.origin.x += d.x; r.size.width -= d.x
                    r.size.height += d.y
                    cropRect = clamp(r, in: geo.size)
                }
                handle(at: .init(x: frame.maxX, y: frame.maxY)) { d in
                    var r = cropRect
                    r.size.width += d.x; r.size.height += d.y
                    cropRect = clamp(r, in: geo.size)
                }
            }
        }
        .allowsHitTesting(true)
    }

    private func handle(at point: CGPoint, onDrag: @escaping (CGPoint) -> Void) -> some View {
        Circle()
            .fill(Palette.bgPrimary)
            .frame(width: 18, height: 18)
            .position(point)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        onDrag(CGPoint(x: v.translation.width / 30, y: v.translation.height / 30))
                    }
            )
    }

    private func clamp(_ r: CGRect, in size: CGSize) -> CGRect {
        var r = r
        r.origin.x = max(0, r.origin.x)
        r.origin.y = max(0, r.origin.y)
        r.size.width = min(size.width - r.origin.x, max(40, r.size.width))
        r.size.height = min(size.height - r.origin.y, max(40, r.size.height))
        return r
    }
}
