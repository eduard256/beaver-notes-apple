import SwiftUI

struct MessageTags: View {
    let tags: [String]

    var body: some View {
        if !tags.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Space.s2) {
                    ForEach(tags, id: \.self) { tag in
                        BeaverChip(text: "#\(tag)")
                    }
                }
            }
        }
    }
}
