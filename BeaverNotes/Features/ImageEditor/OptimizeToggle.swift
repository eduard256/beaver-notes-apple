import SwiftUI

struct OptimizeToggle: View {
    @Binding var enabled: Bool
    let sourceURL: URL
    @State private var originalSize: Int64 = 0

    var body: some View {
        HStack(spacing: Space.s3) {
            Toggle(isOn: $enabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Optimize")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(Palette.textPrimary)
                    Text(estimate)
                        .font(.caption2)
                        .foregroundStyle(Palette.textTertiary)
                }
            }
            .tint(Palette.accent)
        }
        .padding(.horizontal, Space.s4)
        .padding(.vertical, Space.s2)
        .background(Palette.bgSecondary)
        .task { await computeOriginal() }
    }

    private var estimate: String {
        guard originalSize > 0 else { return "calculating…" }
        let bcf = ByteCountFormatter()
        if enabled {
            let optimized = Int64(Double(originalSize) * 0.18)
            return "\(bcf.string(fromByteCount: originalSize)) → ~\(bcf.string(fromByteCount: optimized))"
        }
        return bcf.string(fromByteCount: originalSize)
    }

    private func computeOriginal() async {
        let attrs = try? FileManager.default.attributesOfItem(atPath: sourceURL.path)
        originalSize = (attrs?[.size] as? Int64) ?? 0
    }
}
