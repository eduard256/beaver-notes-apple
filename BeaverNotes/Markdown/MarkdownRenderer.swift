import Foundation
import SwiftUI

enum MarkdownBlock: Identifiable {
    case paragraph(AttributedString)
    case heading(level: Int, AttributedString)
    case codeBlock(language: String?, code: String)
    case bullet(AttributedString)
    case blockquote(AttributedString)
    case rule

    var id: UUID { UUID() }
}

enum MarkdownRenderer {
    // Splits content into blocks. Code fences are extracted as raw, the rest is
    // rendered via AttributedString(markdown:) so inline formatting just works.
    static func parse(_ raw: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var inCode = false
        var codeLang: String?
        var codeLines: [String] = []
        var paraLines: [String] = []

        func flushParagraph() {
            guard !paraLines.isEmpty else { return }
            let text = paraLines.joined(separator: "\n")
            paraLines.removeAll()
            blocks.append(contentsOf: renderInlineBlock(text))
        }

        for line in raw.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") {
                if inCode {
                    blocks.append(.codeBlock(language: codeLang, code: codeLines.joined(separator: "\n")))
                    codeLines.removeAll()
                    codeLang = nil
                    inCode = false
                } else {
                    flushParagraph()
                    codeLang = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    if codeLang?.isEmpty == true { codeLang = nil }
                    inCode = true
                }
                continue
            }

            if inCode {
                codeLines.append(line)
                continue
            }

            paraLines.append(line)
        }
        flushParagraph()
        if inCode, !codeLines.isEmpty {
            blocks.append(.codeBlock(language: codeLang, code: codeLines.joined(separator: "\n")))
        }
        return blocks
    }

    private static func renderInlineBlock(_ text: String) -> [MarkdownBlock] {
        var out: [MarkdownBlock] = []
        var paragraph = ""

        func flush() {
            let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                let attr = (try? AttributedString(markdown: trimmed, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
                    ?? AttributedString(trimmed)
                out.append(.paragraph(attr))
            }
            paragraph = ""
        }

        for line in text.components(separatedBy: "\n") {
            let s = line.trimmingCharacters(in: .whitespaces)
            if s.hasPrefix("# ") {
                flush()
                out.append(.heading(level: 1, attributed(String(s.dropFirst(2)))))
            } else if s.hasPrefix("## ") {
                flush()
                out.append(.heading(level: 2, attributed(String(s.dropFirst(3)))))
            } else if s.hasPrefix("### ") {
                flush()
                out.append(.heading(level: 3, attributed(String(s.dropFirst(4)))))
            } else if s.hasPrefix("- ") || s.hasPrefix("* ") {
                flush()
                out.append(.bullet(attributed(String(s.dropFirst(2)))))
            } else if s.hasPrefix("> ") {
                flush()
                out.append(.blockquote(attributed(String(s.dropFirst(2)))))
            } else if s == "---" || s == "***" {
                flush()
                out.append(.rule)
            } else if s.isEmpty {
                flush()
            } else {
                if !paragraph.isEmpty { paragraph += "\n" }
                paragraph += line
            }
        }
        flush()
        return out
    }

    private static func attributed(_ s: String) -> AttributedString {
        (try? AttributedString(markdown: s, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(s)
    }
}

// Extract hashtags from text (mirrors backend `extractTags` for local Spotlight indexing).
enum HashtagExtractor {
    static func extract(from content: String) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for w in content.split(whereSeparator: { $0.isWhitespace || $0.isNewline }) {
            guard w.hasPrefix("#"), w.count > 1 else { continue }
            let cleaned = w.dropFirst().lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".,;:!?"))
            if !cleaned.isEmpty, seen.insert(cleaned).inserted {
                out.append(cleaned)
            }
        }
        return out
    }
}
