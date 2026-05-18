import SwiftUI
import SwiftData
import PhotosUI

struct QuickInputView: View {
    let server: Server
    @Environment(\.modelContext) private var modelContext
    @State private var text: String = ""
    @State private var attachments: [PendingAttachment] = []
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var showImageEditor = false
    @State private var pendingImageURL: URL?

    var body: some View {
        VStack(spacing: 0) {
            if !attachments.isEmpty {
                AttachmentBar(attachments: attachments) { remove in
                    attachments.removeAll { $0.id == remove.id }
                }
            }

            HStack(alignment: .bottom, spacing: Space.s2) {
                PhotosPicker(selection: $photoItems, matching: .any(of: [.images, .videos])) {
                    Image(systemName: Symbols.attach)
                        .font(.title3)
                        .foregroundStyle(Palette.accent)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)

                QuickInputTextEditor(text: $text, onSubmit: send)

                Button(action: send) {
                    Image(systemName: Symbols.send)
                        .font(.title2)
                        .foregroundStyle(canSend ? Palette.accent : Palette.textTertiary)
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                #if os(macOS)
                .keyboardShortcut(.return, modifiers: .command)
                #endif
            }
            .padding(.horizontal, Space.s3)
            .padding(.vertical, Space.s2)
        }
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle().fill(Palette.borderSecondary).frame(height: 0.5)
        }
        .onAppear {
            text = Drafts.load(forServer: server.id)
        }
        .onChange(of: text) { _, new in
            Drafts.save(new, forServer: server.id)
        }
        .onChange(of: photoItems) { _, new in
            Task { await loadPhotos(new) }
        }
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty
    }

    private func send() {
        guard canSend else { return }
        let content = text.trimmingCharacters(in: .whitespacesAndNewlines)

        let msg = Message(server: server, content: content, tags: HashtagExtractor.extract(from: content), syncState: .pending)
        for att in attachments {
            let f = LocalFile(filename: att.filename, mimeType: att.mimeType, size: att.size, sourcePath: att.url.path, transferState: .queued)
            msg.files.append(f)
        }
        modelContext.insert(msg)

        let op = OutboxOp(server: server, kind: .create, messageLocalID: msg.localID)
        modelContext.insert(op)
        try? modelContext.save()

        text = ""
        attachments.removeAll()
        Drafts.save("", forServer: server.id)
        Haptics.tap()
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else { continue }
                let ext = inferExt(for: item)
                let url = AppGroup.outboxFilesDir.appendingPathComponent("\(UUID().uuidString).\(ext)")
                try data.write(to: url)
                let mime = inferMime(ext: ext)
                let size = Int64(data.count)
                attachments.append(PendingAttachment(url: url, filename: url.lastPathComponent, mimeType: mime, size: size))
            } catch {}
        }
        photoItems = []
    }

    private func inferExt(for item: PhotosPickerItem) -> String {
        if let id = item.supportedContentTypes.first?.preferredFilenameExtension { return id }
        return "jpg"
    }

    private func inferMime(ext: String) -> String {
        switch ext.lowercased() {
        case "jpg", "jpeg": return "image/jpeg"
        case "png":  return "image/png"
        case "heic": return "image/heic"
        case "mp4":  return "video/mp4"
        case "mov":  return "video/quicktime"
        default:     return "application/octet-stream"
        }
    }
}

struct PendingAttachment: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let filename: String
    let mimeType: String
    let size: Int64
}
