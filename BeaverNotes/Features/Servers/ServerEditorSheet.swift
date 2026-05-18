import SwiftUI

struct ServerEditorSheet: View {
    @Bindable var server: Server
    let onDone: () -> Void

    @State private var newPassword: String = ""

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
        }
    }
}
