import Foundation
import SwiftData

@MainActor
@Observable
final class SyncCoordinator {
    let server: Server
    let client: APIClient
    private let context: ModelContext
    private var loopTask: Task<Void, Never>?
    private(set) var isPulling: Bool = false

    init(server: Server, context: ModelContext) {
        self.server = server
        self.context = context
        guard let url = server.url else {
            self.client = APIClient(serverURL: URL(string: "http://invalid")!, cookieIdentifier: server.cookieStorageIdentifier)
            return
        }
        self.client = APIClient(serverURL: url, cookieIdentifier: server.cookieStorageIdentifier)
    }

    func start(intervalSeconds: Int? = nil) {
        stop()
        let interval = TimeInterval(intervalSeconds ?? server.pollingIntervalSeconds)
        loopTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.tickOnce()
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }

    func stop() {
        loopTask?.cancel()
        loopTask = nil
    }

    func triggerImmediatePull() async {
        await tickOnce()
    }

    private func tickOnce() async {
        isPulling = true
        defer { isPulling = false }
        await OutboxProcessor.processOnce(server: server, client: client, context: context)
        await PullEngine.pull(server: server, client: client, context: context)
    }
}
