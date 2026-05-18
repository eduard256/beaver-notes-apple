import SwiftUI

struct ImagePreviewOverlay: View {
    let file: LocalFile
    let server: Server?
    let onClose: () -> Void

    @State private var scale: CGFloat = 1
    @GestureState private var pinch: CGFloat = 1

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CachedImage(file: file, server: server)
                .scaledToFit()
                .scaleEffect(scale * pinch)
                .gesture(
                    MagnificationGesture()
                        .updating($pinch) { v, state, _ in state = v }
                        .onEnded { v in
                            scale = min(max(scale * v, 1), 5)
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation { scale = scale > 1 ? 1 : 2 }
                }
                .onTapGesture { onClose() }

            VStack {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: SF.close)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(Space.s3)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(Space.s4)
        }
    }
}
