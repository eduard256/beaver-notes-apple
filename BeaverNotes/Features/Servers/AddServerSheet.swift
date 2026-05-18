import SwiftUI
import SwiftData

struct AddServerSheet: View {
    let onDone: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \Server.sortOrder) private var servers: [Server]

    var body: some View {
        NavigationStack {
            ServerEntryPage(
                onCancel: onDone,
                onSuccess: { server, password in
                    server.sortOrder = (servers.map(\.sortOrder).max() ?? 0) + 1
                    modelContext.insert(server)
                    try? modelContext.save()
                    Keychain.savePassword(password, forServer: server.id)
                    appState.currentServerID = server.id
                    onDone()
                }
            )
        }
    }
}
