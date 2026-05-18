import SwiftUI

struct AboutSection: View {
    var body: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(version)
                    .foregroundStyle(Palette.textSecondary)
            }
            Link(destination: URL(string: "https://github.com/eduard256/beaver-notes")!) {
                Label("Project on GitHub", systemImage: "link")
            }
        }
    }

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
