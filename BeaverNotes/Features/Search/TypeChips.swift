import SwiftUI

struct TypeChips: View {
    @Binding var selected: String?

    private let types: [(String?, String)] = [
        (nil, "All"),
        ("text", "Text"),
        ("image", "Image"),
        ("video", "Video"),
        ("file", "File"),
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Space.s2) {
                ForEach(types, id: \.1) { item in
                    BeaverChip(text: item.1, active: selected == item.0) {
                        selected = item.0
                    }
                }
            }
        }
    }
}
