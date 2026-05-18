import SwiftUI

struct MessageImages: View {
    let files: [LocalFile]
    let server: Server?
    let onTap: (LocalFile) -> Void

    var body: some View {
        Group {
            if files.count == 1 {
                single(files[0])
            } else {
                grid
            }
        }
    }

    private func single(_ file: LocalFile) -> some View {
        Button { onTap(file) } label: {
            CachedImage(file: file, server: server)
                .frame(maxWidth: 420)
                .frame(maxHeight: 320)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
        .buttonStyle(.plain)
    }

    private var grid: some View {
        let cols: Int = files.count <= 4 ? 2 : 3
        let layout = Array(repeating: GridItem(.flexible(), spacing: Space.s2), count: cols)
        return LazyVGrid(columns: layout, spacing: Space.s2) {
            ForEach(files, id: \.localID) { f in
                Button { onTap(f) } label: {
                    CachedImage(file: f, server: server)
                        .aspectRatio(1, contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct CachedImage: View {
    let file: LocalFile
    let server: Server?

    @State private var image: PlatformImageBridge?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let image {
                #if canImport(UIKit)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                #elseif canImport(AppKit)
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                #endif
            } else if loadFailed {
                placeholder
            } else {
                Palette.bgSecondary
                    .overlay { ProgressView().tint(Palette.textTertiary) }
            }
        }
        .task {
            await load()
        }
    }

    private var placeholder: some View {
        Palette.bgSecondary
            .overlay {
                VStack(spacing: 4) {
                    Image(systemName: SF.image).foregroundStyle(Palette.textTertiary)
                    Text(file.filename).font(.caption2).foregroundStyle(Palette.textTertiary)
                }
                .padding(4)
            }
    }

    private func load() async {
        guard image == nil, let serverID = file.serverID, let server else { return }
        if let localPath = file.localPath, let img = await loadImage(at: URL(fileURLWithPath: localPath)) {
            image = img
            return
        }
        if let url = await FileCache.shared.cachedURL(serverID: serverID), let img = await loadImage(at: url) {
            image = img
            return
        }
        if file.size <= 2 * 1024 * 1024 {
            let dst = AppGroup.fileCacheDir.appendingPathComponent(serverID)
            do {
                let client = APIClient(serverURL: server.url ?? URL(string: "http://invalid")!, cookieIdentifier: server.cookieStorageIdentifier)
                try await client.downloadFile(serverID: serverID, to: dst)
                if let img = await loadImage(at: dst) {
                    image = img
                    return
                }
            } catch {
                loadFailed = true
            }
        } else {
            loadFailed = true
        }
    }

    private func loadImage(at url: URL) async -> PlatformImageBridge? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        #if canImport(UIKit)
        return UIImage(data: data)
        #elseif canImport(AppKit)
        return NSImage(data: data)
        #else
        return nil
        #endif
    }
}

#if canImport(UIKit)
import UIKit
typealias PlatformImageBridge = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImageBridge = NSImage
#endif
