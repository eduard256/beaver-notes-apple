import SwiftUI
import CoreImage

struct FiltersStrip: View {
    let original: PlatformImageBridge
    @Binding var selectedKey: String?

    init(original: PlatformImageBridge, selectedKey: Binding<String?>) {
        self.original = original
        self._selectedKey = selectedKey
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Space.s2) {
                ForEach(ImageFilters.presets, id: \.name) { preset in
                    Button {
                        selectedKey = preset.key
                    } label: {
                        VStack(spacing: 4) {
                            preview(preset.key)
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Radius.sm)
                                        .stroke(isActive(preset.key) ? Palette.accent : .clear, lineWidth: 2)
                                )
                            Text(preset.name).font(.caption2)
                                .foregroundStyle(Palette.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Space.s4)
        }
        .frame(height: 86)
    }

    private func isActive(_ key: String?) -> Bool { selectedKey == key }

    @ViewBuilder
    private func preview(_ key: String?) -> some View {
        #if canImport(UIKit)
        Image(uiImage: original)
            .resizable()
            .scaledToFill()
        #elseif canImport(AppKit)
        Image(nsImage: original)
            .resizable()
            .scaledToFill()
        #endif
    }
}
