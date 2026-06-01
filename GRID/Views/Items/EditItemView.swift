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
                // Header
                HStack {
                    Text("EDIT")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.gridTextPrimary)
                    Spacer()
                    Button("キャンセル") { dismiss() }
                        .font(.gridBody)
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color.gridAccent.opacity(0.7))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
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

                        // Save button
                        Button {
                            var updated = item
                            updated.name             = name
                            updated.type             = type
                            updated.restTimerSeconds = restTimerSeconds
                            updated.muscleGroup      = muscleGroup
                            vm.updateItem(updated)
                            dismiss()
                        } label: {
                            Text("保存")
                                .font(.gridHeadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.gridAccent)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 20)

                        Spacer().frame(height: 60)
                    }
                }

                // Delete button
                Button {
                    showDeleteConfirm = true
                } label: {
                    Text("- ITEM")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.gridDanger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                }
                .background(Color.gridBg)
                .padding(.bottom, 8)
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
}

#Preview {
    EditItemView(item: Item.defaults[0])
        .environmentObject(AppViewModel())
}
