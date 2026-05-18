import Foundation
import SwiftData

@MainActor
@Observable
final class SyncCoordinatorRegistry {
    private var coordinators: [UUID: SyncCoordinator] = [:]
    var activeServerID: UUID?

    func coordinator(for server: Server, context: ModelContext) -> SyncCoordinator {
        if let existing = coordinators[server.id] { return existing }
        let c = SyncCoordinator(server: server, context: context)
        coordinators[server.id] = c
        return c
    }

    func startAll(servers: [Server], context: ModelContext) {
        for s in servers {
            let c = coordinator(for: s, context: context)
            let interval = (s.id == activeServerID) ? s.pollingIntervalSeconds : max(s.pollingIntervalSeconds, 60)
            c.start(intervalSeconds: interval)
        }
    }

    func stopAll() {
        for c in coordinators.values { c.stop() }
    }
}
