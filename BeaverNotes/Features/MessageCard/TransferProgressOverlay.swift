import SwiftUI

struct TransferProgressOverlay: View {
    let file: LocalFile
    var style: Style = .image

    enum Style {
        case image
        case row
    }

    @Environment(UploadTracker.self) private var tracker

    private var progress: Double? {
        guard file.transferState == .transferring || file.transferState == .queued else { return nil }
        return tracker.progressForFile(file.localID) ?? 0
    }

    var body: some View {
        if let progress {
            switch style {
            case .image:
                ZStack {
                    Color.black.opacity(0.35)
                    VStack(spacing: 6) {
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                            .tint(.white)
                            .frame(maxWidth: 140)
                        Text("\(Int(progress * 100))%")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12)
                }
                .allowsHitTesting(false)
            case .row:
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(Palette.accent)
            }
        } else if file.transferState == .failed {
            switch style {
            case .image:
                ZStack {
                    Color.black.opacity(0.45)
                    Image(systemName: SF.warning)
                        .font(.title3)
                        .foregroundStyle(Palette.danger)
                }
                .allowsHitTesting(false)
            case .row:
                EmptyView()
            }
        }
    }
}
