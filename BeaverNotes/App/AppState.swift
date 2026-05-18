import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    var currentServerID: UUID?
    var currentFolder: WallFolder? = .all
    var isLocked: Bool = false
    var globalError: String?
    var pendingMessageDeepLink: String?
    var activeSearch: MessageQuery?

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
