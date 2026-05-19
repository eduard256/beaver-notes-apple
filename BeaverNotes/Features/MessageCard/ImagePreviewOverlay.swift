import SwiftUI
import Photos

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct ImageViewerView: View {
    let files: [LocalFile]
    let server: Server?
    @Binding var index: Int
    let onClose: () -> Void

    @State private var showChrome: Bool = true
    @State private var dragOffset: CGSize = .zero
    @State private var dismissProgress: CGFloat = 0
    @State private var showShare = false
    @State private var shareItems: [Any] = []
    @State private var toast: ToastMessage?
    @State private var savingAll = false
    @State private var savingProgress: (done: Int, total: Int) = (0, 0)

    var body: some View {
        ZStack {
            Color.black
                .opacity(Double(1 - dismissProgress * 0.7))
                .ignoresSafeArea()

            TabView(selection: $index) {
                ForEach(Array(files.enumerated()), id: \.element.localID) { idx, file in
                    ZoomablePage(file: file, server: server,
                                 onTap: { withAnimation(.easeInOut(duration: 0.15)) { showChrome.toggle() } },
                                 onDismissDrag: { offset in dragOffset = offset; updateDismissProgress() },
                                 onDismissEnded: handleDismissEnded)
                        .tag(idx)
                }
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
            .offset(dragOffset)
            .ignoresSafeArea()

            if showChrome { chrome }

            if let toast {
                VStack {
                    Spacer()
                    ToastView(message: toast)
                        .padding(.bottom, 80)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        #if os(iOS)
        .statusBarHidden(!showChrome)
        #endif
        #if canImport(UIKit)
        .sheet(isPresented: $showShare) {
            ShareSheet(items: shareItems)
        }
        #endif
    }

    // MARK: - Chrome

    @ViewBuilder
    private var chrome: some View {
        VStack {
            HStack(spacing: Space.s3) {
                roundButton(SF.close, action: onClose)
                Spacer()
                if files.count > 1 {
                    Text("\(index + 1) / \(files.count)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                Spacer()
                roundButton("square.and.arrow.up") { Task { await share() } }
                roundButton(SF.download) { Task { await saveCurrentToPhotos() } }
            }
            .padding(.horizontal, Space.s4)
            .padding(.top, Space.s2)

            Spacer()

            if files.count > 1 {
                HStack(spacing: Space.s2) {
                    actionPill(title: "Files", system: "folder") {
                        Task { await saveCurrentToFiles() }
                    }
                    actionPill(title: savingAll ? "\(savingProgress.done)/\(savingProgress.total)" : "Save All",
                               system: "square.and.arrow.down.on.square") {
                        Task { await saveAll() }
                    }
                    .disabled(savingAll)
                }
                .padding(.bottom, Space.s4)
            } else {
                actionPill(title: "Save to Files", system: "folder") {
                    Task { await saveCurrentToFiles() }
                }
                .padding(.bottom, Space.s4)
            }
        }
        .transition(.opacity)
    }

    private func roundButton(_ system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func actionPill(title: String, system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: system)
                Text(title).font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Dismiss drag

    private func updateDismissProgress() {
        let dy = max(0, dragOffset.height)
        dismissProgress = min(1, dy / 300)
    }

    private func handleDismissEnded() {
        let dy = dragOffset.height
        if abs(dy) > 140 {
            onClose()
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                dragOffset = .zero
                dismissProgress = 0
            }
        }
    }

    // MARK: - Actions

    private var currentFile: LocalFile? {
        guard files.indices.contains(index) else { return nil }
        return files[index]
    }

    private func resolveURL(for file: LocalFile) async -> URL? {
        if let p = file.localPath, FileManager.default.fileExists(atPath: p) {
            return URL(fileURLWithPath: p)
        }
        if let serverID = file.serverID, let cached = await FileCache.shared.cachedURL(serverID: serverID) {
            return cached
        }
        guard let serverID = file.serverID, let server else { return nil }
        let dst = AppGroup.fileCacheDir.appendingPathComponent(serverID)
        let client = APIClient(serverURL: server.url ?? URL(string: "http://invalid")!,
                               cookieIdentifier: server.cookieStorageIdentifier)
        do {
            try await client.downloadFile(serverID: serverID, to: dst)
            return dst
        } catch {
            return nil
        }
    }

    private func saveCurrentToPhotos() async {
        guard let file = currentFile else { return }
        guard let url = await resolveURL(for: file) else {
            await showToast(.error("Couldn't load image"))
            return
        }
        do {
            try await MediaSaver.saveToPhotos(fileURL: url, suggestedName: file.filename)
            await showToast(.success("Saved to Photos"))
        } catch MediaSaveError.noPermission {
            await showToast(.error("No Photos permission"))
        } catch {
            await showToast(.error("Save failed"))
        }
    }

    private func saveCurrentToFiles() async {
        guard let file = currentFile else { return }
        guard let url = await resolveURL(for: file) else {
            await showToast(.error("Couldn't load image"))
            return
        }
        #if canImport(UIKit)
        guard let presenter = await topViewController() else { return }
        do {
            _ = try await MediaSaver.exportToFiles(fileURL: url, suggestedName: file.filename, from: presenter)
            await showToast(.success("Saved to Files"))
        } catch MediaSaveError.cancelled {
            // silent
        } catch {
            await showToast(.error("Save failed"))
        }
        #elseif canImport(AppKit)
        do {
            let saved = try MediaSaver.saveToDownloads(fileURL: url, suggestedName: file.filename)
            await showToast(.successWithAction("Saved to Downloads", actionTitle: "Show") {
                MediaSaver.revealInFinder(saved)
            })
        } catch {
            await showToast(.error("Save failed"))
        }
        #endif
    }

    private func saveAll() async {
        savingAll = true
        defer { savingAll = false }
        savingProgress = (0, files.count)
        var failed = 0
        for file in files {
            if let url = await resolveURL(for: file) {
                do {
                    try await MediaSaver.saveToPhotos(fileURL: url, suggestedName: file.filename)
                } catch {
                    failed += 1
                }
            } else {
                failed += 1
            }
            savingProgress.done += 1
        }
        if failed == 0 {
            await showToast(.success("All \(files.count) saved to Photos"))
        } else {
            await showToast(.error("\(failed) of \(files.count) failed"))
        }
    }

    private func share() async {
        guard let file = currentFile else { return }
        guard let url = await resolveURL(for: file) else {
            await showToast(.error("Couldn't load image"))
            return
        }
        #if canImport(UIKit)
        shareItems = [url]
        showShare = true
        #elseif canImport(AppKit)
        MacShare.present(items: [url], from: nil)
        #endif
    }

    @MainActor
    private func showToast(_ msg: ToastMessage) async {
        withAnimation(.easeInOut(duration: 0.2)) { toast = msg }
        try? await Task.sleep(nanoseconds: 1_800_000_000)
        withAnimation(.easeInOut(duration: 0.2)) { toast = nil }
    }
}

// MARK: - Zoomable page

private struct ZoomablePage: View {
    let file: LocalFile
    let server: Server?
    let onTap: () -> Void
    let onDismissDrag: (CGSize) -> Void
    let onDismissEnded: () -> Void

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            CachedImage(file: file, server: server, mode: .full)
                .scaledToFit()
                .frame(width: geo.size.width, height: geo.size.height)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(zoomGesture(in: geo.size))
                .simultaneousGesture(panGesture(in: geo.size))
                .gesture(dismissDragGesture(enabled: scale <= 1.01))
                .onTapGesture(count: 2) { handleDoubleTap() }
                .onTapGesture { onTap() }
        }
        .clipped()
    }

    private func zoomGesture(in size: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { v in
                scale = max(1, min(lastScale * v, 5))
            }
            .onEnded { _ in
                lastScale = scale
                clampOffset(in: size)
            }
    }

    private func panGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { v in
                guard scale > 1.01 else { return }
                offset = CGSize(
                    width: lastOffset.width + v.translation.width,
                    height: lastOffset.height + v.translation.height
                )
            }
            .onEnded { _ in
                guard scale > 1.01 else { return }
                lastOffset = offset
                clampOffset(in: size)
            }
    }

    private func dismissDragGesture(enabled: Bool) -> some Gesture {
        DragGesture()
            .onChanged { v in
                guard enabled else { return }
                onDismissDrag(CGSize(width: v.translation.width * 0.4, height: v.translation.height))
            }
            .onEnded { _ in
                guard enabled else { return }
                onDismissEnded()
            }
    }

    private func handleDoubleTap() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            if scale > 1.01 {
                scale = 1
                lastScale = 1
                offset = .zero
                lastOffset = .zero
            } else {
                scale = 2.5
                lastScale = 2.5
            }
        }
    }

    private func clampOffset(in size: CGSize) {
        let extraW = (size.width * scale - size.width) / 2
        let extraH = (size.height * scale - size.height) / 2
        let clampedX = min(max(offset.width, -extraW), extraW)
        let clampedY = min(max(offset.height, -extraH), extraH)
        withAnimation(.easeOut(duration: 0.15)) {
            offset = CGSize(width: clampedX, height: clampedY)
            lastOffset = offset
        }
    }
}

// MARK: - Toast

struct ToastMessage: Equatable {
    enum Kind { case success, error }
    let kind: Kind
    let text: String
    let actionTitle: String?
    let actionID: UUID
    var action: (() -> Void)?

    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.actionID == rhs.actionID
    }

    static func success(_ text: String) -> ToastMessage {
        ToastMessage(kind: .success, text: text, actionTitle: nil, actionID: UUID(), action: nil)
    }
    static func error(_ text: String) -> ToastMessage {
        ToastMessage(kind: .error, text: text, actionTitle: nil, actionID: UUID(), action: nil)
    }
    static func successWithAction(_ text: String, actionTitle: String, action: @escaping () -> Void) -> ToastMessage {
        ToastMessage(kind: .success, text: text, actionTitle: actionTitle, actionID: UUID(), action: action)
    }
}

