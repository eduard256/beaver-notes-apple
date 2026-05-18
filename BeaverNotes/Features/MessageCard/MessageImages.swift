import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct PreviewIndex: Identifiable, Equatable { let id: Int }

struct MessageImages: View {
    let message: Message
    @State private var previewIndex: PreviewIndex?

    private var images: [LocalFile] { message.files.filter { $0.isImage } }

    var body: some View {
        if !images.isEmpty {
            content
                .fullScreenCoverCompat(item: $previewIndex) { idx in
                    ImagePreviewOverlay(files: images, startIndex: idx.id, server: message.server)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch images.count {
        case 1:
            thumbnail(images[0], index: 0)
                .frame(maxWidth: 420)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        case 2...4:
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Space.s2) {
                ForEach(Array(images.enumerated()), id: \.offset) { i, f in
                    thumbnail(f, index: i)
                        .aspectRatio(1, contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                }
            }
        default:
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: Space.s2) {
                ForEach(Array(images.prefix(9).enumerated()), id: \.offset) { i, f in
                    ZStack {
                        thumbnail(f, index: i)
                            .aspectRatio(1, contentMode: .fill)
                        if i == 8 && images.count > 9 {
                            Color.black.opacity(0.5)
                            Text("+\(images.count - 9)")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                }
            }
        }
    }

    private func thumbnail(_ file: LocalFile, index: Int) -> some View {
        ImageLoaderView(file: file, server: message.server)
            .contentShape(Rectangle())
            .onTapGesture { previewIndex = PreviewIndex(id: index) }
    }
}

struct ImageLoaderView: View {
    let file: LocalFile
    let server: Server?
    @State private var url: URL?
    @State private var loading = false

    var body: some View {
        ZStack {
            Palette.bgTertiary
            if let url, let img = loadImage(url) {
                img.resizable().scaledToFill()
            } else if loading {
                ProgressView()
            } else {
                Image(systemName: Symbols.image).foregroundStyle(Palette.textTertiary)
            }
        }
        .task { await load() }
    }

    private func loadImage(_ url: URL) -> Image? {
        #if canImport(UIKit)
        if let img = UIImage(contentsOfFile: url.path) { return Image(uiImage: img) }
        #elseif canImport(AppKit)
        if let img = NSImage(contentsOfFile: url.path) { return Image(nsImage: img) }
        #endif
        return nil
    }

    private func load() async {
        if let local = file.localPath {
            url = URL(fileURLWithPath: local)
            return
        }
        if let source = file.sourcePath {
            url = URL(fileURLWithPath: source)
            return
        }
        guard let sid = file.serverID, let server, let serverURL = server.url else { return }
        if let cached = await FileCache.shared.cachedURL(serverID: sid) {
            url = cached
            return
        }
        loading = true
        defer { loading = false }
        let client = APIClient(serverURL: serverURL, cookieIdentifier: server.cookieStorageIdentifier)
        let dst = AppGroup.fileCacheDir.appendingPathComponent(sid)
        do {
            try await client.downloadFile(serverID: sid, to: dst)
            url = dst
        } catch {}
    }
}

extension View {
    @ViewBuilder
    func fullScreenCoverCompat<Item: Identifiable, Content: View>(item: Binding<Item?>, @ViewBuilder content: @escaping (Item) -> Content) -> some View {
        #if os(iOS)
        self.fullScreenCover(item: item, content: content)
        #else
        self.sheet(item: item, content: content)
        #endif
    }
}

