import Foundation

actor APIClient {
    let serverURL: URL
    private let session: URLSession
    private let cookieStorage: HTTPCookieStorage

    init(serverURL: URL, cookieIdentifier: String) {
        self.serverURL = serverURL
        let storage = HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: cookieIdentifier)
        self.cookieStorage = storage

        let cfg = URLSessionConfiguration.default
        cfg.httpCookieStorage = storage
        cfg.httpCookieAcceptPolicy = .always
        cfg.httpShouldSetCookies = true
        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
        cfg.timeoutIntervalForRequest = 30
        cfg.timeoutIntervalForResource = 600
        self.session = URLSession(configuration: cfg)
    }

    // MARK: - Auth

    func login(password: String) async throws {
        var req = request("/api/auth", method: "POST")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(["password": password])
        _ = try await send(req)
    }

    func checkAuth() async throws -> Bool {
        let req = request("/api/auth", method: "GET")
        do {
            _ = try await send(req)
            return true
        } catch APIError.unauthorized {
            return false
        }
    }

    // MARK: - Messages

    struct MessagesPullResult {
        let response: MessagesResponseDTO?  // nil when 304
        let etag: String?
        let notModified: Bool
    }

    func fetchMessages(query: MessageQuery, since: Date?, ifNoneMatch: String?) async throws -> MessagesPullResult {
        var components = URLComponents(url: serverURL.appendingPathComponent("api/messages"), resolvingAgainstBaseURL: false)!
        components.queryItems = query.queryItems(since: since)
        var req = URLRequest(url: components.url!)
        req.httpMethod = "GET"
        if let etag = ifNoneMatch {
            req.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        let (data, response) = try await rawSend(req)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }

        if http.statusCode == 304 {
            return MessagesPullResult(response: nil, etag: ifNoneMatch, notModified: true)
        }
        try validate(http: http, data: data)

        let etag = http.value(forHTTPHeaderField: "ETag")
        let decoded = try BeaverJSON.decoder.decode(MessagesResponseDTO.self, from: data)
        return MessagesPullResult(response: decoded, etag: etag, notModified: false)
    }

    func createMessage(content: String) async throws -> MessageDTO {
        var req = request("/api/messages", method: "POST")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(["content": content])
        let (data, _) = try await send(req)
        return try BeaverJSON.decoder.decode(MessageDTO.self, from: data)
    }

    func createMessage(content: String, fileURLs: [URL]) async throws -> MessageDTO {
        let boundary = "Boundary-" + UUID().uuidString
        var req = request("/api/messages", method: "POST")
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let lineBreak = "\r\n"
        body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"content\"\(lineBreak)\(lineBreak)".data(using: .utf8)!)
        body.append("\(content)\(lineBreak)".data(using: .utf8)!)

        for url in fileURLs {
            let data = try Data(contentsOf: url)
            let filename = url.lastPathComponent
            let mime = mimeType(for: url.pathExtension)
            body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(filename)\"\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Type: \(mime)\(lineBreak)\(lineBreak)".data(using: .utf8)!)
            body.append(data)
            body.append(lineBreak.data(using: .utf8)!)
        }
        body.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)
        req.httpBody = body

        let (data, _) = try await send(req)
        return try BeaverJSON.decoder.decode(MessageDTO.self, from: data)
    }

    func editMessage(serverID: String, content: String) async throws -> MessageDTO {
        var req = request("/api/messages/\(serverID)?action=edit", method: "PATCH")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(["content": content])
        let (data, _) = try await send(req)
        return try BeaverJSON.decoder.decode(MessageDTO.self, from: data)
    }

    func setPinned(serverID: String, pinned: Bool) async throws -> MessageDTO {
        let action = pinned ? "pin" : "unpin"
        let req = request("/api/messages/\(serverID)?action=\(action)", method: "PATCH")
        let (data, _) = try await send(req)
        return try BeaverJSON.decoder.decode(MessageDTO.self, from: data)
    }

    func deleteMessage(serverID: String) async throws {
        let req = request("/api/messages/\(serverID)?action=delete", method: "PATCH")
        _ = try await send(req)
    }

    func deleteFile(serverID: String) async throws {
        let req = request("/api/files/\(serverID)", method: "DELETE")
        _ = try await send(req)
    }

    // MARK: - File download

    func downloadFile(serverID: String, to dst: URL) async throws {
        let url = serverURL.appendingPathComponent("api/files/\(serverID)")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let (tmp, response) = try await session.download(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        if http.statusCode == 401 { throw APIError.unauthorized }
        if !(200...299).contains(http.statusCode) { throw APIError.server(http.statusCode, nil) }
        if FileManager.default.fileExists(atPath: dst.path) {
            try FileManager.default.removeItem(at: dst)
        }
        try FileManager.default.moveItem(at: tmp, to: dst)
    }

    // MARK: - internals

    private func request(_ path: String, method: String) -> URLRequest {
        let url = serverURL.appendingPathComponent(path.hasPrefix("/") ? String(path.dropFirst()) : path)
        var req = URLRequest(url: url)
        req.httpMethod = method
        return req
    }

    private func send(_ req: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await rawSend(req)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        try validate(http: http, data: data)
        return (data, http)
    }

    private func rawSend(_ req: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: req)
        } catch let e as URLError {
            if e.code == .cancelled { throw APIError.cancelled }
            if e.code == .serverCertificateUntrusted || e.code == .serverCertificateHasUnknownRoot {
                throw APIError.sslUntrusted
            }
            throw APIError.network(e)
        }
    }

    private func validate(http: HTTPURLResponse, data: Data) throws {
        switch http.statusCode {
        case 200...299: return
        case 401: throw APIError.unauthorized
        case 404: throw APIError.notFound
        default:
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["error"]
            throw APIError.server(http.statusCode, msg)
        }
    }

    private func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "jpg", "jpeg": return "image/jpeg"
        case "png":  return "image/png"
        case "gif":  return "image/gif"
        case "webp": return "image/webp"
        case "heic": return "image/heic"
        case "mp4":  return "video/mp4"
        case "mov":  return "video/quicktime"
        case "webm": return "video/webm"
        case "pdf":  return "application/pdf"
        case "zip":  return "application/zip"
        case "txt":  return "text/plain"
        case "md":   return "text/markdown"
        default:     return "application/octet-stream"
        }
    }
}
