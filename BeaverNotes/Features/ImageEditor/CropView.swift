import SwiftUI

struct CropView: View {
    @Binding var crop: CGRect?
    let imageSize: CGSize

    var body: some View {
        GeometryReader { geo in
            let rect = crop ?? CGRect(x: 0, y: 0, width: geo.size.width, height: geo.size.height)
            ZStack {
                Color.black.opacity(0.4)
                Rectangle()
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
                    .blendMode(.destinationOut)
                Rectangle()
                    .stroke(Color.white, lineWidth: 1)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            }
            .compositingGroup()
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let origin = value.startLocation
                        let dx = value.location.x - origin.x
                        let dy = value.location.y - origin.y
                        let new = CGRect(
                            x: min(origin.x, origin.x + dx),
                            y: min(origin.y, origin.y + dy),
                            width: abs(dx),
                            height: abs(dy)
                        )
                        crop = scaleRect(new, viewSize: geo.size, imageSize: imageSize)
                    }
            )
        }
    }

    private func scaleRect(_ r: CGRect, viewSize: CGSize, imageSize: CGSize) -> CGRect {
        let scaleX = imageSize.width / viewSize.width
        let scaleY = imageSize.height / viewSize.height
        return CGRect(x: r.origin.x * scaleX, y: r.origin.y * scaleY, width: r.size.width * scaleX, height: r.size.height * scaleY)
    }
}
