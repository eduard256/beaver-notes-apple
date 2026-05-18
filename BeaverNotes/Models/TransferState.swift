import Foundation

enum TransferState: String, Codable, CaseIterable {
    case none
    case queued
    case transferring
    case done
    case failed
}
