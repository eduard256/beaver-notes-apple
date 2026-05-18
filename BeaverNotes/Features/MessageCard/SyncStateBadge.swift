import SwiftUI

struct SyncStateBadge: View {
    let state: SyncState
    let onRetry: (() -> Void)?

    var body: some View {
        switch state {
        case .synced:
            EmptyView()
        case .local, .pending:
            Image(systemName: SF.clock)
                .font(.caption2)
                .foregroundStyle(Palette.textTertiary)
        case .syncing:
            Image(systemName: SF.arrowsClock)
                .font(.caption2)
                .foregroundStyle(Palette.textTertiary)
                .symbolEffect(.pulse, options: .repeating)
        case .failed:
            Button {
                onRetry?()
            } label: {
                Image(systemName: SF.warning)
                    .font(.caption2)
                    .foregroundStyle(Palette.danger)
            }
            .buttonStyle(.plain)
        }
    }
}
