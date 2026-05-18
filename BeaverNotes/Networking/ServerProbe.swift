import Foundation

enum ServerProbe {
    struct Result {
        let url: URL
    }

    static func probe(urlString: String) async throws -> Result {
        let url = try parseURL(urlString)

        let probeURL = url.appendingPathComponent("api/auth")
        var req = URLRequest(url: probeURL)
        req.httpMethod = "GET"
        req.timeoutInterval = 10

        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 10
        cfg.timeoutIntervalForResource = 10
        let session = URLSession(configuration: cfg)

        do {
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse else { throw APIError.notBeaverServer }

            // Beaver returns 401 with JSON body {"error":"unauthorized"} (or "no session cookie")
            // when no valid cookie is supplied. Status alone is not enough — many servers
            // return 401 for unrelated reasons, so verify the JSON shape.
            guard http.statusCode == 401 else { throw APIError.notBeaverServer }
            guard let payload = try? JSONDecoder().decode([String: String].self, from: data),
                  payload["error"] != nil else {
                throw APIError.notBeaverServer
            }
            return Result(url: url)
        } catch let e as APIError {
            throw e
        } catch let e as URLError {
            switch e.code {
            case .serverCertificateUntrusted, .serverCertificateHasUnknownRoot, .secureConnectionFailed:
                throw APIError.sslUntrusted
            case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                throw APIError.notBeaverServer
            default:
                throw APIError.network(e)
            }
        }
    }

    private static func parseURL(_ s: String) throws -> URL {
        var raw = s.trimmingCharacters(in: .whitespaces)
        if raw.isEmpty { throw APIError.notBeaverServer }

        // Auto-prefix scheme when missing
        if !raw.contains("://") { raw = "https://" + raw }

        guard var components = URLComponents(string: raw) else { throw APIError.notBeaverServer }
        guard let scheme = components.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            throw APIError.notBeaverServer
        }
        components.scheme = scheme
        guard let host = components.host, !host.isEmpty, host.contains(".") || host == "localhost" || isIP(host) else {
            throw APIError.notBeaverServer
        }
        // Strip trailing slash from path
        if components.path == "/" { components.path = "" }
        guard let url = components.url else { throw APIError.notBeaverServer }
        return url
    }

    private static func isIP(_ host: String) -> Bool {
        var sin = sockaddr_in()
        var sin6 = sockaddr_in6()
        return host.withCString { inet_pton(AF_INET, $0, &sin.sin_addr) == 1 || inet_pton(AF_INET6, $0, &sin6.sin6_addr) == 1 }
    }
}
