import SwiftUI

struct EditorToolbar: View {
    @Binding var text: String
    @Binding var preview: Bool

    var body: some View {
        HStack(spacing: 2) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    button(SF.bold)    { wrap("**") }
                    button(SF.italic)  { wrap("*") }
                    button(SF.code)    { wrap("`") }
                    divider
                    button(SF.heading) { prepend("## ") }
                    button(SF.list)    { prepend("- ") }
                    button(SF.link)    { insert("[", "](url)") }
                    button(SF.hr)      { insert("\n---\n", "") }
                }
                .padding(.horizontal, Space.s2)
            }
            Spacer(minLength: 0)
            Toggle("", isOn: $preview)
                .toggleStyle(PreviewToggleStyle())
                .padding(.trailing, Space.s2)
        }
        .frame(height: 40)
    }

    private var divider: some View {
        Rectangle().fill(Palette.borderSecondary).frame(width: 1, height: 20).padding(.horizontal, 4)
    }

    @ViewBuilder
    private func button(_ system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.callout)
                .frame(width: 32, height: 32)
                .foregroundStyle(Palette.textSecondary)
        }
        .buttonStyle(.plain)
    }

    private func wrap(_ marker: String) {
        text = text + marker + marker
    }

    private func prepend(_ s: String) {
        if text.isEmpty || text.hasSuffix("\n") {
            text += s
        } else {
            text += "\n" + s
        }
    }

    private func insert(_ before: String, _ after: String) {
        text = text + before + after
    }
}

private struct PreviewToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Image(systemName: SF.preview)
                .font(.callout)
                .padding(.horizontal, Space.s3)
                .frame(height: 32)
                .foregroundStyle(configuration.isOn ? Palette.accent : Palette.textSecondary)
                .background(configuration.isOn ? Palette.accent.opacity(0.12) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
        }
        .buttonStyle(.plain)
    }
}
