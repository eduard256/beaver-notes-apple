import Foundation

// Lightweight background-session holder for very large uploads.
// Full integration (URLSessionDelegate, progress wiring to SwiftData) lives in
// the OutboxProcessor path; this is a placeholder for the dedicated background session
// that the system can resume independently of the app's lifecycle.
final class BackgroundUploads: NSObject, @unchecked Sendable {
    static let shared = BackgroundUploads()

    let session: URLSession

    override init() {
        let cfg = URLSessionConfiguration.background(withIdentifier: "com.webaweba.BeaverNotes.uploads")
        cfg.allowsCellularAccess = true
        cfg.sessionSendsLaunchEvents = true
        cfg.isDiscretionary = false
        let queue = OperationQueue()
        self.session = URLSession(configuration: cfg, delegate: nil, delegateQueue: queue)
        super.init()
    }
}
