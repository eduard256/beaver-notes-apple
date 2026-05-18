import SwiftUI

struct MessageBody: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            ForEach(MarkdownRenderer.parse(content)) { block in
                blockView(block)
            }
        }
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .paragraph(let attr):
            Text(attr).font(Typography.body).foregroundStyle(Palette.textPrimary)
        case .heading(let level, let attr):
            Text(attr)
                .font(headingFont(level))
                .foregroundStyle(Palette.textPrimary)
        case .codeBlock(let lang, let code):
            CodeBlockView(language: lang, code: code)
        case .bullet(let attr):
            HStack(alignment: .firstTextBaseline, spacing: Space.s2) {
                Text("•").foregroundStyle(Palette.textSecondary)
                Text(attr).foregroundStyle(Palette.textPrimary)
            }
        case .blockquote(let attr):
            HStack(spacing: Space.s3) {
                Rectangle().fill(Palette.borderPrimary).frame(width: 3)
                Text(attr).italic().foregroundStyle(Palette.textSecondary)
            }
        case .rule:
            Rectangle().fill(Palette.borderSecondary).frame(height: 1)
                .padding(.vertical, Space.s2)
        }
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: return .title2.weight(.bold)
        case 2: return .title3.weight(.semibold)
        default: return .headline
        }
    }
}

struct CodeBlockView: View {
    let language: String?
    let code: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let lang = language, !lang.isEmpty {
                Text(lang)
                    .font(Typography.monoSmall)
                    .foregroundStyle(Palette.textTertiary)
                    .padding(.horizontal, Space.s3)
                    .padding(.top, Space.s2)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                Text(CodeHighlighter.highlight(code, language: language))
                    .textSelection(.enabled)
                    .padding(Space.s3)
            }
        }
        .background(Palette.codeBg)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.sm)
                .stroke(Palette.codeBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
    }
}
