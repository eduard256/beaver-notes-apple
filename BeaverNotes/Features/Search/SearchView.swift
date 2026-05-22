import SwiftUI

struct SearchView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var type: String = ""
    @State private var pinned = false
    @State private var tag = ""
    @State private var dateFrom = Date.distantPast
    @State private var dateTo = Date.distantFuture
    @State private var useDateFilter = false

    var body: some View {
        Form {
            Section {
                TextField("Search…", text: $query)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    #endif
            }
            Section("Type") {
                Picker("", selection: $type) {
                    Text("All").tag("")
                    Text("Text").tag("text")
                    Text("Images").tag("image")
                    Text("Videos").tag("video")
                    Text("Files").tag("file")
                }
                .pickerStyle(.segmented)
            }
            Section {
                Toggle("Pinned only", isOn: $pinned)
                HStack {
                    Text("Tag")
                    Spacer()
                    TextField("name", text: $tag)
                        .multilineTextAlignment(.trailing)
                }
            }
            Section {
                Toggle("Filter by date", isOn: $useDateFilter)
                if useDateFilter {
                    DatePicker("From", selection: $dateFrom, displayedComponents: .date)
                    DatePicker("To",   selection: $dateTo,   displayedComponents: .date)
                }
            }
            Section {
                Button("Apply") {
                    apply()
                }
                .frame(maxWidth: .infinity)
                Button("Clear") {
                    clear()
                }
                .foregroundStyle(Palette.danger)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Search")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        #if os(macOS)
        .formStyle(.grouped)
        #endif
    }

    private func apply() {
        var q = MessageQuery()
        if !query.isEmpty { q.search = query }
        if !type.isEmpty  { q.type = type }
        if pinned { q.pinned = true }
        if !tag.isEmpty { q.tag = tag.trimmingCharacters(in: CharacterSet(charactersIn: "#")) }
        if useDateFilter {
            let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime]
            q.dateFrom = f.string(from: dateFrom)
            q.dateTo   = f.string(from: dateTo)
        }
        appState.activeSearch = q
        dismiss()
    }

    private func clear() {
        appState.activeSearch = nil
        query = ""
        type = ""
        pinned = false
        tag = ""
        useDateFilter = false
        dismiss()
    }
}
