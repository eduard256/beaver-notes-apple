import Foundation
import CoreSpotlight
import UniformTypeIdentifiers

enum SpotlightIndexer {
    static func reindex(messages: [Message]) {
        let items = messages.compactMap(buildItem)
        let index = CSSearchableIndex.default()
        index.indexSearchableItems(items)
    }

    static func update(message: Message) {
        guard let item = buildItem(message) else { return }
        CSSearchableIndex.default().indexSearchableItems([item])
    }

    static func remove(message: Message) {
        let id = identifier(message)
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [id])
    }

    static func removeAll() {
        CSSearchableIndex.default().deleteAllSearchableItems()
    }

    private static func identifier(_ message: Message) -> String {
        let serverID = message.server?.id.uuidString ?? "unknown"
        let localOrServer = message.serverID ?? message.localID.uuidString
        return "message:\(serverID):\(localOrServer)"
    }

    private static func buildItem(_ message: Message) -> CSSearchableItem? {
        guard message.deletedAt == nil else { return nil }
        let attrs = CSSearchableItemAttributeSet(contentType: UTType.text)
        let firstLine = message.content.components(separatedBy: .newlines).first ?? message.content
        attrs.title = firstLine.isEmpty ? "Note" : String(firstLine.prefix(80))
        attrs.contentDescription = String(message.content.prefix(400))
        attrs.keywords = message.tags
        attrs.contentCreationDate = message.createdAt
        attrs.contentModificationDate = message.updatedAt
        return CSSearchableItem(
            uniqueIdentifier: identifier(message),
            domainIdentifier: "com.webaweba.BeaverNotes.messages",
            attributeSet: attrs
        )
    }
}
