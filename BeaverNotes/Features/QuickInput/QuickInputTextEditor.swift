import SwiftUI

struct QuickInputTextEditor: View {
    @Binding var text: String
    var onSubmit: () -> Void

    var body: some View {
        TextField("Write a note…", text: $text, axis: .vertical)
            .lineLimit(1...6)
            .font(.body)
            .padding(.horizontal, Space.s3)
            .padding(.vertical, 10)
            .background(Palette.bgInput)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .stroke(Palette.borderPrimary, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .onSubmit(onSubmit)
            #if os(iOS)
            .submitLabel(.send)
            #endif
    }
}
