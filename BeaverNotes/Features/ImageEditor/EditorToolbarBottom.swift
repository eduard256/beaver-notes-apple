import SwiftUI

enum EditorMode: String, CaseIterable, Identifiable {
    case crop, rotate, filters, draw
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .crop:    return SF.crop
        case .rotate:  return SF.rotate
        case .filters: return SF.filters
        case .draw:    return SF.draw
        }
    }
    var label: String {
        switch self {
        case .crop:    return "Crop"
        case .rotate:  return "Rotate"
        case .filters: return "Filters"
        case .draw:    return "Draw"
        }
    }
}

struct EditorToolbarBottom: View {
    @Binding var mode: EditorMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(EditorMode.allCases) { m in
                Button {
                    mode = m
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: m.symbol).font(.callout)
                        Text(m.label).font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Space.s2)
                    .foregroundStyle(mode == m ? Palette.accent : Palette.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 56)
    }
}
