import SwiftUI

struct AttachmentBar: View {
    let attachments: [PendingAttachment]
    let onRemove: (PendingAttachment) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Space.s2) {
                ForEach(attachments) { a in
                    AttachmentChip(name: a.filename) { onRemove(a) }
                }
            }
            .padding(.horizontal, Space.s4)
        }
        .frame(height: 32)
    }
}

struct PendingAttachment: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let filename: String
    let mimeType: String
    let size: Int64
}
