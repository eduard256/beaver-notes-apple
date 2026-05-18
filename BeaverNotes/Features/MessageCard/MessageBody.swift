import SwiftUI

struct MessageBody: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            ForEach(blocks.indices, id: \.self) { i in
                view(for: blocks[i])
            }
        }
    }

    private var blocks: [MarkdownBlock] {
        MarkdownRenderer.parse(content)
    }

    @ViewBuilder
    private func view(for block: MarkdownBlock) -> some View {
        switch block {
        case .paragraph(let attr):
            Text(attr).font(Typography.body).foregroundStyle(Palette.textPrimary)
        case .heading(let level, let attr):
            Text(attr)
                .font(level == 1 ? .title3.weight(.semibold) : level == 2 ? .headline : .subheadline.weight(.semibold))
                .foregroundStyle(Palette.textPrimary)
                .padding(.top, Space.s2)
        case .bullet(let attr):
            HStack(alignment: .top, spacing: Space.s2) {
                Text("•").foregroundStyle(Palette.textSecondary)
                Text(attr).font(Typography.body).foregroundStyle(Palette.textPrimary)
            }
        case .blockquote(let attr):
            HStack {
                Rectangle().fill(Palette.borderPrimary).frame(width: 3)
                Text(attr).font(Typography.body).foregroundStyle(Palette.textSecondary)
            }
            .padding(.leading, 2)
        case .codeBlock(let lang, let code):
            CodeBlockView(language: lang, code: code)
        case .rule:
            Rectangle().fill(Palette.borderSecondary).frame(height: 1).padding(.vertical, 4)
        }
    }
}

private struct CodeBlockView: View {
    let language: String?
    let code: String
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text((language ?? "code").uppercased())
                    .font(.caption2.weight(.medium))
                    .tracking(0.4)
                    .foregroundStyle(Palette.textTertiary)
                Spacer()
                Button {
                    copy()
                } label: {
                    Text(copied ? "Copied" : "Copy")
                        .font(.caption2)
                        .foregroundStyle(copied ? Palette.success : Palette.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Space.s3)
            .padding(.vertical, Space.s2)
            .background(Palette.bgTertiary)

            Text(CodeHighlighter.highlight(code, language: language))
                .textSelection(.enabled)
                .padding(Space.s3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Palette.codeBg)
        .overlay(RoundedRectangle(cornerRadius: Radius.sm).stroke(Palette.codeBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
    }

    private func copy() {
        #if canImport(UIKit)
        UIPasteboard.general.string = code
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        #endif
        copied = true
        Haptics.success()
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            copied = false
        }
    }
}

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
