import Foundation

enum ServerProbe {
    struct Result {
        let url: URL
        let reachable: Bool
    }

    static func probe(urlString: String) async throws -> Result {
        guard var components = URLComponents(string: urlString) else { throw APIError.notBeaverServer }
        if components.scheme == nil { components.scheme = "https" }
        guard let url = components.url else { throw APIError.notBeaverServer }

        let probeURL = url.appendingPathComponent("api/auth")
        var req = URLRequest(url: probeURL)
        req.httpMethod = "GET"
        req.timeoutInterval = 10
        req.setValue("0", forHTTPHeaderField: "Content-Length")

        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 10
        let session = URLSession(configuration: cfg)

        do {
            let (_, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse else { throw APIError.notBeaverServer }
            // expected 401 (no cookie) or 200 (very unusual). either way = beaver.
            if http.statusCode == 401 || http.statusCode == 200 {
                return Result(url: url, reachable: true)
            }
            throw APIError.notBeaverServer
        } catch let e as URLError {
            if e.code == .serverCertificateUntrusted || e.code == .serverCertificateHasUnknownRoot {
                throw APIError.sslUntrusted
            }
            throw APIError.network(e)
        }
    }
}
