import SwiftUI
import AVKit

struct VideoTrimmerView: View {
    let sourceURL: URL
    let onDone: (URL, Int64) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var duration: Double = 0
    @State private var startSeconds: Double = 0
    @State private var endSeconds: Double = 0
    @State private var optimize = PreferencesStore.shared.defaultOptimize
    @State private var working = false
    @State private var player: AVPlayer?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let player {
                    VideoPlayer(player: player)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Color.black.frame(maxHeight: .infinity)
                }

                VideoTimeline(
                    duration: duration,
                    start: $startSeconds,
                    end: $endSeconds
                )
                .padding(Space.s4)

                Toggle("Optimize", isOn: $optimize)
                    .tint(Palette.accent)
                    .padding(.horizontal, Space.s4)
                    .padding(.bottom, Space.s2)
            }
            .background(Palette.bgPrimary)
            .navigationTitle("Trim video")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(working ? "Working…" : "Done") { Task { await finish() } }
                        .disabled(working)
                }
            }
            .task { await setup() }
        }
    }

    private func setup() async {
        let asset = AVURLAsset(url: sourceURL)
        let dur = (try? await asset.load(.duration).seconds) ?? 0
        duration = dur
        endSeconds = dur
        player = AVPlayer(url: sourceURL)
    }

    private func finish() async {
        working = true
        defer { working = false }
        let dst = AppGroup.outboxFilesDir.appendingPathComponent("\(UUID().uuidString).mp4")
        do {
            let start = CMTime(seconds: startSeconds, preferredTimescale: 600)
            let end = CMTime(seconds: endSeconds, preferredTimescale: 600)
            try await VideoTrimmer.trim(source: sourceURL, start: start, end: end, to: dst)
            let size = (try? FileManager.default.attributesOfItem(atPath: dst.path)[.size] as? Int64) ?? 0
            onDone(dst, size)
            dismiss()
        } catch {
            dismiss()
        }
    }
}
