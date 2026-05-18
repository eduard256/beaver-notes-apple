import SwiftUI

struct EmptyWallView: View {
    var body: some View {
        VStack(spacing: Space.s4) {
            Image(systemName: "tree")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .foregroundStyle(Palette.textTertiary)
            Text("No notes yet")
                .font(.title3.weight(.medium))
                .foregroundStyle(Palette.textPrimary)
            Text("Write something below to get started.")
                .font(.callout)
                .foregroundStyle(Palette.textSecondary)
        }
        .padding(Space.s6)
    }
}
