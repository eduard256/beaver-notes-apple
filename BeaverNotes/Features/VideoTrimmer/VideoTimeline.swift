import SwiftUI

struct VideoTimeline: View {
    let duration: Double
    @Binding var start: Double
    @Binding var end: Double

    var body: some View {
        VStack(spacing: Space.s2) {
            GeometryReader { geo in
                let w = geo.size.width
                let startX = duration > 0 ? CGFloat(start / duration) * w : 0
                let endX = duration > 0 ? CGFloat(end / duration) * w : w

                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.bgSecondary).frame(height: 36)
                    Capsule().fill(Palette.accent.opacity(0.25))
                        .frame(width: max(0, endX - startX), height: 36)
                        .offset(x: startX)

                    handle.offset(x: startX - 6).gesture(drag(isStart: true, in: w))
                    handle.offset(x: endX - 6).gesture(drag(isStart: false, in: w))
                }
            }
            .frame(height: 36)

            HStack {
                Text(timeString(start)).font(.caption.monospacedDigit())
                Spacer()
                Text(timeString(end - start)).font(.caption.monospacedDigit().weight(.medium))
                Spacer()
                Text(timeString(end)).font(.caption.monospacedDigit())
            }
            .foregroundStyle(Palette.textSecondary)
        }
    }

    private var handle: some View {
        Rectangle()
            .fill(Palette.accent)
            .frame(width: 12, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func drag(isStart: Bool, in width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0).onChanged { value in
            guard width > 0, duration > 0 else { return }
            let pos = max(0, min(width, value.location.x))
            let v = Double(pos / width) * duration
            if isStart { start = min(v, end - 0.5) }
            else       { end = max(v, start + 0.5) }
        }
    }

    private func timeString(_ s: Double) -> String {
        let t = max(0, s)
        let m = Int(t) / 60
        let sec = Int(t) % 60
        return String(format: "%d:%02d", m, sec)
    }
}
