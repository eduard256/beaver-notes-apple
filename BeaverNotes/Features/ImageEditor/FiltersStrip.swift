import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct FiltersStrip: View {
    let sourceURL: URL
    @Binding var selected: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Space.s2) {
                ForEach(ImageFilters.presets, id: \.name) { p in
                    Button {
                        selected = p.key
                    } label: {
                        VStack(spacing: Space.s1) {
                            thumb(for: p.key)
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Radius.sm)
                                        .stroke(selected == p.key ? Palette.accent : Palette.borderSecondary, lineWidth: selected == p.key ? 2 : 1)
                                )
                            Text(p.name)
                                .font(.caption2)
                                .foregroundStyle(Palette.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Space.s3)
            .padding(.vertical, Space.s2)
        }
        .background(Palette.bgSecondary)
    }

    @ViewBuilder
    private func thumb(for key: String?) -> some View {
        #if canImport(UIKit)
        if let img = UIImage(contentsOfFile: sourceURL.path) {
            Image(uiImage: img).resizable().scaledToFill()
        } else { Palette.bgTertiary }
        #elseif canImport(AppKit)
        if let img = NSImage(contentsOfFile: sourceURL.path) {
            Image(nsImage: img).resizable().scaledToFill()
        } else { Palette.bgTertiary }
        #else
        Palette.bgTertiary
        #endif
    }
}
