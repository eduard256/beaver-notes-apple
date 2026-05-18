import SwiftUI
import SwiftData

struct ServerEditorSheet: View {
    let server: Server
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var urlString: String = ""
    @State private var password: String = ""
    @State private var error: String?
    @State private var working = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Server") {
                    TextField("Name", text: $name)
                    TextField("URL", text: $urlString)
                        #if os(iOS)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #endif
                    SecureField("Password (leave blank to keep)", text: $password)
                }
                if let error {
                    Section { Text(error).foregroundStyle(Palette.danger) }
                }
            }
            .navigationTitle("Edit server")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(working)
                }
            }
            .onAppear {
                name = server.name
                urlString = server.urlString
            }
        }
    }

    private func save() async {
        working = true
        defer { working = false }
        server.name = name
        server.urlString = urlString
        if !password.isEmpty {
            do {
                guard let url = server.url else { error = "Invalid URL"; return }
                let client = APIClient(serverURL: url, cookieIdentifier: server.cookieStorageIdentifier)
                try await client.login(password: password)
                Keychain.savePassword(password, forServer: server.id)
            } catch {
                self.error = error.localizedDescription
                return
            }
        }
        try? modelContext.save()
        dismiss()
    }
}
