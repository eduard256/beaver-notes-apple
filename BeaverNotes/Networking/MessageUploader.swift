import Foundation

struct UploadFile {
    let localID: UUID
    let url: URL
    let filename: String
    let mimeType: String
    let size: Int64
}

enum UploadProgressEvent {
    case file(localID: UUID, progress: Double)
    case total(progress: Double)
}

final class MessageUploader: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    private let serverURL: URL
    private let cookieIdentifier: String
    private var session: URLSession!

    private struct Segment {
        let localID: UUID
        let bodyStart: Int64   // first byte of the file payload in the multipart stream
        let bodyEnd: Int64     // last byte (exclusive) of the file payload
        let size: Int64
    }

    private var segments: [Segment] = []
    private var totalBytes: Int64 = 0
    private var onProgress: ((UploadProgressEvent) -> Void)?
    private var continuation: CheckedContinuation<(Data, HTTPURLResponse), Error>?
    private var responseData = Data()
    private var responseHTTP: HTTPURLResponse?

    init(serverURL: URL, cookieIdentifier: String) {
        self.serverURL = serverURL
        self.cookieIdentifier = cookieIdentifier
        super.init()
        let cfg = URLSessionConfiguration.default
        cfg.httpCookieStorage = HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: cookieIdentifier)
        cfg.httpCookieAcceptPolicy = .always
        cfg.httpShouldSetCookies = true
        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
        cfg.timeoutIntervalForRequest = 60
        cfg.timeoutIntervalForResource = 3600
        self.session = URLSession(configuration: cfg, delegate: self, delegateQueue: nil)
    }

    deinit {
        session.invalidateAndCancel()
    }

    func uploadCreate(content: String, files: [UploadFile], onProgress: @escaping (UploadProgressEvent) -> Void) async throws -> MessageDTO {
        let boundary = "Boundary-" + UUID().uuidString
        let bodyURL = AppGroup.outboxFilesDir.appendingPathComponent("upload-\(UUID().uuidString).bin")
        FileManager.default.createFile(atPath: bodyURL.path, contents: nil)
        guard let handle = try? FileHandle(forWritingTo: bodyURL) else {
            throw APIError.invalidResponse
        }
        defer {
            try? handle.close()
            try? FileManager.default.removeItem(at: bodyURL)
        }

        var offset: Int64 = 0
        let lineBreak = "\r\n"

        func write(_ str: String) throws {
            guard let data = str.data(using: .utf8) else { return }
            try handle.write(contentsOf: data)
            offset += Int64(data.count)
        }

        try write("--\(boundary)\(lineBreak)")
        try write("Content-Disposition: form-data; name=\"content\"\(lineBreak)\(lineBreak)")
        try write("\(content)\(lineBreak)")

        var segments: [Segment] = []
        for f in files {
            try write("--\(boundary)\(lineBreak)")
            try write("Content-Disposition: form-data; name=\"files\"; filename=\"\(f.filename)\"\(lineBreak)")
            try write("Content-Type: \(f.mimeType)\(lineBreak)\(lineBreak)")

            let segStart = offset
            guard let src = try? FileHandle(forReadingFrom: f.url) else {
                throw APIError.invalidResponse
            }
            defer { try? src.close() }
            while true {
                let chunk = (try? src.read(upToCount: 64 * 1024)) ?? Data()
                if chunk.isEmpty { break }
                try handle.write(contentsOf: chunk)
                offset += Int64(chunk.count)
            }
            let segEnd = offset
            segments.append(Segment(localID: f.localID, bodyStart: segStart, bodyEnd: segEnd, size: max(0, segEnd - segStart)))
            try write(lineBreak)
        }
        try write("--\(boundary)--\(lineBreak)")
        try handle.close()

        let totalBytes = (try? FileManager.default.attributesOfItem(atPath: bodyURL.path)[.size] as? Int64) ?? 0

        var req = URLRequest(url: serverURL.appendingPathComponent("api/messages"))
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        req.setValue("\(totalBytes)", forHTTPHeaderField: "Content-Length")

        self.segments = segments
        self.totalBytes = totalBytes
        self.onProgress = onProgress
        self.responseData = Data()
        self.responseHTTP = nil

        let (data, http) = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<(Data, HTTPURLResponse), Error>) in
            self.continuation = cont
            let task = session.uploadTask(with: req, fromFile: bodyURL)
            task.resume()
        }

        switch http.statusCode {
        case 200...299:
            return try BeaverJSON.decoder.decode(MessageDTO.self, from: data)
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["error"]
            throw APIError.server(http.statusCode, msg)
        }
    }

    // MARK: - URLSessionTaskDelegate

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard totalBytes > 0 else { return }
        let total = Double(totalBytesSent) / Double(totalBytes)
        onProgress?(.total(progress: min(max(total, 0), 1)))

        for seg in segments {
            let p: Double
            if totalBytesSent <= seg.bodyStart {
                p = 0
            } else if totalBytesSent >= seg.bodyEnd {
                p = 1
            } else {
                let sent = Double(totalBytesSent - seg.bodyStart)
                p = sent / Double(max(seg.size, 1))
            }
            onProgress?(.file(localID: seg.localID, progress: p))
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        responseData.append(data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            if let urlErr = error as? URLError {
                if urlErr.code == .cancelled {
                    continuation?.resume(throwing: APIError.cancelled)
                } else if urlErr.code == .serverCertificateUntrusted || urlErr.code == .serverCertificateHasUnknownRoot {
                    continuation?.resume(throwing: APIError.sslUntrusted)
                } else {
                    continuation?.resume(throwing: APIError.network(urlErr))
                }
            } else {
                continuation?.resume(throwing: error)
            }
        } else if let http = task.response as? HTTPURLResponse {
            continuation?.resume(returning: (responseData, http))
        } else {
            continuation?.resume(throwing: APIError.invalidResponse)
        }
        continuation = nil
    }
}

extension MessageUploader: URLSessionDataDelegate {}
