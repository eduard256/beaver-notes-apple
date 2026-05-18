import SwiftUI
import SwiftData

struct ServerPickerSheet: View {
    let onDone: () -> Void
    @Environment(AppState.self) private var appState
    @Query(sort: \Server.sortOrder) private var servers: [Server]
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(servers) { s in
                    Button {
                        appState.currentServerID = s.id
                        onDone()
                    } label: {
                        ServerRow(server: s, isActive: s.id == appState.currentServerID, pendingCount: s.outboxOps.count)
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    showAdd = true
                } label: {
                    Label("Add Server", systemImage: SF.add)
                        .foregroundStyle(Palette.accent)
                }
            }
            .navigationTitle("Servers")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDone)
                }
            }
            .sheet(isPresented: $showAdd) {
                AddServerSheet(onDone: { showAdd = false })
            }
        }
        .presentationDetents([.medium, .large])
    }
}
