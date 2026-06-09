import SwiftUI

// Shared form used by both EditItemView and NewItemView
struct ItemFormView: View {
    @Binding var name: String
    @Binding var type: ItemType
    @Binding var restTimerSeconds: Int
    @Binding var muscleGroup: MuscleGroup

    @State private var timerTyped    = ""
    @State private var timerHasTyped = false
    @FocusState private var nameFocused: Bool
    @FocusState private var timerFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // ─── 筋肉グループチップ（上部：キーボードと重ならない）───
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
            .padding(.bottom, 16)

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
                        .focused($nameFocused)
                        .submitLabel(.done)
                        .onSubmit { nameFocused = false }
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .fixedSize()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

                Divider().background(Color.gridCardInner)

                // Rest timer header
                HStack {
                    Text("レストタイマー")
                        .font(.gridBody)
                        .foregroundColor(.gridTextPrimary)
                    Spacer()
                    Button {
                        if timerFocused {
                            // 編集中はチェックで確定
                            timerFocused  = false
                            timerTyped    = ""
                            timerHasTyped = false
                        } else {
                            restTimerSeconds = restTimerSeconds > 0 ? 0 : 120
                        }
                    } label: {
                        Image(systemName: timerFocused ? "checkmark" : (restTimerSeconds > 0 ? "minus" : "plus"))
                            .foregroundColor(timerFocused ? .white : .gridTextSecondary)
                            .frame(width: 28, height: 28)
                            .background(timerFocused ? Color.gridAccent : Color.gridCardInner)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

                // Timer picker (shown when enabled)
                if restTimerSeconds > 0 {
                    HStack(spacing: 32) {
                        Button {
                            if restTimerSeconds > 10 {
                                restTimerSeconds -= 10
                                syncTimerFields()
                            }
                        } label: {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 28))
                                .foregroundColor(.gridAccent)
                        }

                        ZStack {
                            // 見えないTextField（キーボード入力キャプチャ用）
                            TextField("", text: $timerTyped)
                                .keyboardType(.numberPad)
                                .frame(width: 1, height: 1)
                                .opacity(0.01)
                                .focused($timerFocused)
                                .onChange(of: timerTyped) { oldVal, newVal in
                                    let digits = newVal.filter { $0.isNumber }
                                    let oldDigits = oldVal.filter { $0.isNumber }
                                    if digits.count > oldDigits.count {
                                        timerHasTyped = true
                                        timerTyped = String(digits.suffix(4))
                                    } else {
                                        timerTyped = String(digits)
                                    }
                                    if timerHasTyped { applyTimerInput() }
                                }

                            // 色分けテキスト表示
                            timerColoredDisplay
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    timerTyped    = ""
                                    timerHasTyped = false
                                    timerFocused  = true
                                }
                        }

                        Button {
                            restTimerSeconds += 10
                            syncTimerFields()
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
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                if nameFocused {
                    Button("完了") { nameFocused = false }
                        .foregroundColor(.gridAccent)
                }
            }
        }
    }

    // MARK: - 色分けタイマー表示

    private var timerColoredDisplay: some View {
        let font  = Font.system(size: 44, weight: .bold, design: .monospaced)
        let gray  = Color.gridTextTertiary
        let accent = Color.gridAccent

        if !timerHasTyped {
            let m = restTimerSeconds / 60
            let s = restTimerSeconds % 60
            return Text(String(format: "%d:%02d", m, s))
                .font(font).foregroundColor(timerFocused ? gray : .gridTextPrimary)
        } else {
            let typed     = timerTyped.filter { $0.isNumber }
            let autoCount = max(0, 4 - typed.count)
            let padded    = String(repeating: "0", count: autoCount) + typed
            let d         = Array(padded)

            func col(_ idx: Int) -> Color { idx < autoCount ? gray : accent }

            return (
                Text(String(d[0])).foregroundColor(col(0)) +
                Text(String(d[1])).foregroundColor(col(1)) +
                Text(":").foregroundColor(gray) +
                Text(String(d[2])).foregroundColor(col(2)) +
                Text(String(d[3])).foregroundColor(col(3))
            ).font(font)
        }
    }

    // MARK: - ヘルパー

    private func applyTimerInput() {
        let digits = timerTyped.filter { $0.isNumber }
        let padded = String(repeating: "0", count: max(0, 4 - digits.count)) + digits
        let m = Int(padded.prefix(2))!
        let s = Int(padded.suffix(2))!
        let total = m * 60 + s
        if total > 0 { restTimerSeconds = total }
    }

    private func syncTimerFields() {
        timerTyped    = ""
        timerHasTyped = false
    }

    private func timerString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

#Preview {
    ZStack {
        Color.gridBg.ignoresSafeArea()
        ScrollView {
            ItemFormView(
                name: .constant("ベンチプレス"),
                type: .constant(.freeWeight),
                restTimerSeconds: .constant(120),
                muscleGroup: .constant(.chest)
            )
            .padding(.top, 40)
        }
    }
}
