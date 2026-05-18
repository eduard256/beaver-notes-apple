import SwiftUI

struct WallToolbar: ToolbarContent {
    @Binding var showServerPicker: Bool
    @Binding var showSettings: Bool
    @Binding var searchQuery: String

    var body: some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .topBarLeading) {
            Button { showServerPicker = true } label: {
                Image(systemName: Symbols.server)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button { showSettings = true } label: {
                Image(systemName: Symbols.settings)
            }
        }
        #else
        ToolbarItem {
            Button { showSettings = true } label: {
                Image(systemName: Symbols.settings)
            }
        }
        #endif
    }
}
