import Foundation
import SwiftUI

// Lightweight regex-based highlighter for common code languages used in beaver notes.
// Returns an AttributedString that uses Palette tokens, so dark/light theme is automatic.
enum CodeHighlighter {
    static func highlight(_ code: String, language: String?) -> AttributedString {
        var attr = AttributedString(code)
        attr.font = .system(.callout, design: .monospaced)
        attr.foregroundColor = Palette.textPrimary

        let lang = language?.lowercased() ?? ""
        let rules = ruleSet(for: lang)

        for rule in rules {
            apply(rule, to: &attr, on: code)
        }
        return attr
    }

    private struct Rule {
        let pattern: String
        let color: Color
    }

    private static func ruleSet(for lang: String) -> [Rule] {
        switch lang {
        case "swift":
            return [
                Rule(pattern: #"\b(let|var|func|struct|class|enum|return|if|else|guard|while|for|in|switch|case|default|break|continue|do|try|catch|throw|throws|nil|true|false|public|private|internal|fileprivate|static|self|init|protocol|extension|async|await|actor|some|any|where|as|is|import)\b"#, color: .purple),
                Rule(pattern: #""[^"\\]*(?:\\.[^"\\]*)*""#, color: .green),
                Rule(pattern: #"//[^\n]*"#, color: .gray),
                Rule(pattern: #"\b\d+(\.\d+)?\b"#, color: .orange),
            ]
        case "go":
            return [
                Rule(pattern: #"\b(func|var|const|type|struct|interface|return|if|else|for|range|switch|case|default|break|continue|go|defer|chan|select|package|import|map|nil|true|false)\b"#, color: .purple),
                Rule(pattern: #""[^"\\]*(?:\\.[^"\\]*)*""#, color: .green),
                Rule(pattern: #"//[^\n]*"#, color: .gray),
                Rule(pattern: #"\b\d+(\.\d+)?\b"#, color: .orange),
            ]
        case "js", "javascript", "ts", "typescript":
            return [
                Rule(pattern: #"\b(const|let|var|function|return|if|else|for|while|do|switch|case|default|break|continue|class|new|this|null|undefined|true|false|async|await|import|from|export|default|interface|type|extends|implements)\b"#, color: .purple),
                Rule(pattern: #""[^"\\]*(?:\\.[^"\\]*)*"|'[^'\\]*(?:\\.[^'\\]*)*'"#, color: .green),
                Rule(pattern: #"//[^\n]*"#, color: .gray),
                Rule(pattern: #"\b\d+(\.\d+)?\b"#, color: .orange),
            ]
        case "json":
            return [
                Rule(pattern: #""[^"\\]*(?:\\.[^"\\]*)*""#, color: .green),
                Rule(pattern: #"\b(true|false|null)\b"#, color: .purple),
                Rule(pattern: #"-?\b\d+(\.\d+)?\b"#, color: .orange),
            ]
        case "bash", "sh":
            return [
                Rule(pattern: #"#[^\n]*"#, color: .gray),
                Rule(pattern: #""[^"\\]*(?:\\.[^"\\]*)*""#, color: .green),
                Rule(pattern: #"\$\w+"#, color: .orange),
            ]
        default:
            return []
        }
    }

    private static func apply(_ rule: Rule, to attr: inout AttributedString, on source: String) {
        guard let regex = try? NSRegularExpression(pattern: rule.pattern) else { return }
        let nsSource = source as NSString
        let matches = regex.matches(in: source, range: NSRange(location: 0, length: nsSource.length))
        for m in matches {
            let r = m.range
            guard let swiftRange = Range(r, in: source),
                  let attrRange = attr.range(of: source[swiftRange]) else { continue }
            attr[attrRange].foregroundColor = rule.color
        }
    }
}
