import SwiftUI

struct OnboardingFlow: View {
    @State private var page = 0

    var body: some View {
        TabView(selection: $page) {
            WelcomePage(onNext: { page = 1 })
                .tag(0)
            ServerEntryPage(onDone: { })
                .tag(1)
        }
        #if os(iOS)
        .tabViewStyle(.page(indexDisplayMode: .always))
        #endif
        .background(Palette.bgPrimary.ignoresSafeArea())
    }
}
