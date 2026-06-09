import SwiftUI

struct NewItemView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss

    var initialGroup: MuscleGroup = .chest

    @State private var name             = ""
    @State private var type             = ItemType.freeWeight
    @State private var restTimerSeconds = 120
    @State private var muscleGroup: MuscleGroup

    init(initialGroup: MuscleGroup = .chest) {
        self.initialGroup = initialGroup
        _muscleGroup = State(initialValue: initialGroup)
    }

    var body: some View {
        ZStack {
            Color.gridBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header：キャンセル ｜ +ITEM（中央）｜ 保存
                ZStack {
                    HStack(spacing: 4) {
                        Text("+")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.gridDanger)
                        Text("ITEM")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.gridTextPrimary)
                    }
                    .frame(maxWidth: .infinity)

                    HStack {
                        Button("キャンセル") { dismiss() }
                            .font(.gridBody)
                            .foregroundColor(.gridAccent)

                        Spacer()

                        Button("保存") {
                            saveItem()
                        }
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
                .padding(.top, GRIDLayout.headerTopPadding)
                .padding(.bottom, GRIDLayout.headerBottomPadding)

                ScrollView {
                    VStack(spacing: 20) {
                        ItemFormView(
                            name: $name,
                            type: $type,
                            restTimerSeconds: $restTimerSeconds,
                            muscleGroup: $muscleGroup
                        )
                        Spacer().frame(height: 100)
                    }
                }
            }
        }
    }

    private func saveItem() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let item = Item(
            name: name,
            type: type,
            restTimerSeconds: restTimerSeconds,
            muscleGroup: muscleGroup
        )
        vm.addItem(item)
        dismiss()
    }
}

#Preview {
    NewItemView()
        .environmentObject(AppViewModel())
}
