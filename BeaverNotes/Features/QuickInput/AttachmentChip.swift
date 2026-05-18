import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct AttachmentChip: View {
    let attachment: PendingAttachment
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: Space.s2) {
            thumb
            VStack(alignment: .leading, spacing: 1) {
                Text(attachment.filename)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundStyle(Palette.textPrimary)
                Text(ByteCountFormatter().string(fromByteCount: attachment.size))
                    .font(.caption2)
                    .foregroundStyle(Palette.textTertiary)
            }
            .frame(maxWidth: 120, alignment: .leading)

            Button(action: onRemove) {
                Image(systemName: Symbols.close)
                    .font(.caption2)
                    .foregroundStyle(Palette.textSecondary)
                    .padding(4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Space.s2)
        .padding(.vertical, Space.s1)
        .background(Palette.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    @ViewBuilder
    private var thumb: some View {
        if attachment.mimeType.hasPrefix("image/") {
            #if canImport(UIKit)
            if let img = UIImage(contentsOfFile: attachment.url.path) {
                Image(uiImage: img).resizable().scaledToFill().frame(width: 32, height: 32).clipShape(RoundedRectangle(cornerRadius: 4))
            } else { placeholder }
            #elseif canImport(AppKit)
            if let img = NSImage(contentsOfFile: attachment.url.path) {
                Image(nsImage: img).resizable().scaledToFill().frame(width: 32, height: 32).clipShape(RoundedRectangle(cornerRadius: 4))
            } else { placeholder }
            #else
            placeholder
            #endif
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Image(systemName: attachment.mimeType.hasPrefix("video/") ? Symbols.play : Symbols.file)
            .foregroundStyle(Palette.textSecondary)
            .frame(width: 32, height: 32)
            .background(Palette.bgTertiary, in: RoundedRectangle(cornerRadius: 4))
    }
}
