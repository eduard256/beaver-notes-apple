import SwiftUI

struct SearchFilterState: Equatable {
    var type: String?
    var dateFrom: Date?
    var dateTo: Date?
    var tag: String = ""
    var pinned: Bool = false
}

struct SearchFilters: View {
    @Binding var state: SearchFilterState

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s4) {
            TypeChips(selected: $state.type)
            DateRangeRow(from: $state.dateFrom, to: $state.dateTo)
            TagInput(text: $state.tag)
            Toggle("Pinned only", isOn: $state.pinned)
                .tint(Palette.accent)
        }
        .padding(Space.s4)
        .background(Palette.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }
}
