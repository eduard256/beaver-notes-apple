import SwiftUI

struct ServerEntryPage: View {
    let onCancel: () -> Void
    let onSuccess: (Server, String) -> Void

    @State private var name: String = "My Server"
    @State private var urlString: String = "https://"
    @State private var password: String = ""
    @State private var status: Status = .idle
    @FocusState private var focused: Field?

    enum Field: Hashable { case name, url, password }
    enum Status: Equatable {
        case idle
        case probing
        case loggingIn
        case error(String)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s5) {
            HStack {
                Button(action: onCancel) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .foregroundStyle(Palette.textSecondary)
                Spacer()
            }
            .padding(.bottom, Space.s4)

            Text("Add Server")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Palette.textPrimary)

            Text("Enter the URL of your self-hosted Beaver server, then your password.")
                .font(Typography.callout)
                .foregroundStyle(Palette.textSecondary)

            VStack(alignment: .leading, spacing: Space.s2) {
                Text("Name").font(.caption.weight(.medium)).foregroundStyle(Palette.textTertiary).textCase(.uppercase)
                TextField("Home server", text: $name)
                    .beaverField()
                    .focused($focused, equals: .name)
                    .submitLabel(.next)
                    .onSubmit { focused = .url }
                    #if os(iOS)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    #endif
            }

            VStack(alignment: .leading, spacing: Space.s2) {
                Text("Server URL").font(.caption.weight(.medium)).foregroundStyle(Palette.textTertiary).textCase(.uppercase)
                TextField("https://notes.example.com", text: $urlString)
                    .beaverField(hasError: isError)
                    .focused($focused, equals: .url)
                    .submitLabel(.next)
                    .onSubmit { focused = .password }
                    #if os(iOS)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    #endif
            }

            VStack(alignment: .leading, spacing: Space.s2) {
                Text("Password").font(.caption.weight(.medium)).foregroundStyle(Palette.textTertiary).textCase(.uppercase)
                SecureField("•••••••", text: $password)
                    .beaverField(hasError: isError)
                    .focused($focused, equals: .password)
                    .submitLabel(.go)
                    .onSubmit { connect() }
            }

            if case .error(let msg) = status {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(Palette.danger)
            }

            Spacer()

            Button(action: connect) {
                HStack {
                    if status == .probing || status == .loggingIn {
                        ProgressView().tint(Palette.bgPrimary)
                        Text(status == .probing ? "Checking…" : "Signing in…")
                    } else {
                        Text("Connect")
                    }
                }
            }
            .buttonStyle(.beaverPrimary)
            .disabled(!canConnect)
        }
        .padding(Space.s5)
        .frame(maxWidth: 520)
        .frame(maxHeight: .infinity)
        .onAppear { focused = .url }
    }

    private var canConnect: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !urlString.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty &&
        status != .probing && status != .loggingIn
    }

    private var isError: Bool {
        if case .error = status { return true } else { return false }
    }

    private func connect() {
        guard canConnect else { return }
        status = .probing
        let trimmedURL = urlString.trimmingCharacters(in: .whitespaces)
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let pass = password

        Task {
            do {
                let probe = try await ServerProbe.probe(urlString: trimmedURL)
                let server = Server(name: trimmedName, urlString: probe.url.absoluteString)
                status = .loggingIn

                let client = APIClient(serverURL: probe.url, cookieIdentifier: server.cookieStorageIdentifier)
                try await client.login(password: pass)

                onSuccess(server, pass)
            } catch let e as APIError {
                status = .error(e.errorDescription ?? "Connection failed")
            } catch {
                status = .error(error.localizedDescription)
            }
        }
    }
}