struct ToastView: View {
    let message: ToastMessage

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: message.kind == .success ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(message.kind == .success ? .green : .red)
            Text(message.text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
            if let title = message.actionTitle, let action = message.action {
                Button(title, action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.leading, 4)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 40)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

// MARK: - Presenter (handles fullScreenCover on iOS, sheet on macOS)

struct ImagePreviewPresenter: ViewModifier {
    @Binding var isPresented: Bool
    let files: [LocalFile]
    let server: Server?
    @Binding var index: Int
    let onClose: () -> Void

    func body(content: Content) -> some View {
        #if os(iOS)
        content.fullScreenCover(isPresented: $isPresented) {
            ImageViewerView(files: files, server: server, index: $index, onClose: onClose)
        }
        #else
        content.sheet(isPresented: $isPresented) {
            ImageViewerView(files: files, server: server, index: $index, onClose: onClose)
                .frame(minWidth: 640, minHeight: 480)
        }
        #endif
    }
}

// MARK: - UIKit helpers

#if canImport(UIKit)
@MainActor
private func topViewController(base: UIViewController? = nil) -> UIViewController? {
    let root = base ?? UIApplication.shared
        .connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
        .first?
        .rootViewController
    if let nav = root as? UINavigationController { return topViewController(base: nav.visibleViewController) }
    if let tab = root as? UITabBarController, let sel = tab.selectedViewController {
        return topViewController(base: sel)
    }
    if let presented = root?.presentedViewController { return topViewController(base: presented) }
    return root
}
#endif
