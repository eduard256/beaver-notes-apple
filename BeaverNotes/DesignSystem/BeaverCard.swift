import SwiftUI

struct BeaverCard<Content: View>: View {
    let pinned: Bool
    @ViewBuilder let content: () -> Content

    init(pinned: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.pinned = pinned
        self.content = content
    }

    var body: some View {
        content()
            .padding(.horizontal, Space.s5)
            .padding(.vertical, Space.s4)
            .background(Palette.bgCard)
            .overlay(alignment: .leading) {
                if pinned {
                    Rectangle().fill(Palette.pin).frame(width: 3)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .stroke(Palette.borderSecondary, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }
}
