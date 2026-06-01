import SwiftUI

struct AddMenuView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss

    @State private var session: Session
    @State private var showItemPicker = false
    @State private var editingEntry: WorkoutEntry? = nil

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
                        Text("Today, \(session.fullDateString)")
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
                        Text("Item")
                            .font(.gridBody)
                    }
                    .foregroundColor(.gridTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.gridCard)
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
        .sheet(isPresented: $showItemPicker) {
            ItemPickerSheet(session: $session)
                .environmentObject(vm)
        }
        .sheet(item: $editingEntry) { entry in
            AddItemView(session: $session, entryId: entry.id)
                .environmentObject(vm)
        }
    }

    private func entryRow(entry: WorkoutEntry) -> some View {
        let itemName = vm.item(for: entry.itemId)?.name ?? "Unknown"
        return VStack(spacing: 0) {
            Button {
                editingEntry = entry
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

    var body: some View {
        ZStack {
            Color.gridBg.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("種目を選択")
                        .font(.gridHeadline)
                        .foregroundColor(.gridTextPrimary)
                    Spacer()
                    Button("閉じる") { dismiss() }
                        .foregroundColor(.gridAccent)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)

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
                                    .background(selectedGroup == group ? Color.gridAccent : Color.gridCard)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 16)

                List {
                    ForEach(vm.items(for: selectedGroup)) { item in
                        Button {
                            addItem(item)
                        } label: {
                            HStack {
                                Text(item.name)
                                    .foregroundColor(.gridTextPrimary)
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.gridAccent)
                            }
                        }
                        .listRowBackground(Color.gridCard)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func addItem(_ item: Item) {
        let entry = WorkoutEntry(itemId: item.id)
        session.entries.append(entry)
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
