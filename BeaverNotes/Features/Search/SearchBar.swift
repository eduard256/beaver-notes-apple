import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @Binding var showFilters: Bool

    var body: some View {
        HStack(spacing: Space.s2) {
            Image(systemName: Symbols.search)
                .foregroundStyle(Palette.textSecondary)
            TextField("Search", text: $text)
                .textFieldStyle(.plain)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                #endif
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: Symbols.close).foregroundStyle(Palette.textTertiary)
                }
                .buttonStyle(.plain)
            }
            Button { showFilters.toggle() } label: {
                Image(systemName: showFilters ? Symbols.filterActive : Symbols.filter)
                    .foregroundStyle(Palette.accent)
            }
            .buttonStyle(.plain)
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
