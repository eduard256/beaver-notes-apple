import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(SyncCoordinatorRegistry.self) private var registry
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Server.sortOrder) private var servers: [Server]

    var body: some View {
        Group {
            if servers.isEmpty {
                OnboardingFlow()
            } else if appState.isLocked {
                LockScreen()
            } else {
                MainContainer()
            }
        }
        .background(Palette.bgPrimary.ignoresSafeArea())
        .preferredColorScheme(PreferencesStore.shared.colorScheme)
        .onAppear { setupOnFirstAppear() }
        .onChange(of: scenePhase) { _, new in
            handleScenePhase(new)
        }
        .onChange(of: servers.count) { _, _ in
            // First server just added (post-onboarding) or one removed → reconfigure
            if appState.currentServerID == nil, let first = servers.first {
                appState.currentServerID = first.id
            }
            registry.activeServerID = appState.currentServerID
            registry.startAll(servers: servers, context: modelContext)
        }
        .onChange(of: appState.currentServerID) { _, _ in
            registry.activeServerID = appState.currentServerID
            registry.startAll(servers: servers, context: modelContext)
            Task {
                if let id = appState.currentServerID,
                   let server = servers.first(where: { $0.id == id }) {
                    await registry.coordinator(for: server, context: modelContext).triggerImmediatePull()
                }
            }
        }
        .overlay {
            if scenePhase != .active && PreferencesStore.shared.hidePreviewsInAppSwitcher && !servers.isEmpty {
                PrivacyShade()
            }
        }
    }

    private func setupOnFirstAppear() {
        if appState.currentServerID == nil, let first = servers.first {
            appState.currentServerID = first.id
        }
        if PreferencesStore.shared.biometricLockEnabled {
            appState.isLocked = true
        }
        registry.activeServerID = appState.currentServerID
        registry.startAll(servers: servers, context: modelContext)
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            registry.startAll(servers: servers, context: modelContext)
        case .background, .inactive:
            registry.stopAll()
        @unknown default: break
        }
    }
}

// Top-level container that decides iPhone vs iPad/Mac layout
struct MainContainer: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \Server.sortOrder) private var servers: [Server]
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            iPhoneLayout
        } else {
            iPadMacLayout
        }
        #else
        iPadMacLayout
        #endif
    }

    private var iPhoneLayout: some View {
        NavigationStack {
            WallView()
        }
    }

    private var iPadMacLayout: some View {
        NavigationSplitView(columnVisibility: $sidebarVisibility) {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 340)
        } detail: {
            WallView()
        }
        .navigationSplitViewStyle(.balanced)
    }
}
