import Foundation

enum DeepLinkRouter {
    @MainActor
    static func handle(_ url: URL, appState: AppState) {
        guard url.scheme == "beavernotes" else { return }
        let parts = url.pathComponents.filter { $0 != "/" }
        let host = url.host

        if host == "message", let id = parts.first {
            appState.pendingMessageDeepLink = id
        } else if host == "server", let idString = parts.first, let uuid = UUID(uuidString: idString) {
            appState.switchTo(server: uuid)
        }
    }
}
