import SwiftUI

struct EmptyWallView: View {
    let isFiltered: Bool

    var body: some View {
        VStack(spacing: Space.s4) {
            Image(systemName: isFiltered ? SF.search : "tray")
                .font(.system(size: 44))
                .foregroundStyle(Palette.textTertiary.opacity(0.5))

            Text(isFiltered ? "Nothing found" : "No notes yet")
                .font(Typography.body)
                .foregroundStyle(Palette.textTertiary)

            if !isFiltered {
                Text("Send your first message below.")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.textTertiary)
            }
        }
        .padding(Space.s6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
