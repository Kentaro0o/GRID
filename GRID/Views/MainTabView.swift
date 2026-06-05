import SwiftUI

struct MainTabView: View {
    @StateObject private var vm = AppViewModel()
    @State private var selectedTab: GRIDTab = .log

    var body: some View {
        Group {
            switch selectedTab {
            case .log:
                LogTabView()
            case .items:
                ViewItemView()
            case .data:
                DataView()
            case .system:
                SystemView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            GRIDTabBar(selected: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
        .environmentObject(vm)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView()
}
