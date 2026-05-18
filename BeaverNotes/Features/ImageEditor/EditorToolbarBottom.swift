import SwiftUI

struct EditorToolbarBottom: View {
    @Binding var mode: EditorMode
    let onReset: () -> Void

    var body: some View {
        HStack(spacing: Space.s2) {
            tab(.crop, symbol: Symbols.crop, label: "Crop")
            tab(.rotate, symbol: Symbols.rotate, label: "Rotate")
            tab(.filters, symbol: Symbols.filters, label: "Filters")
            tab(.draw, symbol: Symbols.draw, label: "Draw")
            Button {
                onReset()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: Symbols.reset)
                    Text("Reset").font(.caption2)
                }
                .foregroundStyle(Palette.danger)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Space.s3)
        .padding(.vertical, Space.s3)
        .background(Palette.bgCard)
    }

    private func tab(_ m: EditorMode, symbol: String, label: String) -> some View {
        Button {
            mode = m
            if m == .rotate { /* handled via state */ }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                Text(label).font(.caption2)
            }
            .foregroundStyle(mode == m ? Palette.accent : Palette.textSecondary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
