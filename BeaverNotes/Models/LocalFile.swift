import Foundation
import SwiftData

@Model
final class LocalFile {
    @Attribute(.unique) var localID: UUID
    var serverID: String?
    var filename: String
    var mimeType: String
    var size: Int64
    var localPath: String?
    var sourcePath: String?
    var transferStateRaw: String
    var bytesTransferred: Int64
    var pixelWidth: Int?
    var pixelHeight: Int?

    init(
        localID: UUID = UUID(),
        serverID: String? = nil,
        filename: String,
        mimeType: String,
        size: Int64,
        localPath: String? = nil,
        sourcePath: String? = nil,
        transferState: TransferState = .none
    ) {
        self.localID = localID
        self.serverID = serverID
        self.filename = filename
        self.mimeType = mimeType
        self.size = size
        self.localPath = localPath
        self.sourcePath = sourcePath
        self.bytesTransferred = 0
        self.transferStateRaw = transferState.rawValue
    }

    var transferState: TransferState {
        get { TransferState(rawValue: transferStateRaw) ?? .none }
        set { transferStateRaw = newValue.rawValue }
    }

    var isImage: Bool { mimeType.hasPrefix("image/") }
    var isVideo: Bool { mimeType.hasPrefix("video/") }
}
