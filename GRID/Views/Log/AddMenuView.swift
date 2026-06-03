import SwiftUI

struct AddMenuView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss

    @State private var session: Session
    @State private var showItemPicker = false
    @State private var navPath = NavigationPath()

    init(session: Session) {
        _session = State(initialValue: session)
    }

    private var entriesByMuscle: [(MuscleGroup, [WorkoutEntry])] {
        vm.entriesByMuscle(for: session)
    }

    private var muscleGroups: [MuscleGroup] {
        vm.muscleGroups(for: session)
    }

    var body: some View {
        NavigationStack(path: $navPath) {
        ZStack {
            Color.gridBgPurple.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SESSION #\(session.sessionNumber)")
                            .font(.gridSmall)
                            .foregroundColor(.gridTextSecondary)
                            .kerning(1.5)
                        Text("今日 \(session.fullDateString)")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.gridTextPrimary)

                        // Muscle group chips
                        if !muscleGroups.isEmpty {
                            HStack(spacing: 8) {
                                ForEach(muscleGroups) { group in
                                    Text(group.rawValue)
                                        .font(.gridCaption)
                                        .foregroundColor(.gridAccent)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.gridAccent.opacity(0.18))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.top, 6)
                        }
                    }
                    Spacer()
                    Button {
                        vm.updateSession(session)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gridTextSecondary)
                            .frame(width: 32, height: 32)
                            .background(Color.gridCard)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 20)

                // Add Item button
                Button {
                    showItemPicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle")
                        Text("種目を追加")
                            .font(.gridBody)
                    }
                    .foregroundColor(.gridTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.gridCardInner)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)

                // Item list
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(entriesByMuscle, id: \.0) { group, entries in
                            // Section header
                            HStack {
                                Text(group.rawValue)
                                    .font(.gridSmall)
                                    .foregroundColor(.gridTextSecondary)
                                    .kerning(1.2)
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .padding(.bottom, 6)

                            ForEach(entries) { entry in
                                entryRow(entry: entry)
                            }
                        }

                        // Memo
                        VStack(alignment: .leading, spacing: 8) {
                            TextEditor(text: $session.memo)
                                .font(.gridBody)
                                .foregroundColor(.gridTextPrimary)
                                .frame(minHeight: 80)
                                .padding(12)
                                .scrollContentBackground(.hidden)
                                .background(Color.gridCardInner)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    Group {
                                        if session.memo.isEmpty {
                                            Text("メモ")
                                                .font(.gridBody)
                                                .foregroundColor(.gridTextTertiary)
                                                .padding(16)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                                .allowsHitTesting(false)
                                        }
                                    }
                                )
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showItemPicker) {
            ItemPickerSheet(session: $session)
                .environmentObject(vm)
        }
        .navigationDestination(for: WorkoutEntry.self) { entry in
            AddItemView(session: $session, entryId: entry.id)
                .environmentObject(vm)
        }
        } // NavigationStack
    }

    private func entryRow(entry: WorkoutEntry) -> some View {
        let itemName = vm.item(for: entry.itemId)?.name ?? "Unknown"
        return VStack(spacing: 0) {
            Button {
                navPath.append(entry)
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(.gridTextTertiary)
                    Text(itemName)
                        .font(.gridBody)
                        .foregroundColor(.gridTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundColor(.gridTextTertiary)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider()
                .background(Color.gridCardInner)
                .padding(.horizontal, 24)
        }
    }
}

// MARK: - Item picker sheet

struct ItemPickerSheet: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var session: Session

    @State private var selectedGroup: MuscleGroup = .chest
    @State private var selectedItemIds: Set<UUID> = []
    @State private var searchText: String = ""

    private var filteredItems: [Item] {
        let items = vm.items(for: selectedGroup)
        if searchText.isEmpty { return items }
        return items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ZStack {
            Color.gridBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // ヘッダー
                ZStack {
                    Text("種目を選択")
                        .font(.gridHeadline)
                        .foregroundColor(.gridTextPrimary)
                        .frame(maxWidth: .infinity)

                    HStack {
                        Button("閉じる") {
                            dismiss()
                        }
                        .font(.gridBody)
                        .foregroundColor(.gridAccent)

                        Spacer()

                        Button {
                            addSelectedItems()
                        } label: {
                            Text("追加\(selectedItemIds.isEmpty ? "" : "(\(selectedItemIds.count))")")
                                .font(.gridBody)
                                .foregroundColor(selectedItemIds.isEmpty ? .gridTextTertiary : .white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 7)
                                .background(selectedItemIds.isEmpty ? Color.gridCard : Color.gridAccent)
                                .clipShape(Capsule())
                        }
                        .disabled(selectedItemIds.isEmpty)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)

                // 検索フォーム
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gridTextTertiary)
                    TextField("検索", text: $searchText)
                        .font(.gridBody)
                        .foregroundColor(.gridTextPrimary)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gridTextTertiary)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(Color.gridCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)
                .padding(.bottom, 14)

                // 筋肉グループフィルター
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(MuscleGroup.allCases) { group in
                            let isSelected = selectedGroup == group
                            let hasMatch = !searchText.isEmpty &&
                                vm.items(for: group).contains { $0.name.localizedCaseInsensitiveContains(searchText) }
                            Button {
                                selectedGroup = group
                            } label: {
                                Text(group.rawValue)
                                    .font(.gridBody)
                                    .foregroundColor(
                                        isSelected ? .white :
                                        hasMatch   ? .gridAccent :
                                                     .gridTextSecondary
                                    )
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 8)
                                    .background(
                                        isSelected ? Color.gridAccent :
                                        hasMatch   ? Color.gridAccent.opacity(0.30) :
                                                     Color.gridCard
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 12)

                // 種目リスト
                List {
                    ForEach(filteredItems) { item in
                        let isSelected = selectedItemIds.contains(item.id)
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                if isSelected {
                                    selectedItemIds.remove(item.id)
                                } else {
                                    selectedItemIds.insert(item.id)
                                }
                            }
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .stroke(isSelected ? Color.gridAccent : Color.gridTextTertiary.opacity(0.5), lineWidth: 1.5)
                                        .frame(width: 18, height: 18)
                                    if isSelected {
                                        Circle()
                                            .fill(Color.gridAccent)
                                            .frame(width: 18, height: 18)
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                Text(item.name)
                                    .font(.gridBody)
                                    //.font(.system(size: 17, weight: .regular))
                                    .foregroundColor(.gridTextPrimary)
                                Spacer()
                            }
                        }
                        .listRowBackground(isSelected ? Color.gridAccent.opacity(0.08) : Color.gridCard)
                        .animation(.easeInOut(duration: 0.15), value: isSelected)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func addSelectedItems() {
        for id in selectedItemIds {
            if !session.entries.contains(where: { $0.itemId == id }) {
                session.entries.append(WorkoutEntry(itemId: id))
            }
        }
        vm.updateSession(session)
        dismiss()
    }
}
#Preview {
    let vm = AppViewModel()
    let session = vm.ensureTodaySession()
    return AddMenuView(session: session)
        .environmentObject(vm)
}
