import Foundation
import SwiftData
import CoreSpotlight

@MainActor
enum LocalDataEraser {
    static func eraseEverything(
        context: ModelContext,
        registry: SyncCoordinatorRegistry,
        appState: AppState
    ) async {
        registry.stopAll()

        Keychain.deleteAll()

        try? context.delete(model: Message.self)
        try? context.delete(model: LocalFile.self)
        try? context.delete(model: OutboxOp.self)
        try? context.delete(model: Server.self)
        try? context.save()

        await FileCache.shared.clear()
        clearOutboxFiles()

        let groupCookies = HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: AppGroup.identifier)
        for cookie in groupCookies.cookies ?? [] {
            groupCookies.deleteCookie(cookie)
        }
        for cookie in HTTPCookieStorage.shared.cookies ?? [] {
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }

        URLCache.shared.removeAllCachedResponses()

        clearUserDefaults()

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            CSSearchableIndex.default().deleteAllSearchableItems { _ in cont.resume() }
        }

        appState.currentServerID = nil
        appState.currentFolder = .all
        appState.isLocked = false
        appState.globalError = nil
        appState.pendingMessageDeepLink = nil
        appState.activeSearch = nil
    }

    private static func clearOutboxFiles() {
        let fm = FileManager.default
        let dir = AppGroup.outboxFilesDir
        if let items = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
            for url in items {
                try? fm.removeItem(at: url)
            }
        }
    }

    private static func clearUserDefaults() {
        let defaults = AppGroup.userDefaults
        let domain = defaults.dictionaryRepresentation()
        for key in domain.keys {
            defaults.removeObject(forKey: key)
        }
    }
}
