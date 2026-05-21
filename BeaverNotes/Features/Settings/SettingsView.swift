import SwiftUI
import SwiftData

struct SettingsView: View {
    let onDone: () -> Void

    @State private var prefs = PreferencesStore.shared
    @State private var cacheSize: Int64 = 0
    @State private var confirmingErase = false
    @State private var erasing = false
    @Environment(AppState.self) private var appState
    @Environment(SyncCoordinatorRegistry.self) private var registry
    @Environment(\.modelContext) private var modelContext

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
                    Link("Privacy Policy", destination: URL(string: "https://eduard256.github.io/beaver-notes-apple/PRIVACY.md")!)
                    Link("Support", destination: URL(string: "mailto:dev.apps.pol@gmail.com")!)
                }

                Section {
                    Button(role: .destructive) {
                        confirmingErase = true
                    } label: {
                        if erasing {
                            HStack {
                                ProgressView()
                                Text("Erasing…")
                            }
                        } else {
                            Text("Erase all local data")
                        }
                    }
                    .disabled(erasing)
                } footer: {
                    Text("Removes all locally stored notes, files, server connections, and preferences from this device. Data on your servers is not affected.")
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
            .confirmationDialog(
                "Erase all local data?",
                isPresented: $confirmingErase,
                titleVisibility: .visible
            ) {
                Button("Erase Everything", role: .destructive) {
                    eraseAll()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This deletes all locally stored notes, files, server connections, and preferences. Data on your servers is not affected.")
            }
        }
    }

    private func eraseAll() {
        erasing = true
        Task {
            await LocalDataEraser.eraseEverything(
                context: modelContext,
                registry: registry,
                appState: appState
            )
            erasing = false
            onDone()
        }
    }

    private var version: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(v) (\(b))"
    }
}
