import SwiftUI

struct EditorSection: View {
    let prefs: PreferencesStore

    var body: some View {
        Section("Editor") {
            Toggle("Optimize media by default", isOn: Binding(get: { prefs.defaultOptimize }, set: { prefs.defaultOptimize = $0 }))
                .tint(Palette.accent)
        }
    }
}
