import SwiftUI
import SwiftData

struct ServerEntryPage: View {
    let onDone: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var name = ""
    @State private var urlString = ""
    @State private var password = ""
    @State private var error: String?
    @State private var working = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s5) {
                VStack(alignment: .leading, spacing: Space.s2) {
                    Text("Connect your server")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Palette.textPrimary)
                    Text("Enter the URL of your Beaver Notes server.")
                        .font(.callout)
                        .foregroundStyle(Palette.textSecondary)
                }

                VStack(alignment: .leading, spacing: Space.s2) {
                    Text("Name").font(.caption).foregroundStyle(Palette.textSecondary)
                    TextField("My server", text: $name)
                        .beaverField()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #endif
                }
                VStack(alignment: .leading, spacing: Space.s2) {
                    Text("URL").font(.caption).foregroundStyle(Palette.textSecondary)
                    TextField("https://notes.example.com", text: $urlString)
                        .beaverField()
                        #if os(iOS)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #endif
                }
                VStack(alignment: .leading, spacing: Space.s2) {
                    Text("Password").font(.caption).foregroundStyle(Palette.textSecondary)
                    SecureField("••••••••", text: $password)
                        .beaverField()
                }

                if let error {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(Palette.danger)
                }

                Button {
                    Task { await connect() }
                } label: {
                    HStack {
                        if working { ProgressView().tint(Palette.bgPrimary) }
                        Text(working ? "Connecting…" : "Connect")
                    }
                }
                .buttonStyle(.beaverPrimary)
                .disabled(working || urlString.isEmpty || password.isEmpty)

                Spacer(minLength: Space.s8)
            }
            .padding(Space.s5)
        }
        .background(Palette.bgPrimary)
    }

    private func connect() async {
        working = true
        error = nil
        defer { working = false }
        do {
            let result = try await ServerProbe.probe(urlString: urlString)
            let server = Server(
                name: name.trimmingCharacters(in: .whitespaces).isEmpty ? result.url.host ?? "Server" : name,
                urlString: result.url.absoluteString,
                sortOrder: 0
            )
            modelContext.insert(server)
            try modelContext.save()

            let client = APIClient(serverURL: result.url, cookieIdentifier: server.cookieStorageIdentifier)
            try await client.login(password: password)

            Keychain.savePassword(password, forServer: server.id)
            appState.currentServerID = server.id
            Haptics.success()
            onDone()
        } catch APIError.unauthorized {
            error = "Wrong password."
        } catch APIError.sslUntrusted {
            error = "Server certificate is not trusted."
        } catch APIError.notBeaverServer {
            error = "Not a Beaver Notes server."
        } catch let e {
            error = e.localizedDescription
        }
    }
}
