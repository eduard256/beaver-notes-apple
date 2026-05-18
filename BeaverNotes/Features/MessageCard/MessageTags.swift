import SwiftUI

struct MessageTags: View {
    let tags: [String]
    let onTap: (String) -> Void

    var body: some View {
        FlowLayout(spacing: Space.s2) {
            ForEach(tags, id: \.self) { t in
                Button {
                    onTap(t)
                } label: {
                    Text("#\(t)")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, Space.s2)
                        .padding(.vertical, 3)
                        .foregroundStyle(Palette.accent)
                        .background(Palette.accent.opacity(0.1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// Simple wrap-content flow layout for chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[CGSize]] = [[]]
        var rowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for v in subviews {
            let size = v.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, !rows[rows.count - 1].isEmpty {
                totalHeight += rowHeight + spacing
                rows.append([])
                rowWidth = 0
                rowHeight = 0
            }
            rows[rows.count - 1].append(size)
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for v in subviews {
            let size = v.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            v.place(at: CGPoint(x: x, y: y), proposal: .init(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
