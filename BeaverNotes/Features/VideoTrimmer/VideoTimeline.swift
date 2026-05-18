import SwiftUI
import AVFoundation

struct VideoTimeline: View {
    let duration: Double
    @Binding var startSeconds: Double
    @Binding var endSeconds: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let startX = w * (startSeconds / duration)
            let endX   = w * (endSeconds / duration)
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.bgSecondary)
                Capsule()
                    .fill(Palette.accent.opacity(0.3))
                    .frame(width: max(0, endX - startX))
                    .offset(x: startX)

                handle(at: startX)
                    .gesture(drag(width: w, isStart: true))
                handle(at: endX)
                    .gesture(drag(width: w, isStart: false))
            }
        }
        .frame(height: 36)
    }

    private func handle(at x: CGFloat) -> some View {
        Capsule()
            .fill(Palette.accent)
            .frame(width: 6, height: 36)
            .offset(x: x - 3)
    }

    private func drag(width: CGFloat, isStart: Bool) -> some Gesture {
        DragGesture()
            .onChanged { v in
                let pct = max(0, min(1, v.location.x / width))
                let t = pct * duration
                if isStart {
                    startSeconds = min(t, endSeconds - 0.5)
                } else {
                    endSeconds = max(t, startSeconds + 0.5)
                }
            }
    }
}
