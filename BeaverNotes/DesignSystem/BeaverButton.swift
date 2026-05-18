import SwiftUI

struct BeaverButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, danger }
    let kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.medium))
            .padding(.horizontal, Space.s4)
            .padding(.vertical, Space.s3)
            .frame(maxWidth: .infinity)
            .background(background(pressed: configuration.isPressed))
            .foregroundStyle(foreground)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }

    private func background(pressed: Bool) -> Color {
        switch kind {
        case .primary:   return pressed ? Palette.accentHover : Palette.accent
        case .secondary: return Palette.bgSecondary
        case .danger:    return Palette.danger
        }
    }

    private var foreground: Color {
        switch kind {
        case .primary, .danger: return Palette.bgPrimary
        case .secondary:        return Palette.textPrimary
        }
    }
}

extension ButtonStyle where Self == BeaverButtonStyle {
    static var beaverPrimary: BeaverButtonStyle   { BeaverButtonStyle(kind: .primary) }
    static var beaverSecondary: BeaverButtonStyle { BeaverButtonStyle(kind: .secondary) }
    static var beaverDanger: BeaverButtonStyle    { BeaverButtonStyle(kind: .danger) }
}
