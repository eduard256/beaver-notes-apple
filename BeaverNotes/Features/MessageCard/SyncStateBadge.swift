import SwiftUI

struct SyncStateBadge: View {
    let state: SyncState

    var body: some View {
        switch state {
        case .local, .pending:
            Image(systemName: Symbols.clock)
                .font(.caption2)
                .foregroundStyle(Palette.textTertiary)
        case .syncing:
            Image(systemName: Symbols.arrowsClock)
                .font(.caption2)
                .foregroundStyle(Palette.accent)
        case .synced:
            EmptyView()
        case .failed:
            Image(systemName: Symbols.warning)
                .font(.caption2)
                .foregroundStyle(Palette.danger)
        }
    }
}
