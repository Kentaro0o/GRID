import SwiftUI
import AudioToolbox
import UserNotifications

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
    @State private var timerTyped   = ""              // ユーザーが打った数字（最大4桁）
    @State private var timerHasTyped = false          // 一度でも入力したか
    @State private var timerEndDate: Date? = nil   // バックグラウンド対応用
    @State private var showEditItem = false
    @State private var keyboardHeight: CGFloat = 0
    // セット入力（タイマーと同じ仕組み）
    @State private var fieldTyped: String = ""
    @State private var fieldHasTyped: Bool = false
    @State private var savedFieldDouble: Double = 0  // weight保存値
    @State private var savedFieldInt: Int = 0        // reps保存値
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case weight(Int)  // setIdx
        case reps(Int)    // setIdx
        case memo
        case timer
    }

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
            Color.gridBgPurple.ignoresSafeArea(.all)

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
                    Menu {
                        Button {
                            showEditItem = true
                        } label: {
                            Label("編集", systemImage: "pencil")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gridTextSecondary)
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                    }
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

            // タイマーパネル：編集時のみキーボード分だけ上にオフセット
            timerContainerView
                .offset(y: isEditingTimer ? -(keyboardHeight - 48) : 0)
                .animation(.easeInOut(duration: 0.25), value: keyboardHeight)
        }
        .ignoresSafeArea(.keyboard)
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            vm.hideTabBar = true
            if let item = entry.flatMap({ vm.item(for: $0.itemId) }) {
                totalSeconds = item.restTimerSeconds
                remainingSeconds = item.restTimerSeconds
            }
        }
        .onDisappear {
            vm.hideTabBar = false
            timer?.invalidate()
        }
        // fieldTyped の変化 → weight/reps に反映
        .onChange(of: fieldTyped) { oldVal, val in
            guard let entryIdx = entryIndex else { return }
            switch focusedField {
            case .weight:
                let filtered = String(val.filter { $0.isNumber || $0 == "." })
                if filtered != val { fieldTyped = filtered; return }
                // 文字が増えた時だけ「入力あり」と判定
                if filtered.count > oldVal.filter({ $0.isNumber || $0 == "." }).count {
                    fieldHasTyped = true
                }
            case .reps:
                let filtered = String(val.filter { $0.isNumber })
                if filtered != val { fieldTyped = filtered; return }
                if filtered.count > oldVal.filter({ $0.isNumber }).count {
                    fieldHasTyped = true
                }
            default: break
            }
        }
        // フォーカス変化 → 前フィールドの値を確定、新フィールドの保存値をセット
        .onChange(of: focusedField) { oldField, newField in
            guard let entryIdx = entryIndex else { return }
            // 前フィールドへの入力を確定
            if let old = oldField {
                switch old {
                case .weight(let si):
                    if fieldHasTyped {
                        let v = Double(fieldTyped) ?? savedFieldDouble
                        session.entries[entryIdx].sets[si].weight = v
                    }
                    // hasTyped=false なら savedFieldDouble のまま（変更なし）
                case .reps(let si):
                    if fieldHasTyped {
                        session.entries[entryIdx].sets[si].reps = Int(fieldTyped) ?? savedFieldInt
                    }
                default: break
                }
            }
            // 新フィールドの保存値をセット
            fieldTyped = ""
            fieldHasTyped = false
            if let nf = newField {
                switch nf {
                case .weight(let si):
                    guard si < session.entries[entryIdx].sets.count else { break }
                    savedFieldDouble = session.entries[entryIdx].sets[si].weight
                case .reps(let si):
                    guard si < session.entries[entryIdx].sets.count else { break }
                    savedFieldInt = session.entries[entryIdx].sets[si].reps
                default: break
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, timerRunning, let endDate = timerEndDate {
                // フォアグラウンド復帰時に残り時間を再計算
                let remaining = Int(endDate.timeIntervalSinceNow.rounded(.up))
                if remaining > 0 {
                    remainingSeconds = remaining
                } else {
                    // バックグラウンド中に終了していた → リセット
                    stopTimer()
                    remainingSeconds = totalSeconds
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                if focusedField != .timer && focusedField != .memo {
                    Button("完了") {
                        focusedField = nil
                    }
                    .foregroundColor(.gridAccent)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notif in
            if let frame = notif.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = frame.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showEditItem) {
            if let item = entry.flatMap({ vm.item(for: $0.itemId) }) {
                EditItemView(item: item)
                    .environmentObject(vm)
            }
        }
    }

    // MARK: - Set row

    private func setRow(entryIdx: Int, setIdx: Int) -> some View {
        let weightFocused = focusedField == .weight(setIdx)
        let repsFocused   = focusedField == .reps(setIdx)
        let weight = session.entries[entryIdx].sets[setIdx].weight
        let reps   = session.entries[entryIdx].sets[setIdx].reps

        return VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Set number
                Text("\(setIdx + 1)")
                    .font(.gridCaption)
                    .foregroundColor(.gridTextSecondary)
                    .frame(width: 20)

                // ─── Weight ───
                HStack(spacing: 4) {
                    ZStack {
                        // hidden TextField（キーボード入力受け取り）
                        TextField("", text: $fieldTyped)
                            .keyboardType(.decimalPad)
                            .frame(width: 1, height: 1)
                            .opacity(0.01)
                            .focused($focusedField, equals: .weight(setIdx))

                        // 色分け表示
                        Group {
                            if weightFocused {
                                if fieldHasTyped {
                                    Text(fieldTyped.isEmpty ? "0" : fieldTyped)
                                        .foregroundColor(.gridAccent)
                                } else if weight == 0 {
                                    // 新規（値なし）フォーカス中 → ダンベル
                                    Image(systemName: "dumbbell.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gridTextTertiary)
                                } else {
                                    Text(weightDisplayString(weight))
                                        .foregroundColor(.gridTextTertiary)
                                }
                            } else {
                                Text(weight == 0 ? "－" : weightDisplayString(weight))
                                    .foregroundColor(weight == 0 ? .gridTextTertiary : .gridTextPrimary)
                            }
                        }
                        .font(.gridBody)
                        .frame(width: 56)
                        .multilineTextAlignment(.center)
                        .contentShape(Rectangle())
                        .onTapGesture { focusedField = .weight(setIdx) }
                    }
                    Text("Kg")
                        .font(.gridCaption)
                        .foregroundColor(.gridTextSecondary)
                }

                // ─── Reps ───
                HStack(spacing: 4) {
                    ZStack {
                        TextField("", text: $fieldTyped)
                            .keyboardType(.numberPad)
                            .frame(width: 1, height: 1)
                            .opacity(0.01)
                            .focused($focusedField, equals: .reps(setIdx))

                        Group {
                            if repsFocused {
                                if fieldHasTyped {
                                    Text(fieldTyped.isEmpty ? "0" : fieldTyped)
                                        .foregroundColor(.gridAccent)
                                } else if reps == 0 {
                                    // 新規（値なし）フォーカス中 → ダンベル
                                    Image(systemName: "dumbbell.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gridTextTertiary)
                                } else {
                                    Text(String(reps))
                                        .foregroundColor(.gridTextTertiary)
                                }
                            } else {
                                Text(reps == 0 ? "－" : String(reps))
                                    .foregroundColor(reps == 0 ? .gridTextTertiary : .gridTextPrimary)
                            }
                        }
                        .font(.gridBody)
                        .frame(width: 44)
                        .multilineTextAlignment(.center)
                        .contentShape(Rectangle())
                        .onTapGesture { focusedField = .reps(setIdx) }
                    }
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
            .padding(.vertical, 16)

            Divider()
                .background(Color.gridCardInner)
                .padding(.horizontal, 24)
        }
    }

    private func weightDisplayString(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(w)) : String(w)
    }

    // MARK: - Timer panel

    private var timerContainerView: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEditingTimer.toggle()
                        if !isEditingTimer {
                            focusedField  = nil
                            remainingSeconds = totalSeconds
                            timerTyped    = ""
                            timerHasTyped = false
                        }
                    }
                } label: {
                    Image(systemName: isEditingTimer ? "checkmark.circle.fill" : "slider.horizontal.3")
                        .font(.system(size: 20))
                        .foregroundColor(isEditingTimer ? .gridAccent : .gridTextSecondary)
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 2)

            timerPanel
        }
        .background(Color.gridBgPurple)
    }

    private var timerPanel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 24) {
                if isEditingTimer {
                    // 編集モード：−
                    Button {
                        if totalSeconds > 10 {
                            totalSeconds -= 10
                            remainingSeconds = totalSeconds
                            syncTimerFields()
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

                if isEditingTimer {
                    ZStack {
                        // 見えないTextField（キーボード入力キャプチャ用）
                        TextField("", text: $timerTyped)
                            .keyboardType(.numberPad)
                            .frame(width: 1, height: 1)
                            .opacity(0.01)
                            .focused($focusedField, equals: .timer)
                            .onChange(of: timerTyped) { oldVal, newVal in
                                let digits = newVal.filter { $0.isNumber }
                                if digits.count > oldVal.filter({ $0.isNumber }).count {
                                    // 追加
                                    timerHasTyped = true
                                    timerTyped = String(digits.suffix(4))
                                } else {
                                    // 削除
                                    timerTyped = String(digits)
                                }
                                if timerHasTyped { applyTimerInput() }
                            }

                        // 色分けテキスト表示
                        timerColoredDisplay
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                            .onTapGesture { focusedField = .timer }
                    }
                    .onAppear {
                        timerTyped    = ""
                        timerHasTyped = false
                        focusedField  = .timer
                    }
                } else {
                    Text(timeString(remainingSeconds))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(timerRunning ? .white : .gridTextPrimary)
                        .frame(maxWidth: .infinity)
                }

                if isEditingTimer {
                    // 編集モード：＋
                    Button {
                        totalSeconds += 10
                        remainingSeconds = totalSeconds
                        syncTimerFields()
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

    /// 色分けタイマー表示
    private var timerColoredDisplay: some View {
        let font = Font.system(size: 48, weight: .bold, design: .monospaced)
        let gray = Color.gridTextTertiary
        let accent = Color.gridAccent

        if !timerHasTyped {
            // 未入力：既存値をすべてグレーで表示
            let m = totalSeconds / 60
            let s = totalSeconds % 60
            return Text(String(format: "%d:%02d", m, s))
                .font(font).foregroundColor(gray)
        } else {
            // 入力中：先頭の自動ゼロ=グレー、打ち込んだ桁=アクセント
            let typed = timerTyped.filter { $0.isNumber }
            let autoCount = max(0, 4 - typed.count)
            let padded = String(repeating: "0", count: autoCount) + typed
            let d = Array(padded)
            let m1 = String(d[0]); let m2 = String(d[1])
            let s1 = String(d[2]); let s2 = String(d[3])

            func col(_ idx: Int) -> Color { idx < autoCount ? gray : accent }

            return (
                Text(m1).foregroundColor(col(0)) +
                Text(m2).foregroundColor(col(1)) +
                Text(":").foregroundColor(gray) +
                Text(s1).foregroundColor(col(2)) +
                Text(s2).foregroundColor(col(3))
            ).font(font)
        }
    }

    private func applyTimerInput() {
        let digits = timerTyped.filter { $0.isNumber }
        let padded = String(repeating: "0", count: max(0, 4 - digits.count)) + digits
        let m = Int(padded.prefix(2))!
        let s = Int(padded.suffix(2))!
        let total = m * 60 + s
        if total > 0 {
            totalSeconds = total
            remainingSeconds = total
            saveTimerToItem()
        }
    }

    private func syncTimerFields() {
        timerTyped    = ""
        timerHasTyped = false
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
        timerEndDate = Date().addingTimeInterval(Double(remainingSeconds))

        // ローカル通知をスケジュール
        scheduleTimerNotification(after: remainingSeconds)

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            // 終了予定時刻から残り秒数を計算（バックグラウンド復帰後も正確）
            let remaining = Int((timerEndDate?.timeIntervalSinceNow ?? 0).rounded(.up))
            if remaining > 0 {
                remainingSeconds = remaining
            } else {
                stopTimer()
                let soundEnabled = UserDefaults.standard.object(forKey: "timerSoundEnabled") as? Bool ?? true
                if soundEnabled {
                    AudioServicesPlaySystemSound(1057)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        AudioServicesPlaySystemSound(1057)
                    }
                }
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                // 自動リセット（再生ボタンがすぐ使えるように）
                remainingSeconds = totalSeconds
            }
        }
    }

    private func stopTimer() {
        timerRunning = false
        timerEndDate = nil
        timer?.invalidate()
        timer = nil
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["grid_timer"])
    }

    private func scheduleTimerNotification(after seconds: Int) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "GRID"
            content.body = "レストタイマーが終了しました"
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(seconds), repeats: false)
            let request = UNNotificationRequest(identifier: "grid_timer", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
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
