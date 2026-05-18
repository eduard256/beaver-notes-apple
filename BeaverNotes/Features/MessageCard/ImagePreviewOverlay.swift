import SwiftUI

struct ImagePreviewOverlay: View {
    let files: [LocalFile]
    @State var startIndex: Int
    let server: Server?
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            TabView(selection: $startIndex) {
                ForEach(Array(files.enumerated()), id: \.offset) { i, f in
                    ImageLoaderView(file: f, server: server)
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(MagnificationGesture().onChanged { scale = max(1, $0) })
                        .gesture(DragGesture().onChanged { offset = $0.translation }.onEnded { _ in
                            withAnimation { offset = .zero }
                        })
                        .tag(i)
                }
            }
            #if os(iOS)
            .tabViewStyle(.page)
            #endif

            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: Symbols.close)
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding(Space.s3)
                            .background(.black.opacity(0.4), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .padding()
                }
                Spacer()
            }
        }
    }
}
