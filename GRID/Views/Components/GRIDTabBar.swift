import SwiftUI

enum GRIDTab {
    case log, items, data, system
}

struct GRIDTabBar: View {
    @Binding var selected: GRIDTab

    var body: some View {
        HStack(spacing: 0) {
            tabItem(icon: "list.bullet.rectangle", label: "LOG",    tab: .log)
            tabItem(icon: "dumbbell",              label: "ITEMS",  tab: .items)
            tabItem(icon: "chart.bar",             label: "DATA",   tab: .data)
            tabItem(icon: "gearshape",             label: "SYSTEM", tab: .system)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.gridTabBar)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, GRIDLayout.tabBarHomePadding)
    }

    private func tabItem(icon: String, label: String, tab: GRIDTab) -> some View {
        let isSelected = selected == tab
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selected = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                Text(label)
                    .font(.gridSmall)
                    .kerning(1)
            }
            .foregroundColor(isSelected ? .gridAccent : .gridTextSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.gridTabSelected)
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    ZStack {
        Color.gridBg.ignoresSafeArea()
        VStack {
            Spacer()
            GRIDTabBar(selected: .constant(.log))
        }
    }
}
