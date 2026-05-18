import SwiftUI

struct LockScreen: View {
    @Environment(AppState.self) private var appState
    @State private var attempting = false

    var body: some View {
        ZStack {
            Palette.bgPrimary.ignoresSafeArea()
            VStack(spacing: Space.s6) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Palette.accent)

                Text("Beaver Notes")
                    .font(Typography.title)
                    .foregroundStyle(Palette.textPrimary)

                Text("Locked")
                    .font(Typography.callout)
                    .foregroundStyle(Palette.textSecondary)

                Button {
                    unlock()
                } label: {
                    HStack(spacing: Space.s2) {
                        Image(systemName: SF.faceID)
                        Text("Unlock")
                    }
                }
                .buttonStyle(.beaverPrimary)
                .frame(maxWidth: 240)
                .disabled(attempting)
            }
            .padding(Space.s8)
        }
        .task {
            unlock()
        }
    }

    private func unlock() {
        guard !attempting else { return }
        attempting = true
        Task {
            let ok = await BiometricGate.authenticate()
            attempting = false
            if ok {
                appState.isLocked = false
            }
        }
    }
}
