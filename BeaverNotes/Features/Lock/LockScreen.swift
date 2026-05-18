import SwiftUI

struct LockScreen: View {
    @Environment(AppState.self) private var appState
    @State private var failed = false

    var body: some View {
        VStack(spacing: Space.s6) {
            Spacer()
            Image(systemName: "lock.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundStyle(Palette.accent)
            Text("Beaver Notes is locked")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Palette.textPrimary)
            Spacer()
            Button {
                Task { await unlock() }
            } label: {
                HStack(spacing: Space.s2) {
                    Image(systemName: Symbols.faceID)
                    Text(failed ? "Try again" : "Unlock")
                }
            }
            .buttonStyle(.beaverPrimary)
            .padding(.horizontal, Space.s6)
            Spacer().frame(height: Space.s8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.bgPrimary.ignoresSafeArea())
        .task { await unlock() }
    }

    private func unlock() async {
        let ok = await BiometricGate.authenticate()
        if ok {
            appState.isLocked = false
            failed = false
        } else {
            failed = true
        }
    }
}
