import SwiftUI

struct PrivacyShade: View {
    var body: some View {
        ZStack {
            Palette.bgPrimary
            Image(systemName: SF.faceID)
                .font(.system(size: 48))
                .foregroundStyle(Palette.textTertiary)
        }
        .ignoresSafeArea()
        .transition(.opacity)
    }
}
