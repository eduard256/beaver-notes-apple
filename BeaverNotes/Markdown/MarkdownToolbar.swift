import Foundation

enum MarkdownAction {
    case bold, italic, code, codeBlock, heading, list, link, hr
}

// Helpers for inserting markdown markers at a TextView cursor / selection.
// Returns the new (text, cursorPosition) so the caller can apply it.
enum MarkdownToolbar {
    static func apply(_ action: MarkdownAction, text: String, selection: Range<String.Index>) -> (String, String.Index) {
        switch action {
        case .bold:      return wrap(text: text, selection: selection, with: "**")
        case .italic:    return wrap(text: text, selection: selection, with: "*")
        case .code:      return wrap(text: text, selection: selection, with: "`")
        case .codeBlock: return insert(text: text, at: selection.lowerBound, prefix: "\n```\n", suffix: "\n```\n")
        case .heading:   return insert(text: text, at: selection.lowerBound, prefix: "## ", suffix: "")
        case .list:      return insert(text: text, at: selection.lowerBound, prefix: "- ", suffix: "")
        case .link:      return insert(text: text, at: selection.lowerBound, prefix: "[", suffix: "](url)")
        case .hr:        return insert(text: text, at: selection.lowerBound, prefix: "\n---\n", suffix: "")
        }
    }

    private static func wrap(text: String, selection: Range<String.Index>, with marker: String) -> (String, String.Index) {
        var t = text
        let selected = String(t[selection])
        t.replaceSubrange(selection, with: "\(marker)\(selected)\(marker)")
        let newCursor = t.index(t.startIndex, offsetBy: t.distance(from: t.startIndex, to: selection.lowerBound) + marker.count + selected.count)
        return (t, newCursor)
    }

    private static func insert(text: String, at index: String.Index, prefix: String, suffix: String) -> (String, String.Index) {
        var t = text
        t.insert(contentsOf: prefix + suffix, at: index)
        let newCursor = t.index(index, offsetBy: prefix.count)
        return (t, newCursor)
    }
}
