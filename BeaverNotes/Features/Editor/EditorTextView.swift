import SwiftUI

#if canImport(UIKit)
import UIKit

struct EditorTextView: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextView {
        let v = UITextView()
        v.font = .preferredFont(forTextStyle: .body)
        v.backgroundColor = .clear
        v.text = text
        v.delegate = context.coordinator
        v.autocapitalizationType = .sentences
        return v
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text { uiView.text = text }
    }

    func makeCoordinator() -> Coord { Coord(self) }

    final class Coord: NSObject, UITextViewDelegate {
        var parent: EditorTextView
        init(_ p: EditorTextView) { parent = p }
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}

#elseif canImport(AppKit)
import AppKit

struct EditorTextView: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSTextView.scrollableTextView()
        if let tv = scroll.documentView as? NSTextView {
            tv.font = .systemFont(ofSize: NSFont.systemFontSize)
            tv.delegate = context.coordinator
            tv.isRichText = false
            tv.string = text
            tv.allowsUndo = true
            tv.backgroundColor = .clear
            tv.drawsBackground = false
        }
        scroll.drawsBackground = false
        return scroll
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let tv = nsView.documentView as? NSTextView, tv.string != text {
            tv.string = text
        }
    }

    func makeCoordinator() -> Coord { Coord(self) }

    final class Coord: NSObject, NSTextViewDelegate {
        var parent: EditorTextView
        init(_ p: EditorTextView) { parent = p }
        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.text = tv.string
        }
    }
}
#endif
