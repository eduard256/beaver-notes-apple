import SwiftUI

struct OptimizeToggle: View {
    @Binding var optimize: Bool
    let originalBytes: Int64
    let estimatedBytes: Int64?

    var body: some View {
        HStack(spacing: Space.s3) {
            Toggle("", isOn: $optimize)
                .labelsHidden()

            VStack(alignment: .leading, spacing: 2) {
                Text("Optimize")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(Palette.textPrimary)
                if optimize, let est = estimatedBytes {
                    Text("\(formatBytes(originalBytes)) → \(formatBytes(est))")
                        .font(.caption2)
                        .foregroundStyle(Palette.success)
                } else if !optimize {
                    Text("Send original (\(formatBytes(originalBytes)))")
                        .font(.caption2)
                        .foregroundStyle(Palette.textTertiary)
                }
            }
            Spacer()
        }
        .padding(Space.s3)
        .background(Palette.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }
}
