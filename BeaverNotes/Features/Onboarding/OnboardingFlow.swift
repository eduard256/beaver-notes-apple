import SwiftUI
import SwiftData

struct OnboardingFlow: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var page = 0

    var body: some View {
        ZStack {
            Palette.bgPrimary.ignoresSafeArea()
            Group {
                switch page {
                case 0: WelcomePage(onContinue: { page = 1 })
                case 1:
                    ServerEntryPage(
                        onCancel: { page = 0 },
                        onSuccess: { server, password in
                            modelContext.insert(server)
                            try? modelContext.save()
                            Keychain.savePassword(password, forServer: server.id)
                            appState.currentServerID = server.id
                        }
                    )
                default: EmptyView()
                }
            }
            .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
        .animation(.easeInOut(duration: 0.25), value: page)
    }
}
