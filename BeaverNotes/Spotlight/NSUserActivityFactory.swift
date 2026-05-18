import Foundation

#if canImport(UIKit)
import UIKit
#endif

enum NSUserActivityFactory {
    static let messageActivityType = "com.webaweba.BeaverNotes.viewMessage"

    static func activity(for message: Message) -> NSUserActivity {
        let a = NSUserActivity(activityType: messageActivityType)
        a.title = message.content.components(separatedBy: .newlines).first ?? "Note"
        a.userInfo = [
            "serverID": message.server?.id.uuidString ?? "",
            "messageID": message.serverID ?? message.localID.uuidString,
        ]
        a.isEligibleForHandoff = true
        a.isEligibleForSearch = true
        #if os(iOS)
        a.isEligibleForPrediction = true
        #endif
        return a
    }
}
