import Foundation

enum APIError: Error, LocalizedError {
    case unauthorized
    case notFound
    case network(URLError)
    case server(Int, String?)
    case invalidResponse
    case cancelled
    case sslUntrusted
    case notBeaverServer

    var errorDescription: String? {
        switch self {
        case .unauthorized:    return "Unauthorized. Check your password."
        case .notFound:        return "Not found."
        case .network(let e):  return "Network error: \(e.localizedDescription)"
        case .server(let s, let msg): return "Server \(s): \(msg ?? "no message")"
        case .invalidResponse: return "Unexpected server response."
        case .cancelled:       return "Request cancelled."
        case .sslUntrusted:    return "Server certificate is not trusted."
        case .notBeaverServer: return "This URL does not look like a Beaver server."
        }
    }
}
