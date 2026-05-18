import SwiftUI

struct SettingsView: View {
    let onDone: () -> Void

    @State private var prefs = PreferencesStore.shared
    @State private var cacheSize: Int64 = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Servers") {
                    NavigationLink {
                        ServersListView()
                    } label: {
                        Label("Manage Servers", systemImage: SF.server)
                    }
                }

                Section("Sync") {
                    Toggle("Sync over cellular", isOn: $prefs.syncOverCellular)
                }

                Section("Editor") {
                    Toggle("Optimize media by default", isOn: $prefs.defaultOptimizeMedia)
                }

                Section("Appearance") {
                    Picker("Theme", selection: $prefs.theme) {
                        ForEach(ThemeChoice.allCases) { Text($0.label).tag($0) }
                    }
                }

                Section("Privacy") {
                    Toggle("Lock with Face ID / Touch ID", isOn: $prefs.biometricLockEnabled)
                    Picker("Auto-lock", selection: $prefs.autoLock) {
                        ForEach(AutoLockTimeout.allCases) { Text($0.label).tag($0) }
                    }
                    Toggle("Hide previews in App Switcher", isOn: $prefs.hidePreviewsInAppSwitcher)
                }

                Section("Storage") {
                    HStack {
                        Text("Cache size")
                        Spacer()
                        Text(formatBytes(cacheSize)).foregroundStyle(Palette.textTertiary)
                    }
                    Stepper(value: $prefs.cacheLimitMB, in: 50...10_000, step: 50) {
                        Text("Limit: \(prefs.cacheLimitMB) MB")
                    }
                    Button("Clear cache") {
                        Task {
                            await FileCache.shared.clear()
                            cacheSize = await FileCache.shared.currentSize()
                        }
                    }
                    .foregroundStyle(Palette.danger)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(version).foregroundStyle(Palette.textTertiary)
                    }
                    Link("GitHub", destination: URL(string: "https://github.com/eduard256/beaver-notes-apple")!)
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDone)
                }
            }
            .task {
                cacheSize = await FileCache.shared.currentSize()
            }
        }
    }

    private var version: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(v) (\(b))"
    }
}
