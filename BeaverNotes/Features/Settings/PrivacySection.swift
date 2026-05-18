import SwiftUI

struct PrivacySection: View {
    let prefs: PreferencesStore

    var body: some View {
        Section("Privacy") {
            Toggle("Biometric lock", isOn: Binding(get: { prefs.biometricLockEnabled }, set: { prefs.biometricLockEnabled = $0 }))
                .tint(Palette.accent)
            Picker("Auto-lock", selection: Binding(get: { prefs.autoLockSeconds }, set: { prefs.autoLockSeconds = $0 })) {
                Text("Immediately").tag(0)
                Text("After 1 min").tag(60)
                Text("After 5 min").tag(300)
                Text("After 15 min").tag(900)
            }
            Toggle("Hide previews in app switcher", isOn: Binding(get: { prefs.hidePreviewsInAppSwitcher }, set: { prefs.hidePreviewsInAppSwitcher = $0 }))
                .tint(Palette.accent)
        }
    }
}
