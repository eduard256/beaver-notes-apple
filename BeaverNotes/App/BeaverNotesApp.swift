import SwiftUI
import SwiftData

@main
struct BeaverNotesApp: App {
    @State private var appState = AppState()
    @State private var registry = SyncCoordinatorRegistry()
    @State private var uploadTracker = UploadTracker.shared
    private let modelContainer: ModelContainer

    init() {
        do {
            self.modelContainer = try BeaverModelContainer.make()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(registry)
                .environment(uploadTracker)
                .modelContainer(modelContainer)
                .tint(Palette.accent)
                .onOpenURL { url in
                    DeepLinkRouter.handle(url, appState: appState)
                }
        }
        #if os(macOS)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Note") { /* wired via env in RootView */ }
                    .keyboardShortcut("n", modifiers: [.command])
            }
        }
        #endif
    }
}
