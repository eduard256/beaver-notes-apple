import SwiftUI

struct SyncSection: View {
    let prefs: PreferencesStore

    var body: some View {
        Section("Sync") {
            Picker("Polling interval", selection: Binding(get: { prefs.pollingIntervalSeconds }, set: { prefs.pollingIntervalSeconds = $0 })) {
                Text("3 s").tag(3)
                Text("7 s").tag(7)
                Text("15 s").tag(15)
                Text("30 s").tag(30)
                Text("60 s").tag(60)
            }
            Toggle("Use cellular", isOn: Binding(get: { prefs.cellularSyncEnabled }, set: { prefs.cellularSyncEnabled = $0 }))
                .tint(Palette.accent)
        }
    }
}
