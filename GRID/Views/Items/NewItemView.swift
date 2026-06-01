import SwiftUI

struct NewItemView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name             = ""
    @State private var type             = ItemType.freeWeight
    @State private var restTimerSeconds = 120
    @State private var muscleGroup      = MuscleGroup.chest

    var body: some View {
        ZStack {
            Color.gridBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: 4) {
                        Text("+")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.gridDanger)
                        Text("ITEM")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.gridTextPrimary)
                    }
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
                            guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            let item = Item(
                                name: name,
                                type: type,
                                restTimerSeconds: restTimerSeconds,
                                muscleGroup: muscleGroup
                            )
                            vm.addItem(item)
                            dismiss()
                        } label: {
                            Text("保存")
                                .font(.gridHeadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(name.isEmpty ? Color.gridAccent.opacity(0.4) : Color.gridAccent)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(name.isEmpty)
                        .padding(.horizontal, 20)

                        Spacer().frame(height: 100)
                    }
                }
            }
        }
    }
}

#Preview {
    NewItemView()
        .environmentObject(AppViewModel())
}
