import SwiftUI

struct AttachmentBar: View {
    let attachments: [PendingAttachment]
    let onRemove: (PendingAttachment) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Space.s2) {
                ForEach(attachments) { att in
                    AttachmentChip(attachment: att) { onRemove(att) }
                }
            }
            .padding(.horizontal, Space.s3)
            .padding(.vertical, Space.s2)
        }
    }
}
