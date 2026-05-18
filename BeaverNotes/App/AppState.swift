import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    var currentServerID: UUID?
    var isLocked: Bool = false
    var globalError: String?
    var pendingMessageDeepLink: String?

    func switchTo(server id: UUID) {
        currentServerID = id
    }

    func presentError(_ message: String) {
        globalError = message
    }

    func dismissError() {
        globalError = nil
    }
}
