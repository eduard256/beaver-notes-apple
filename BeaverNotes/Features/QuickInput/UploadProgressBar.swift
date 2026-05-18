import SwiftUI

struct UploadProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Palette.borderSecondary)
                Rectangle().fill(Palette.accent).frame(width: geo.size.width * progress)
            }
        }
        .frame(height: 2)
    }
}
