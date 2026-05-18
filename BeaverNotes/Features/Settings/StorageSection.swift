import SwiftUI

struct StorageSection: View {
    let prefs: PreferencesStore
    @State private var cacheSize: Int64 = 0

    var body: some View {
        Section("Storage") {
            HStack {
                Text("Cache size")
                Spacer()
                Text(ByteCountFormatter().string(fromByteCount: cacheSize))
                    .foregroundStyle(Palette.textSecondary)
            }
            Stepper(value: Binding(get: { prefs.cacheLimitMB }, set: { prefs.cacheLimitMB = $0 }), in: 100...5000, step: 100) {
                Text("Limit: \(prefs.cacheLimitMB) MB")
            }
            Button("Clear cache", role: .destructive) {
                Task {
                    await FileCache.shared.clear()
                    await refresh()
                }
            }
        }
        .task { await refresh() }
    }

    private func refresh() async {
        cacheSize = await FileCache.shared.currentSize()
    }
}
