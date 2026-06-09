import SwiftUI

struct ViewItemView: View {
    @EnvironmentObject var vm: AppViewModel

    @State private var selectedGroup: MuscleGroup = .chest
    @State private var showNewItem   = false
    @State private var editingItem: Item? = nil
    @State private var isEditing     = false

    private var filteredItems: [Item] {
        vm.items(for: selectedGroup)
    }

    var body: some View {
        ZStack {
            Color.gridBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // ─── Header ───
                ZStack {
                    Text("ITEM")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.gridTextPrimary)
                        .frame(maxWidth: .infinity)

                    HStack {
                        // 左：追加（編集中は非表示）
                        if !isEditing {
                            Button { showNewItem = true } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.gridTextPrimary)
                                    .frame(width: 40, height: 40)
                                    .background(Color.gridCard)
                                    .clipShape(Circle())
                            }
                        } else {
                            Color.clear.frame(width: 40, height: 40)
                        }

                        Spacer()

                        // 右：編集 / 完了
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isEditing.toggle()
                            }
                        } label: {
                            Image(systemName: isEditing ? "checkmark" : "pencil")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(isEditing ? .white : .gridTextPrimary)
                                .frame(width: 40, height: 40)
                                .background(isEditing ? Color.gridAccent : Color.gridCard)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.top, GRIDLayout.headerTopPadding)
                .padding(.bottom, GRIDLayout.headerBottomPadding)

                // ─── Muscle group filter ───
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(MuscleGroup.allCases) { group in
                            Button { selectedGroup = group } label: {
                                Text(group.rawValue)
                                    .font(.gridBody)
                                    .foregroundColor(selectedGroup == group ? .white : .gridTextSecondary)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 8)
                                    .background(selectedGroup == group ? Color.gridAccent : Color.clear)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(
                                            selectedGroup == group ? Color.clear : Color.gridTextSecondary.opacity(0.3),
                                            lineWidth: 1
                                        )
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 20)

                // ─── Item list ───
                List {
                    ForEach(filteredItems) { item in
                        itemRow(item: item)
                            .listRowBackground(Color.gridBg)
                            .listRowSeparatorTint(Color.gridCardInner)
                            .listRowInsets(EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 16))
                    }
                    .onMove { source, destination in
                        vm.moveItems(in: selectedGroup, from: source, to: destination)
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { vm.deleteItem(filteredItems[$0]) }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            }
        }
        .sheet(item: $editingItem) { item in
            EditItemView(item: item).environmentObject(vm)
        }
        .sheet(isPresented: $showNewItem) {
            NewItemView(initialGroup: selectedGroup).environmentObject(vm)
        }
    }

    private func itemRow(item: Item) -> some View {
        HStack(spacing: 14) {
            Text(item.name)
                .font(.gridBody)
                .foregroundColor(.gridTextPrimary)
            Spacer()
            if !isEditing {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(.gridTextTertiary)
            }
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing { editingItem = item }
        }
    }
}

#Preview {
    ViewItemView()
        .environmentObject(AppViewModel())
}
