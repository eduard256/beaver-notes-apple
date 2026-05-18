import SwiftUI
import AVFoundation
import AVKit

struct VideoTrimmerView: View {
    let sourceURL: URL
    let originalBytes: Int64
    let onDone: (URL) -> Void
    let onCancel: () -> Void

    @State private var duration: Double = 0
    @State private var startSeconds: Double = 0
    @State private var endSeconds: Double = 0
    @State private var player = AVPlayer()
    @State private var optimize = true
    @State private var estimatedBytes: Int64?
    @State private var exporting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: Space.s4) {
                VideoPlayer(player: player)
                    .frame(maxHeight: .infinity)

                VStack(spacing: Space.s2) {
                    HStack {
                        Text(format(startSeconds)).font(.caption.monospacedDigit())
                        Spacer()
                        Text(format(endSeconds - startSeconds))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Palette.accent)
                        Spacer()
                        Text(format(endSeconds)).font(.caption.monospacedDigit())
                    }
                    VideoTimeline(duration: max(0.1, duration), startSeconds: $startSeconds, endSeconds: $endSeconds)
                }
                .padding(.horizontal, Space.s4)

                OptimizeToggle(optimize: $optimize, originalBytes: originalBytes, estimatedBytes: estimatedBytes)
                    .padding(.horizontal, Space.s4)
            }
            .padding(.bottom, Space.s4)
            .navigationTitle("Trim Video")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await export() }
                    } label: {
                        if exporting { ProgressView() } else { Text("Done").fontWeight(.semibold) }
                    }
                    .disabled(exporting)
                }
            }
            .task { await loadAsset() }
            .onChange(of: optimize) { _, _ in Task { await refreshEstimate() } }
        }
    }

    private func loadAsset() async {
        let asset = AVURLAsset(url: sourceURL)
        if let d = try? await asset.load(.duration) {
            duration = CMTimeGetSeconds(d)
            startSeconds = 0
            endSeconds = duration
        }
        player.replaceCurrentItem(with: AVPlayerItem(url: sourceURL))
        player.play()
        await refreshEstimate()
    }

    private func refreshEstimate() async {
        guard optimize else { estimatedBytes = nil; return }
        estimatedBytes = await VideoOptimizer.estimatedSize(source: sourceURL, preset: .p1080)
    }

    private func export() async {
        exporting = true
        let dst = AppGroup.outboxFilesDir.appendingPathComponent("\(UUID().uuidString).mp4")
        let start = CMTime(seconds: startSeconds, preferredTimescale: 600)
        let end   = CMTime(seconds: endSeconds,   preferredTimescale: 600)
        do {
            if optimize {
                try await VideoOptimizer.export(source: sourceURL, to: dst, preset: .p1080, timeRange: CMTimeRange(start: start, end: end))
            } else {
                try await VideoTrimmer.trim(source: sourceURL, start: start, end: end, to: dst)
            }
            onDone(dst)
        } catch {
            exporting = false
        }
    }

    private func format(_ s: Double) -> String {
        let total = Int(s)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
