import SwiftUI

struct EditorToolbar: View {
    let onAction: (MarkdownAction) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Space.s2) {
                btn(Symbols.bold, .bold)
                btn(Symbols.italic, .italic)
                btn(Symbols.code, .code)
                btn(Symbols.heading, .heading)
                btn(Symbols.list, .list)
                btn(Symbols.link, .link)
                btn(Symbols.hr, .hr)
            }
            .padding(.horizontal, Space.s3)
            .padding(.vertical, Space.s2)
        }
        .background(Palette.bgSecondary)
    }

    private func btn(_ symbol: String, _ action: MarkdownAction) -> some View {
        Button {
            onAction(action)
        } label: {
            Image(systemName: symbol)
                .font(.callout)
                .foregroundStyle(Palette.textPrimary)
                .frame(width: 36, height: 32)
                .background(Palette.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
        }
        .buttonStyle(.plain)
    }
}
