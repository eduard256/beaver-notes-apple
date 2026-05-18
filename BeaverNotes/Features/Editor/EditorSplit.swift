import SwiftUI

struct EditorSplit: View {
    @Binding var content: String

    var body: some View {
        HStack(spacing: 0) {
            EditorTextView(text: $content)
                .frame(maxWidth: .infinity)
            Divider()
            ScrollView {
                EditorPreview(content: content).padding(Space.s4)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
