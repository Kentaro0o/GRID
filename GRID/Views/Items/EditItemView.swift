import SwiftUI

struct EditItemView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss

    let item: Item

    @State private var name: String
    @State private var type: ItemType
    @State private var restTimerSeconds: Int
    @State private var muscleGroup: MuscleGroup
    @State private var showDeleteConfirm = false

    @FocusState private var isAnyFieldFocused: Bool

    init(item: Item) {
        self.item = item
        _name             = State(initialValue: item.name)
        _type             = State(initialValue: item.type)
        _restTimerSeconds = State(initialValue: item.restTimerSeconds)
        _muscleGroup      = State(initialValue: item.muscleGroup)
    }

    var body: some View {
        ZStack {
            Color.gridBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // ─── Header：キャンセル ｜ /EDIT（中央）｜ 保存 ───
                ZStack {
                    HStack(spacing: 0) {
                        Text("/")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.gridDanger)
                        Text("EDIT")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.gridTextPrimary)
                    }
                    .frame(maxWidth: .infinity)

                    HStack {
                        Button("キャンセル") { dismiss() }
                            .font(.gridBody)
                            .foregroundColor(.gridAccent)

                        Spacer()

                        Button("保存") { saveItem() }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(name.isEmpty ? .gridTextTertiary : .white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(name.isEmpty ? Color.gridCard : Color.gridAccent)
                            .clipShape(Capsule())
                            .disabled(name.isEmpty)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.top, 60)
                .padding(.bottom, 24)

                ScrollView {
                    VStack(spacing: 20) {
                        ItemFormView(
                            name: $name,
                            type: $type,
                            restTimerSeconds: $restTimerSeconds,
                            muscleGroup: $muscleGroup
                        )

                        // ─── 削除ボタン ───
                        Button {
                            showDeleteConfirm = true
                        } label: {
                            Text("削除")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(.gridDanger)
                        }
                        .padding(.top, 48)

                        Spacer().frame(height: 100)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") { isAnyFieldFocused = false }
                    .foregroundColor(.gridAccent)
            }
        }
        .alert("削除しますか？", isPresented: $showDeleteConfirm) {
            Button("削除", role: .destructive) {
                vm.deleteItem(item)
                dismiss()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("\(item.name) を削除します。この操作は取り消せません。")
        }
    }

    private func saveItem() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        var updated = item
        updated.name             = name
        updated.type             = type
        updated.restTimerSeconds = restTimerSeconds
        updated.muscleGroup      = muscleGroup
        vm.updateItem(updated)
        dismiss()
    }
}

#Preview {
    EditItemView(item: Item.defaults[0])
        .environmentObject(AppViewModel())
}
