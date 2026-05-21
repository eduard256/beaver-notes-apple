import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

struct QuickInputView: View {
    let onEdit: (Message) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \Server.sortOrder) private var servers: [Server]

    @State private var text: String = ""
    @State private var attachments: [PendingAttachment] = []
    @State private var photoSelection: [PhotosPickerItem] = []
    @State private var showFullEditor = false
    @State private var showFileImporter = false
    @State private var sending = false

    var body: some View {
        VStack(spacing: 0) {
            if !attachments.isEmpty {
                AttachmentBar(attachments: attachments) { a in
                    attachments.removeAll { $0.id == a.id }
                }
                .padding(.top, Space.s2)
            }

            HStack(alignment: .bottom, spacing: Space.s2) {
                Menu {
                    PhotosPicker(selection: $photoSelection, matching: .any(of: [.images, .videos])) {
                        Label("Photo or Video", systemImage: SF.image)
                    }
                    Button {
                        showFileImporter = true
                    } label: {
                        Label("File", systemImage: SF.file)
                    }
                } label: {
                    Image(systemName: SF.attach)
                        .font(.title3)
                        .foregroundStyle(Palette.textTertiary)
                        .frame(width: 36, height: 36)
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
                .onChange(of: photoSelection) { _, items in
                    Task { await ingestPicker(items) }
                }
                .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
                    if case .success(let urls) = result {
                        Task { await ingestFiles(urls) }
                    }
                }

                TextField("Message…", text: $text, axis: .vertical)
                    .lineLimit(1...6)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, Space.s3)
                    .padding(.vertical, 8)
                    .background(Palette.bgInput)
                    .overlay(RoundedRectangle(cornerRadius: Radius.lg).stroke(Palette.borderPrimary, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                    .onChange(of: text) { _, new in
                        if let id = appState.currentServerID {
                            Drafts.save(new, forServer: id)
                        }
                    }

                Button {
                    showFullEditor = true
                } label: {
                    Image(systemName: SF.expand)
                        .font(.title3)
                        .foregroundStyle(Palette.textTertiary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)

                Button {
                    send()
                } label: {
                    Image(systemName: SF.send)
                        .font(.title2)
                        .foregroundStyle(canSend ? Palette.accent : Palette.textTertiary.opacity(0.4))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .disabled(!canSend || sending)
            }
            .padding(.horizontal, Space.s4)
            .padding(.top, Space.s2)
            .padding(.bottom, Space.s2)
        }
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
        .onAppear(perform: loadDraft)
        .onChange(of: appState.currentServerID) { _, _ in loadDraft() }
        .sheet(isPresented: $showFullEditor) {
            EditorView(initialContent: text, isEdit: false) { final in
                text = final
                showFullEditor = false
                send()
            }
        }
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty
    }

    private func loadDraft() {
        guard let id = appState.currentServerID else { return }
        text = Drafts.load(forServer: id)
    }

    private func ingestPicker(_ items: [PhotosPickerItem]) async {
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            let ext = item.supportedContentTypes.first?.preferredFilenameExtension ?? "bin"
            let mime = item.supportedContentTypes.first?.preferredMIMEType ?? "application/octet-stream"
            let url = AppGroup.outboxFilesDir.appendingPathComponent("\(UUID().uuidString).\(ext)")
            do {
                try data.write(to: url, options: .atomic)
                attachments.append(PendingAttachment(url: url, filename: "attachment.\(ext)", mimeType: mime, size: Int64(data.count)))
            } catch {
                continue
            }
        }
        photoSelection.removeAll()
    }

    private func ingestFiles(_ urls: [URL]) async {
        for src in urls {
            let needsScope = src.startAccessingSecurityScopedResource()
            defer { if needsScope { src.stopAccessingSecurityScopedResource() } }
            let ext = src.pathExtension.isEmpty ? "bin" : src.pathExtension
            let mime = UTType(filenameExtension: ext)?.preferredMIMEType ?? "application/octet-stream"
            let dst = AppGroup.outboxFilesDir.appendingPathComponent("\(UUID().uuidString).\(ext)")
            do {
                if FileManager.default.fileExists(atPath: dst.path) {
                    try FileManager.default.removeItem(at: dst)
                }
                try FileManager.default.copyItem(at: src, to: dst)
                let size = (try? FileManager.default.attributesOfItem(atPath: dst.path)[.size] as? Int64) ?? 0
                attachments.append(PendingAttachment(url: dst, filename: src.lastPathComponent, mimeType: mime, size: size))
            } catch {
                continue
            }
        }
    }

    private func send() {
        guard let serverID = appState.currentServerID,
              let server = servers.first(where: { $0.id == serverID }) else { return }
        sending = true

        let content = text
        let payload = attachments
        text = ""
        attachments = []
        Drafts.save("", forServer: serverID)

        let msg = Message(server: server, content: content, syncState: .pending)
        msg.tags = HashtagExtractor.extract(from: content)
        for p in payload {
            let f = LocalFile(
                filename: p.filename,
                mimeType: p.mimeType,
                size: p.size,
                sourcePath: p.url.path,
                transferState: .queued
            )
            msg.files.append(f)
        }
        modelContext.insert(msg)

        let op = OutboxOp(server: server, kind: .create, messageLocalID: msg.localID)
        modelContext.insert(op)
        try? modelContext.save()
        sending = false
        Haptics.tap()
    }
}
