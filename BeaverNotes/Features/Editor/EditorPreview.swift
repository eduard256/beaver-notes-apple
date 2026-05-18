import SwiftUI

struct EditorPreview: View {
    let content: String

    var body: some View {
        MessageBody(content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
