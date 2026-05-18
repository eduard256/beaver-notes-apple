import SwiftUI

struct AppearanceSection: View {
    let prefs: PreferencesStore

    var body: some View {
        Section("Appearance") {
            Picker("Theme", selection: Binding(get: { prefs.themeOverride }, set: { prefs.themeOverride = $0 })) {
                ForEach(ThemeOverride.allCases) { t in
                    Text(t.label).tag(t)
                }
            }
        }
    }
}
