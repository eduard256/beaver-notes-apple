import SwiftUI

struct DateRangeRow: View {
    @Binding var from: Date?
    @Binding var to: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            row("From", binding: $from)
            row("To", binding: $to)
        }
    }

    private func row(_ label: String, binding: Binding<Date?>) -> some View {
        HStack {
            Text(label).foregroundStyle(Palette.textSecondary)
            Spacer()
            DatePicker("", selection: Binding(
                get: { binding.wrappedValue ?? Date() },
                set: { binding.wrappedValue = $0 }
            ), displayedComponents: .date)
            .labelsHidden()
            if binding.wrappedValue != nil {
                Button { binding.wrappedValue = nil } label: {
                    Image(systemName: Symbols.close).foregroundStyle(Palette.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
