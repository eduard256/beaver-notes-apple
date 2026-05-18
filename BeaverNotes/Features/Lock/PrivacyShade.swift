import SwiftUI

struct PrivacyShade: View {
    var body: some View {
        ZStack {
            Palette.bgPrimary.ignoresSafeArea()
            Image(systemName: "tree.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundStyle(Palette.accent.opacity(0.6))
        }
    }
}
