import SwiftUI

struct WelcomePage: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: Space.s6) {
            Spacer()

            Image(systemName: "tray.full.fill")
                .font(.system(size: 72))
                .foregroundStyle(Palette.accent)

            Text("Beaver Notes")
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(Palette.textPrimary)

            Text("Your self-hosted note wall.\nTransfer text, images, and files between\nyour devices, without third parties.")
                .multilineTextAlignment(.center)
                .font(Typography.body)
                .foregroundStyle(Palette.textSecondary)
                .padding(.horizontal, Space.s6)

            Spacer()

            Button("Get Started", action: onContinue)
                .buttonStyle(.beaverPrimary)
                .padding(.horizontal, Space.s6)
                .padding(.bottom, Space.s8)
        }
        .frame(maxWidth: 480)
    }
}
