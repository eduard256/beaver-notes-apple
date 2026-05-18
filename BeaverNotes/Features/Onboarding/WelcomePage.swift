import SwiftUI

struct WelcomePage: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: Space.s6) {
            Spacer()
            Image(systemName: "tree.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .foregroundStyle(Palette.accent)
            VStack(spacing: Space.s3) {
                Text("Beaver Notes")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Palette.textPrimary)
                Text("Your self-hosted notes, with you everywhere.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.horizontal, Space.s8)
            }
            Spacer()
            Button("Get started", action: onNext)
                .buttonStyle(.beaverPrimary)
                .padding(.horizontal, Space.s6)
            Spacer().frame(height: Space.s12)
        }
    }
}
