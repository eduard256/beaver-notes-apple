import Foundation
import SwiftData

enum BeaverModelContainer {
    static func make() throws -> ModelContainer {
        let schema = Schema([
            Server.self,
            Message.self,
            LocalFile.self,
            OutboxOp.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            url: AppGroup.databaseURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [config])
    }

    static func preview() throws -> ModelContainer {
        let schema = Schema([Server.self, Message.self, LocalFile.self, OutboxOp.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
