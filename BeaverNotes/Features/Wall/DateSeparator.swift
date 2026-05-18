import SwiftUI

struct DateSeparator: View {
    let label: String
    var body: some View {
        HStack {
            Text(label.uppercased())
                .font(.caption2.weight(.medium))
                .tracking(0.6)
                .foregroundStyle(Palette.textTertiary)
                .padding(.horizontal, Space.s3)
                .padding(.vertical, 3)
                .background(Palette.bgSecondary)
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Space.s2)
    }
}

enum DateLabels {
    static func label(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let df = DateFormatter()
        df.locale = .current
        if cal.component(.year, from: date) == cal.component(.year, from: Date()) {
            df.setLocalizedDateFormatFromTemplate("MMMM d")
        } else {
            df.setLocalizedDateFormatFromTemplate("MMMM d yyyy")
        }
        return df.string(from: date)
    }

    static func dayKey(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    static func time(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = .current
        df.setLocalizedDateFormatFromTemplate("HH:mm")
        return df.string(from: date)
    }
}
