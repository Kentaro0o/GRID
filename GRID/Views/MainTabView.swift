import SwiftUI

struct MainTabView: View {
    @StateObject private var vm = AppViewModel()
    @State private var selectedTab: GRIDTab = .log

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .log:
                    LogTabView()
                case .items:
                    ViewItemView()
                case .system:
                    SystemView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            GRIDTabBar(selected: $selectedTab)
        }
        .environmentObject(vm)
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView()
}
