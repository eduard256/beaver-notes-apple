import SwiftUI

struct ServersSection: View {
    var body: some View {
        Section("Servers") {
            NavigationLink {
                ServersListView()
            } label: {
                Label("Manage servers", systemImage: Symbols.server)
            }
        }
    }
}
