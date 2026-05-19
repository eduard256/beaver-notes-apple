import SwiftUI
import SwiftData

struct ServerEditorSheet: View {
    @Bindable var server: Server
    let onDone: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \Server.sortOrder) private var servers: [Server]

    @State private var newPassword: String = ""
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Name", text: $server.name)
                }
                Section("URL") {
                    TextField("https://…", text: $server.urlString)
                        #if os(iOS)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #endif
                }
                Section("Password") {
                    SecureField("Change password", text: $newPassword)
                    Text("Changing the password invalidates all sessions on the server.")
                        .font(.caption)
                        .foregroundStyle(Palette.textTertiary)
                }
                Section("Sync") {
                    Stepper(value: $server.pollingIntervalSeconds, in: 3...60) {
                        Text("Poll every \(server.pollingIntervalSeconds)s")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        HStack {
                            Image(systemName: SF.trash)
                            Text("Delete Server")
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                } footer: {
                    Text("Removes the server from this device. Notes on the server remain untouched. Local cached notes will also be deleted.")
                        .font(.caption)
                        .foregroundStyle(Palette.textTertiary)
                }
            }
            .navigationTitle("Edit Server")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDone() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !newPassword.isEmpty {
                            Keychain.savePassword(newPassword, forServer: server.id)
                        }
                        onDone()
                    }
                }
            }
            .confirmationDialog(
                "Delete \(server.name)?",
                isPresented: $confirmDelete,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { performDelete() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove the server, its locally cached notes, and saved password from this device. Notes on the server itself are not affected.")
            }
        }
    }

    private func performDelete() {
        let id = server.id
        Keychain.deletePassword(forServer: id)
        modelContext.delete(server)
        try? modelContext.save()

        if appState.currentServerID == id {
            appState.currentServerID = servers.first(where: { $0.id != id })?.id
        }
        onDone()
    }
}
