import SwiftUI

struct BeaverTextFieldStyle: TextFieldStyle {
    var hasError: Bool = false

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textFieldStyle(.plain)
            .padding(.horizontal, Space.s4)
            .padding(.vertical, 12)
            .background(Palette.bgInput)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(hasError ? Palette.danger : Palette.borderPrimary, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .font(.body)
    }
}

extension View {
    func beaverField(hasError: Bool = false) -> some View {
        self.textFieldStyle(BeaverTextFieldStyle(hasError: hasError))
    }
}
