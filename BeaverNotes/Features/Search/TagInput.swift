import SwiftUI

struct TagInput: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: Space.s2) {
            Image(systemName: Symbols.tag).foregroundStyle(Palette.textSecondary)
            TextField("tag", text: $text)
                .textFieldStyle(.plain)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                #endif
        }
        .padding(.horizontal, Space.s3)
        .padding(.vertical, Space.s2)
        .background(Palette.bgInput)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md).stroke(Palette.borderPrimary, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }
}
