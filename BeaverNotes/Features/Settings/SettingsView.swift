import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var prefs = PreferencesStore.shared

    var body: some View {
        Form {
            ServersSection()
            SyncSection(prefs: prefs)
            EditorSection(prefs: prefs)
            AppearanceSection(prefs: prefs)
            PrivacySection(prefs: prefs)
            StorageSection(prefs: prefs)
            AboutSection()
        }
        .navigationTitle("Settings")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}
