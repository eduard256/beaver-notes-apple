import Foundation

struct MessageDTO: Codable, Sendable {
    let id: String
    let content: String
    let pinned: Bool
    let created_at: Date
    let updated_at: Date
    let deleted_at: Date?
    let files: [FileDTO]?
    let tags: [String]?
}

struct FileDTO: Codable, Sendable {
    let id: String
    let message_id: String
    let filename: String
    let mime_type: String
    let size: Int64
    let created_at: Date
}

struct MessagesResponseDTO: Codable, Sendable {
    let messages: [MessageDTO]
    let total: Int
    let has_more: Bool
}

struct MessageQuery: Sendable {
    var search: String?
    var type: String?
    var dateFrom: String?
    var dateTo: String?
    var tag: String?
    var pinned: Bool?
    var offset: Int = 0
    var limit: Int = 50

    nonisolated func queryItems(since: Date?) -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let search { items.append(.init(name: "search", value: search)) }
        if let type   { items.append(.init(name: "type", value: type)) }
        if let dateFrom { items.append(.init(name: "date_from", value: dateFrom)) }
        if let dateTo   { items.append(.init(name: "date_to", value: dateTo)) }
        if let tag    { items.append(.init(name: "tag", value: tag)) }
        if let pinned { items.append(.init(name: "pinned", value: pinned ? "true" : "false")) }
        items.append(.init(name: "offset", value: String(offset)))
        items.append(.init(name: "limit", value: String(limit)))
        if let since {
            items.append(.init(name: "since", value: ISO8601DateFormatter.beaver.string(from: since)))
        }
        return items
    }
}

extension ISO8601DateFormatter {
    nonisolated(unsafe) static let beaver: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}

enum BeaverJSON {
    nonisolated static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let s = try decoder.singleValueContainer().decode(String.self)
            if let date = ISO8601DateFormatter.beaver.date(from: s) { return date }
            let plain = ISO8601DateFormatter()
            plain.formatOptions = [.withInternetDateTime]
            if let date = plain.date(from: s) { return date }
            throw DecodingError.dataCorruptedError(in: try decoder.singleValueContainer(), debugDescription: "Bad date: \(s)")
        }
        return d
    }()

    nonisolated static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .custom { date, encoder in
            var c = encoder.singleValueContainer()
            try c.encode(ISO8601DateFormatter.beaver.string(from: date))
        }
        return e
    }()
}
