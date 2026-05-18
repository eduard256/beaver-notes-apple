import SwiftUI

struct DateSeparator: View {
    let date: Date

    var body: some View {
        Text(formatted)
            .font(.caption.weight(.medium))
            .foregroundStyle(Palette.textSecondary)
            .padding(.horizontal, Space.s3)
            .padding(.vertical, 4)
            .background(Palette.bgSecondary, in: Capsule())
    }

    private var formatted: String {
        let f = DateFormatter()
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        f.dateStyle = .medium
        f.doesRelativeDateFormatting = true
        return f.string(from: date)
    }
}
