import SwiftUI

struct EditorTextView: View {
    @Binding var text: String

    var body: some View {
        TextEditor(text: $text)
            .font(.system(.callout, design: .monospaced))
            .foregroundStyle(Palette.textPrimary)
            .scrollContentBackground(.hidden)
            .background(Palette.bgPrimary)
    }
}
