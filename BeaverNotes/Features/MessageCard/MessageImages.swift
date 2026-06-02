import SwiftUI
import SwiftData

// MARK: - Public entry

struct MessageImages: View {
    let files: [LocalFile]
    let server: Server?
    let onTap: (LocalFile) -> Void

    var body: some View {
        ImageGroupGrid(files: files, server: server, onTap: onTap)
    }
}

// MARK: - Telegram-style grid

private struct ImageGroupGrid: View {
    let files: [LocalFile]
    let server: Server?
    let onTap: (LocalFile) -> Void

    private let maxWidth: CGFloat = 360
    private let gutter: CGFloat = 2
    private let radius: CGFloat = Radius.md

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width, maxWidth)
            layout(width: width)
        }
        .frame(maxWidth: maxWidth, alignment: .leading)
        .frame(height: computedHeight)
    }

    private var computedHeight: CGFloat {
        height(forWidth: maxWidth)
    }

    private func height(forWidth width: CGFloat) -> CGFloat {
        switch files.count {
        case 0: return 0
        case 1:
            let ratio = aspect(files[0])
            // single: limit by max-width and a sensible max-height.
            let h = width / ratio
            return min(max(h, 140), 360)
        case 2:
            return width * 0.62
        case 3:
            return width * 0.85
        case 4:
            return width
        case 5, 6:
            return width * 1.05
        default:
            // 3-col grid, last cell with "+N"
            let cols: CGFloat = 3
            let cell = (width - gutter * (cols - 1)) / cols
            let rows = ceil(CGFloat(min(files.count, 9)) / cols)
            return cell * rows + gutter * (rows - 1)
        }
    }

    @ViewBuilder
    private func layout(width: CGFloat) -> some View {
        switch files.count {
        case 1:
            tile(files[0])
                .frame(width: width, height: height(forWidth: width))
                .clipShape(RoundedRectangle(cornerRadius: radius))
        case 2:
            HStack(spacing: gutter) {
                tile(files[0])
                tile(files[1])
            }
            .frame(width: width, height: height(forWidth: width))
            .clipShape(RoundedRectangle(cornerRadius: radius))
        case 3:
            threeLayout(width: width)
                .clipShape(RoundedRectangle(cornerRadius: radius))
        case 4:
            fourLayout(width: width)
                .clipShape(RoundedRectangle(cornerRadius: radius))
        case 5:
            fiveLayout(width: width)
                .clipShape(RoundedRectangle(cornerRadius: radius))
        case 6:
            sixLayout(width: width)
                .clipShape(RoundedRectangle(cornerRadius: radius))
        default:
            manyLayout(width: width)
                .clipShape(RoundedRectangle(cornerRadius: radius))
        }
    }

    // 3: portrait-leading -> one tall left + two stacked right; otherwise top + 2 bottom
    @ViewBuilder
    private func threeLayout(width: CGFloat) -> some View {
        let h = height(forWidth: width)
        if isPortrait(files[0]) {
            HStack(spacing: gutter) {
                tile(files[0])
                    .frame(width: (width - gutter) * 0.62)
                VStack(spacing: gutter) {
                    tile(files[1])
                    tile(files[2])
                }
                .frame(width: (width - gutter) * 0.38)
            }
            .frame(width: width, height: h)
        } else {
            VStack(spacing: gutter) {
                tile(files[0])
                    .frame(height: h * 0.62)
                HStack(spacing: gutter) {
                    tile(files[1])
                    tile(files[2])
                }
                .frame(height: h * 0.38 - gutter)
            }
            .frame(width: width, height: h)
        }
    }

    @ViewBuilder
    private func fourLayout(width: CGFloat) -> some View {
        let h = height(forWidth: width)
        // 2x2
        VStack(spacing: gutter) {
            HStack(spacing: gutter) {
                tile(files[0]); tile(files[1])
            }
            HStack(spacing: gutter) {
                tile(files[2]); tile(files[3])
            }
        }
        .frame(width: width, height: h)
    }

    @ViewBuilder
    private func fiveLayout(width: CGFloat) -> some View {
        let h = height(forWidth: width)
        VStack(spacing: gutter) {
            HStack(spacing: gutter) {
                tile(files[0]); tile(files[1])
            }
            .frame(height: h * 0.55)
            HStack(spacing: gutter) {
                tile(files[2]); tile(files[3]); tile(files[4])
            }
            .frame(height: h * 0.45 - gutter)
        }
        .frame(width: width, height: h)
    }

    @ViewBuilder
    private func sixLayout(width: CGFloat) -> some View {
        let h = height(forWidth: width)
        VStack(spacing: gutter) {
            HStack(spacing: gutter) {
                tile(files[0]); tile(files[1]); tile(files[2])
            }
            HStack(spacing: gutter) {
                tile(files[3]); tile(files[4]); tile(files[5])
            }
        }
        .frame(width: width, height: h)
    }

    @ViewBuilder
    private func manyLayout(width: CGFloat) -> some View {
        let cols: CGFloat = 3
        let cell = (width - gutter * (cols - 1)) / cols
        let visible = Array(files.prefix(9))
        let extra = files.count - visible.count
        let columns = Array(repeating: GridItem(.fixed(cell), spacing: gutter), count: 3)
        LazyVGrid(columns: columns, spacing: gutter) {
            ForEach(Array(visible.enumerated()), id: \.element.localID) { idx, file in
                ZStack {
                    tile(file)
                    if idx == visible.count - 1 && extra > 0 {
                        Color.black.opacity(0.45)
                        Text("+\(extra)")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: cell, height: cell)
                .clipped()
            }
        }
        .frame(width: width)
    }

    private func tile(_ file: LocalFile) -> some View {
        ZStack {
            CachedImage(file: file, server: server, mode: .thumbnail)
            TransferProgressOverlay(file: file, style: .image)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { onTap(file) }
    }

    private func aspect(_ file: LocalFile) -> CGFloat {
        guard let w = file.pixelWidth, let h = file.pixelHeight, w > 0, h > 0 else {
            return 4.0 / 3.0
        }
        return CGFloat(w) / CGFloat(h)
    }

    private func isPortrait(_ file: LocalFile) -> Bool {
        aspect(file) < 0.95
    }
}

// MARK: - CachedImage

enum CachedImageMode {
    case thumbnail
    case full
}

struct CachedImage: View {
    let file: LocalFile
    let server: Server?
    var mode: CachedImageMode = .thumbnail

    @Environment(\.modelContext) private var modelContext
    @State private var image: PlatformImageBridge?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let image {
                #if canImport(UIKit)
                Image(uiImage: image).resizable().scaledToFill()
                #elseif canImport(AppKit)
                Image(nsImage: image).resizable().scaledToFill()
                #endif
            } else if loadFailed {
                placeholder
            } else {
                Palette.bgSecondary
                    .overlay { ProgressView().tint(Palette.textTertiary) }
            }
        }
        .clipped()
        .task(id: reloadKey) {
            await load()
        }
    }

    // Re-runs the loader whenever anything that affects image availability changes:
    // the file finishes uploading (serverID appears), a local copy lands, or the
    // transfer state flips. Without this the view keeps showing the placeholder
    // until the app is relaunched.
    private var reloadKey: String {
        "\(file.localID)|\(file.serverID ?? "")|\(file.localPath ?? "")|\(file.transferStateRaw)"
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
        guard image == nil else { return }
        loadFailed = false
        if let url = await resolveLocalURL() {
            await decode(from: url)
            return
        }
        if let serverID = file.serverID, let server {
            do {
                let url = try await downloadToCache(serverID: serverID, server: server)
                await decode(from: url)
            } catch {
                loadFailed = true
            }
        } else {
            loadFailed = true
        }
    }

    private func resolveLocalURL() async -> URL? {
        if let localPath = file.localPath, FileManager.default.fileExists(atPath: localPath) {
            return URL(fileURLWithPath: localPath)
        }
        if let serverID = file.serverID, let cached = await FileCache.shared.cachedURL(serverID: serverID) {
            return cached
        }
        return nil
    }

    private func downloadToCache(serverID: String, server: Server) async throws -> URL {
        let dst = AppGroup.fileCacheDir.appendingPathComponent(serverID)
        let client = APIClient(serverURL: server.url ?? URL(string: "http://invalid")!,
                               cookieIdentifier: server.cookieStorageIdentifier)
        try await client.downloadFile(serverID: serverID, to: dst)
        return dst
    }

    @MainActor
    private func decode(from url: URL) async {
        let maxPixel: CGFloat = mode == .thumbnail ? 1024 : 4096
        if let size = ImageBytes.pixelSize(at: url) {
            if file.pixelWidth == nil || file.pixelHeight == nil {
                file.pixelWidth = Int(size.width)
                file.pixelHeight = Int(size.height)
                try? modelContext.save()
            }
        }
        let img: PlatformImageBridge? = mode == .thumbnail
            ? ImageBytes.thumbnail(at: url, maxPixel: maxPixel)
            : ImageBytes.full(at: url)
        if let img {
            self.image = img
        } else {
            loadFailed = true
        }
    }
}
