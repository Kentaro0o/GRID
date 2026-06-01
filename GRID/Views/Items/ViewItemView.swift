import SwiftUI

struct ViewItemView: View {
    @EnvironmentObject var vm: AppViewModel

    @State private var selectedGroup: MuscleGroup = .chest
    @State private var showNewItem = false
    @State private var editingItem: Item? = nil

    private var filteredItems: [Item] {
        vm.items(for: selectedGroup)
    }

    var body: some View {
        ZStack {
            Color.gridBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("ITEM")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.gridTextPrimary)
                    Spacer()
                    Button {
                        showNewItem = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.gridAccent)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 24)

                // Muscle group filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(MuscleGroup.allCases) { group in
                            Button {
                                selectedGroup = group
                            } label: {
                                Text(group.rawValue)
                                    .font(.gridBody)
                                    .foregroundColor(selectedGroup == group ? .white : .gridTextSecondary)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 8)
                                    .background(selectedGroup == group ? Color.gridAccent : Color.clear)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(selectedGroup == group ? Color.clear : Color.gridTextSecondary.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 20)

                // Item list
                List {
                    ForEach(filteredItems) { item in
                        Button {
                            editingItem = item
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundColor(.gridTextTertiary)
                                Text(item.name)
                                    .font(.gridBody)
                                    .foregroundColor(.gridTextPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gridTextTertiary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.gridBg)
                        .listRowSeparatorTint(Color.gridCardInner)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .sheet(item: $editingItem) { item in
            EditItemView(item: item)
                .environmentObject(vm)
        }
        .sheet(isPresented: $showNewItem) {
            NewItemView()
                .environmentObject(vm)
        }
    }
}

#Preview {
    ViewItemView()
        .environmentObject(AppViewModel())
}
