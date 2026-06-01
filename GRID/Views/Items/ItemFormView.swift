import SwiftUI

// Shared form used by both EditItemView and NewItemView
struct ItemFormView: View {
    @Binding var name: String
    @Binding var type: ItemType
    @Binding var restTimerSeconds: Int
    @Binding var muscleGroup: MuscleGroup

    var body: some View {
        VStack(spacing: 0) {
            // Card
            VStack(spacing: 0) {
                // Name field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Item")
                        .font(.gridCaption)
                        .foregroundColor(.gridTextSecondary)
                    TextField("ベンチプレス", text: $name)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.gridTextPrimary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                Divider().background(Color.gridCardInner)

                // Type picker
                HStack {
                    Text("タイプ")
                        .font(.gridBody)
                        .foregroundColor(.gridTextPrimary)
                    Spacer()
                    Picker("", selection: $type) {
                        ForEach(ItemType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.menu)
                    .foregroundColor(.gridTextSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

                Divider().background(Color.gridCardInner)

                // Rest timer toggle
                HStack {
                    Text("レストタイマー")
                        .font(.gridBody)
                        .foregroundColor(.gridTextPrimary)
                    Spacer()
                    Button {
                        restTimerSeconds = restTimerSeconds > 0 ? 0 : 120
                    } label: {
                        Image(systemName: restTimerSeconds > 0 ? "minus" : "plus")
                            .foregroundColor(.gridTextSecondary)
                            .frame(width: 28, height: 28)
                            .background(Color.gridCardInner)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

                // Timer picker (shown when enabled)
                if restTimerSeconds > 0 {
                    HStack(spacing: 32) {
                        Button {
                            if restTimerSeconds > 30 { restTimerSeconds -= 30 }
                        } label: {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 28))
                                .foregroundColor(.gridAccent)
                        }

                        Text(timerString(restTimerSeconds))
                            .font(.system(size: 44, weight: .bold, design: .monospaced))
                            .foregroundColor(.gridTextPrimary)

                        Button {
                            restTimerSeconds += 30
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 28))
                                .foregroundColor(.gridAccent)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.gridAccent.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .background(Color.gridCard)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 20)

            // Muscle group chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(MuscleGroup.allCases) { group in
                        Button {
                            muscleGroup = group
                        } label: {
                            Text(group.rawValue)
                                .font(.gridBody)
                                .foregroundColor(muscleGroup == group ? .white : .gridTextSecondary)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 8)
                                .background(muscleGroup == group ? Color.gridAccent : Color.gridCard)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 20)
        }
    }

    private func timerString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
