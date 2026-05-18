import SwiftUI

struct EditorView: View {
    let initialContent: String
    let isEdit: Bool
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @State private var preview = false

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.bgPrimary.ignoresSafeArea()
                VStack(spacing: 0) {
                    EditorToolbar(text: $text, preview: $preview)

                    Divider().background(Palette.borderSecondary)

                    if preview {
                        ScrollView {
                            MessageBody(content: text)
                                .padding(Space.s4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        EditorTextView(text: $text)
                            .padding(.horizontal, Space.s3)
                    }
                }
            }
            .navigationTitle(isEdit ? "Edit" : "New")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(text)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear { text = initialContent }
        }
    }
}
