import SwiftUI

struct AddItemView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss

    @Binding var session: Session
    let entryId: UUID

    @State private var timerRunning = false
    @State private var remainingSeconds: Int = 120
    @State private var timer: Timer? = nil
    @State private var totalSeconds: Int = 120
    @State private var isEditingTimer = false
    @FocusState private var focusedField: Field?

    enum Field { case weight, reps, memo }

    private var entryIndex: Int? {
        session.entries.firstIndex { $0.id == entryId }
    }

    private var entry: WorkoutEntry? {
        guard let i = entryIndex else { return nil }
        return session.entries[i]
    }

    private var itemName: String {
        entry.flatMap { vm.item(for: $0.itemId) }?.name ?? ""
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.gridBgPurple.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        saveAndDismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.gridTextPrimary)
                            .frame(width: 36, height: 36)
                            //.background(Color.gridCard)
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text(itemName)
                        .font(.gridHeadline)
                        .foregroundColor(.gridTextPrimary)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                //確認のため
                //.background(.red)

                // Sets list
                ScrollView {
                    VStack(spacing: 0) {
                        HStack {
                            Text("セット")
                                .font(.gridSmall)
                                .foregroundColor(.gridTextSecondary)
                                .kerning(1.2)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 10)

                        if let idx = entryIndex {
                            ForEach(Array(session.entries[idx].sets.enumerated()), id: \.element.id) { setIdx, _ in
                                setRow(entryIdx: idx, setIdx: setIdx)
                            }
                        }

                        // Add / Remove set buttons
                        HStack(spacing: 16) {
                            Spacer()
                            Button {
                                if let idx = entryIndex, session.entries[idx].sets.count > 1 {
                                    session.entries[idx].sets.removeLast()
                                }
                            } label: {
                                Image(systemName: "minus")
                                    .frame(width: 36, height: 36)
                                    //.background(Color.gridCard)
                                    .clipShape(Circle())
                                    .foregroundColor(.gridTextPrimary)
                            }
                            Button {
                                if let idx = entryIndex {
                                    let prev = session.entries[idx].sets.last
                                    session.entries[idx].sets.append(
                                        WorkoutSet(weight: prev?.weight ?? 0, reps: prev?.reps ?? 0)
                                    )
                                }
                            } label: {
                                Image(systemName: "plus")
                                    .frame(width: 36, height: 36)
                                    //.background(Color.gridCard)
                                    .clipShape(Circle())
                                    .foregroundColor(.gridTextPrimary)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)

                        // Memo
                        if let idx = entryIndex {
                            TextEditor(text: $session.entries[idx].memo)
                                .font(.gridBody)
                                .foregroundColor(.gridTextPrimary)
                                .frame(minHeight: 70)
                                .padding(12)
                                .scrollContentBackground(.hidden)
                                .focused($focusedField, equals: .memo)
                                .background(Color.gridCardInner)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    Group {
                                        if session.entries[idx].memo.isEmpty {
                                            Text("メモ")
                                                .font(.gridBody)
                                                .foregroundColor(.gridTextTertiary)
                                                .padding(16)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                                .allowsHitTesting(false)
                                        }
                                    }
                                )
                                .padding(.horizontal, 24)
                        }

                        Spacer().frame(height: 20)
                    }
                }

                Spacer().frame(height: 160)
            }

            // 編集ボタン＋タイマー（キーボードで動かない）
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isEditingTimer.toggle()
                            if !isEditingTimer {
                                remainingSeconds = totalSeconds
                            }
                        }
                    } label: {
                        Image(systemName: isEditingTimer ? "checkmark.circle.fill" : "slider.horizontal.3")
                            .font(.system(size: 20))
                            .foregroundColor(isEditingTimer ? .gridAccent : .gridTextSecondary)
                            .frame(width: 36, height: 36)
                            //.background(Color.gridCard)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .padding(.bottom, 10)

                timerPanel
            }
            //.ignoresSafeArea(.keyboard)
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            if let item = entry.flatMap({ vm.item(for: $0.itemId) }) {
                totalSeconds = item.restTimerSeconds
                remainingSeconds = item.restTimerSeconds
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") {
                    focusedField = nil
                }
                .foregroundColor(.gridAccent)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Set row

    private func setRow(entryIdx: Int, setIdx: Int) -> some View {
        VStack(spacing: 0) {
        HStack(spacing: 12) {
            // Set number
            Text("\(setIdx + 1)")
                .font(.gridCaption)
                .foregroundColor(.gridTextSecondary)
                .frame(width: 20)

            // Weight
            HStack(spacing: 4) {
                TextField("0", value: $session.entries[entryIdx].sets[setIdx].weight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 56)
                    .padding(.vertical, 8)
                    //.background(Color.gridCard)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .font(.gridBody)
                    .foregroundColor(.gridTextPrimary)
                    .focused($focusedField, equals: .weight)
                Text("Kg")
                    .font(.gridCaption)
                    .foregroundColor(.gridTextSecondary)
            }

            // Reps
            HStack(spacing: 4) {
                TextField("0", value: $session.entries[entryIdx].sets[setIdx].reps, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 44)
                    .padding(.vertical, 8)
                    //.background(Color.gridCard)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .font(.gridBody)
                    .foregroundColor(.gridTextPrimary)
                    .focused($focusedField, equals: .reps)
                Text("回")
                    .font(.gridCaption)
                    .foregroundColor(.gridTextSecondary)
            }

            Spacer()

            // Delete
            Button {
                if session.entries[entryIdx].sets.count > 1 {
                    session.entries[entryIdx].sets.remove(at: setIdx)
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.gridTextTertiary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)

        Divider()
            .background(Color.gridCardInner)
            .padding(.horizontal, 24)
        } // VStack
    }

    // MARK: - Timer panel

    private var timerPanel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 24) {
                if isEditingTimer {
                    // 編集モード：−
                    Button {
                        if totalSeconds > 30 {
                            totalSeconds -= 30
                            remainingSeconds = totalSeconds
                            saveTimerToItem()
                        }
                    } label: {
                        Image(systemName: "minus.circle")
                            .font(.system(size: 28))
                            .foregroundColor(.gridAccent)
                            .frame(width: 48, height: 48)
                    }
                } else {
                    // 通常：リセット
                    Button {
                        remainingSeconds = totalSeconds
                        stopTimer()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 18))
                            .foregroundColor(timerRunning ? .white : .gridTextSecondary)
                            .frame(width: 48, height: 48)
                    }
                }

                Text(timeString(isEditingTimer ? totalSeconds : remainingSeconds))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(isEditingTimer ? .gridAccent : (timerRunning ? .white : .gridTextPrimary))
                    .frame(maxWidth: .infinity)

                if isEditingTimer {
                    // 編集モード：＋
                    Button {
                        totalSeconds += 30
                        remainingSeconds = totalSeconds
                        saveTimerToItem()
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 28))
                            .foregroundColor(.gridAccent)
                            .frame(width: 48, height: 48)
                    }
                } else {
                    // 通常：再生/一時停止
                    Button {
                        timerRunning ? stopTimer() : startTimer()
                    } label: {
                        Image(systemName: timerRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 22))
                            .foregroundColor(timerRunning ? .white : .gridTextSecondary)
                            .frame(width: 48, height: 48)
                            .background(timerRunning ? Color.white.opacity(0.2) : Color.clear)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 32)
        }
        .background(
            isEditingTimer
                ? Color.gridAccent.opacity(0.12)
                : (timerRunning ? Color.gridAccent.opacity(0.25) : Color.gridCard.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.gridTextSecondary.opacity(0.3), lineWidth: 1)
                .opacity(timerRunning || isEditingTimer ? 0 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        //.background(.green)
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .animation(.easeInOut(duration: 0.3), value: timerRunning)
        .animation(.easeInOut(duration: 0.2), value: isEditingTimer)
    }

    private func saveTimerToItem() {
        guard let entry = entry,
              var item = vm.item(for: entry.itemId) else { return }
        item.restTimerSeconds = totalSeconds
        vm.updateItem(item)
    }

    // MARK: - Timer logic

    private func startTimer() {
        timerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                stopTimer()
            }
        }
    }

    private func stopTimer() {
        timerRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func saveAndDismiss() {
        vm.updateSession(session)
        dismiss()
    }
}


#Preview {
    let vm = AppViewModel()
    var session = vm.ensureTodaySession()
    let item = Item.defaults[0]
    let entry = WorkoutEntry(
        itemId: item.id,
        sets: [
            WorkoutSet(weight: 90, reps: 8),
            WorkoutSet(weight: 90, reps: 8),
            WorkoutSet(weight: 80, reps: 7),
        ]
    )
    session.entries = [entry]
    vm.updateSession(session)
    return AddItemView(session: .constant(session), entryId: entry.id)
        .environmentObject(vm)
}
