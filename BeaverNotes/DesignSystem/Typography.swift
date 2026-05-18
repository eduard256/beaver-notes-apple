import SwiftUI

enum Typography {
    static let title    = Font.title2.weight(.semibold)
    static let body     = Font.body
    static let callout  = Font.callout
    static let caption  = Font.caption
    static let micro    = Font.caption2
    static let mono     = Font.system(.callout, design: .monospaced)
    static let monoSmall = Font.system(.caption, design: .monospaced)
}
