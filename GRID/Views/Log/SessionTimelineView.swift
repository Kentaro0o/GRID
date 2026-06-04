import SwiftUI
import PhotosUI

struct SessionTimelineView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.scenePhase) private var scenePhase

    private var sessions: [Session] {
        vm.sessions.sorted { $0.date < $1.date }
    }

    private var todayIndex: Int {
        sessions.firstIndex { Calendar.current.isDateInToday($0.date) } ?? 0
    }

    @State private var currentIndex: Int = 0
    @State private var isPurple: Bool = false
    @State private var dwellTimer: Timer? = nil
    @State private var addMenuSession: Session? = nil
    @State private var sessionToDelete: Session? = nil
    @State private var photoPicker: [PhotosPickerItem] = []
    @State private var showAddCalendar = false
    @State private var showWeightInput = false
    @State private var weightInputText = ""
    @State private var showPhotoSourceDialog = false
    @State private var showCamera = false
    @State private var showLibraryPicker = false
    @State private var cameraImageData: Data? = nil
    @State private var showPhotoViewer = false
    @State private var photoViewerInitialIndex = 0
    @AppStorage("saveCameraPhotoToRoll") private var saveCameraPhotoToRoll = true

    // ─── チャート高速スクロール ───
    @State private var isFastScroll = false
    @State private var chartDragBaseIndex: Int = 0
    @State private var longPressWork: DispatchWorkItem? = nil
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let impactFeedback    = UIImpactFeedbackGenerator(style: .heavy)

    private var currentSession: Session? {
        sessions[safe: currentIndex]
    }

    private var isToday: Bool {
        guard let s = currentSession else { return false }
        return Calendar.current.isDateInToday(s.date)
    }

    private var chartCenterIndex: Int {
        guard let s = currentSession else { return 0 }
        return vm.weightChartData.firstIndex {
            Calendar.current.isDate($0.0, inSameDayAs: s.date)
        } ?? 0
    }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                // ─── カードカルーセル ───
                TabView(selection: $currentIndex) {
                    ForEach(Array(sessions.enumerated()), id: \.element.id) { i, session in
                        sessionCard(session: session)
                            .tag(i)
                            .padding(.horizontal, 28)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 380)
                .onChange(of: currentIndex) { _, newIdx in
                    onPageChanged(newIdx)
                }

                Spacer()

                // ─── チャート (中央揃え) ───
                WeightLineChart(
                    data: vm.weightChartData,
                    knownWeightDates: Set(vm.sessions.compactMap { $0.bodyWeight != nil ? $0.date : nil }),
                    centerIndex: chartCenterIndex,
                    accentColor: isPurple ? .white.opacity(0.85) : .gridAccent,
                    backgroundColor: isPurple
                        ? Color(red: 0.185, green: 0.170, blue: 0.475)
                        : .gridBg
                )
                .frame(height: 90)
                .scaleEffect(isFastScroll ? 1.04 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isFastScroll)
                .contentShape(Rectangle())
                .gesture(chartFastScrollGesture)

                // ─── 体重ピル ───
                HStack {
                    Spacer()
                    weightPill
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            _ = vm.ensureTodaySession()  // 今日のセッションが必ず存在する状態にする
            currentIndex = todayIndex
        }
        .onChange(of: photoPicker) { _, items in
            Task {
                guard var session = currentSession else { return }
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        session.photosData.append(data)
                    }
                }
                vm.updateSession(session)
                photoPicker = []
            }
        }
        .fullScreenCover(item: $addMenuSession) { session in
            AddMenuView(session: session)
                .environmentObject(vm)
        }
        // 写真なし → 追加ダイアログ
        .confirmationDialog("写真を追加", isPresented: $showPhotoSourceDialog, titleVisibility: .visible) {
            Button("カメラで撮影") { showCamera = true }
            Button("カメラロールから選択") { showLibraryPicker = true }
            Button("キャンセル", role: .cancel) {}
        }
        .photosPicker(isPresented: $showLibraryPicker, selection: $photoPicker, maxSelectionCount: 10, matching: .images)
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(imageData: $cameraImageData, saveToRoll: saveCameraPhotoToRoll)
                .ignoresSafeArea()
        }
        .onChange(of: cameraImageData) { _, data in
            guard let data, var session = currentSession else { return }
            session.photosData.append(data)
            vm.updateSession(session)
            cameraImageData = nil
        }
        // 写真あり → 全画面ビューア
        .fullScreenCover(isPresented: $showPhotoViewer) {
            if let idx = sessions.firstIndex(where: { $0.id == currentSession?.id }) {
                PhotoViewerView(
                    photosData: Binding(
                        get: { vm.sessions.first(where: { $0.id == sessions[safe: idx]?.id })?.photosData ?? [] },
                        set: { newData in
                            if var s = vm.sessions.first(where: { $0.id == sessions[safe: idx]?.id }) {
                                s.photosData = newData
                                vm.updateSession(s)
                            }
                        }
                    ),
                    initialIndex: photoViewerInitialIndex
                )
            }
        }
        .alert("体重を入力", isPresented: $showWeightInput) {
            TextField("例: 72.5", text: $weightInputText)
                .keyboardType(.decimalPad)
            Button("保存") {
                if let w = Double(weightInputText), var session = currentSession {
                    session.bodyWeight = (w * 10).rounded() / 10
                    vm.updateSession(session)
                }
            }
            Button("キャンセル", role: .cancel) {}
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                vm.removeEmptySessions()
            }
        }
        .alert("このログを削除しますか？", isPresented: Binding(
            get: { sessionToDelete != nil },
            set: { if !$0 { sessionToDelete = nil } }
        )) {
            Button("削除", role: .destructive) {
                if let s = sessionToDelete {
                    vm.deleteSession(s)
                    sessionToDelete = nil
                }
            }
            Button("キャンセル", role: .cancel) { sessionToDelete = nil }
        }
        .sheet(isPresented: $showAddCalendar) {
            TrainingCalendarSheet(mode: .add) { date in
                let existing = vm.sessions.first {
                    Calendar.current.isDate($0.date, inSameDayAs: date)
                }
                if let existing,
                   let idx = sessions.firstIndex(where: { $0.id == existing.id }) {
                    // 既存記録 → タイムラインに移動
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentIndex = idx
                    }
                } else {
                    // 新規作成 → タイムラインに移動
                    let s = Session(
                        sessionNumber: (vm.sessions.map { $0.sessionNumber }.max() ?? 0) + 1,
                        date: date
                    )
                    vm.updateSession(s)
                    if let idx = sessions.firstIndex(where: { $0.id == s.id }) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentIndex = idx
                        }
                    }
                }
            }
            .environmentObject(vm)
        }
    }

    // MARK: - 背景

    private var background: some View {
        Group {
            if isPurple {
                LinearGradient(
                    colors: [
                        Color(red: 0.22, green: 0.20, blue: 0.55),
                        Color(red: 0.15, green: 0.14, blue: 0.40),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Color.gridBg
            }
        }
        .animation(.easeInOut(duration: 0.45), value: isPurple)
    }

    // MARK: - ヘッダー

    private var header: some View {
        ZStack {
            Text(headerTitle)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.gridTextPrimary)
                .frame(maxWidth: .infinity)
                .animation(.none, value: currentIndex)

            HStack {
                // 左：カレンダーボタン + 過去追加ボタン
                Button {
                    showAddCalendar = true
                } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 22))
                        .foregroundColor(isPurple ? .white.opacity(0.7) : .gridTextSecondary)
                }

                Spacer()

                // 右：Todayボタン（今日以外のとき）
                if !isToday {
                    Button("今日") {
                        _ = vm.ensureTodaySession()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentIndex = todayIndex
                        }
                    }
                    .font(.gridBody)
                    .foregroundColor(.gridTextPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isPurple ? Color.white.opacity(0.4) : Color.gridTextSecondary.opacity(0.5),
                                lineWidth: 1
                            )
                    )
                } else {
                    Color.clear.frame(width: 70, height: 32)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 20)
        .animation(.easeInOut(duration: 0.3), value: isPurple)
    }

    private var headerTitle: String {
        guard let s = currentSession else { return "" }
        if isToday { return "今日" }
        let f = DateFormatter()
        f.dateFormat = "yyyy"
        return f.string(from: s.date)
    }

    // MARK: - セッションカード

    private func sessionCard(session: Session) -> some View {
        let isCurrent = Calendar.current.isDateInToday(session.date)

        let muscleGroups = vm.muscleGroups(for: session)

        return VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("SESSION #\(session.sessionNumber)")
                    .font(.gridSmall)
                    .foregroundColor(isPurple ? .white.opacity(0.65) : .gridTextSecondary)
                    .kerning(1.5)
                HStack(alignment: .bottom, spacing: 10) {
                    Text(session.dateString)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.gridTextPrimary)

                    if !muscleGroups.isEmpty {
                        MuscleGroupChipsView(groups: muscleGroups, isPurple: isPurple)
                            .padding(.bottom, 5)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                if session.photosData.isEmpty {
                    showPhotoSourceDialog = true
                } else {
                    photoViewerInitialIndex = 0
                    showPhotoViewer = true
                }
            } label: {
                photoContent(session: session)
            }
            .buttonStyle(.plain)

            let hasLog = !session.entries.isEmpty
            let isSessionToday = Calendar.current.isDateInToday(session.date)
            HStack(spacing: 10) {
                Button {
                    addMenuSession = session
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: hasLog ? "doc.text" : "plus.circle")
                        Text(hasLog ? "ログを見る" : "ログを追加")
                            .font(.gridBody)
                    }
                    .foregroundColor(isPurple ? .white.opacity(0.8) : (!hasLog ? .gridAccent : .gridTextSecondary))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isPurple ? Color.white.opacity(0.12) : (!hasLog ? Color.gridAccent.opacity(0.15) : Color.gridCardInner))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if !isSessionToday {
                    Button {
                        sessionToDelete = session
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(isPurple ? .white.opacity(0.5) : .gridTextTertiary)
                            .frame(width: 44, height: 44)
                            .background(isPurple ? Color.white.opacity(0.08) : Color.gridCardInner)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding(20)
        .background(isPurple ? Color.white.opacity(0.10) : Color.gridCard)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .background(
            Group {
                if isCurrent {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(isPurple ? Color.white.opacity(0.04) : Color.gridCard.opacity(0.5))
                            .offset(x: -12, y: -6)
                            .scaleEffect(0.94)
                        RoundedRectangle(cornerRadius: 22)
                            .fill(isPurple ? Color.white.opacity(0.07) : Color.gridCard.opacity(0.7))
                            .offset(x: -6, y: -3)
                            .scaleEffect(0.97)
                    }
                }
            }
        )
        .animation(.easeInOut(duration: 0.35), value: isPurple)
    }

    @ViewBuilder
    private func photoContent(session: Session) -> some View {
        Group {
            if let data = session.photosData.first, let ui = UIImage(data: data) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                    if session.photosData.count > 1 {
                        Text("\(session.photosData.count)")
                            .font(.gridCaption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Capsule())
                            .padding(8)
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 28))
                }
                .foregroundColor(isPurple ? .white.opacity(0.4) : .gridTextSecondary)
            }
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .background(isPurple ? Color.white.opacity(0.08) : Color.gridCardInner)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - 体重ピル

    private var weightPill: some View {
        let hasWeight = currentSession?.bodyWeight != nil

        return Button {
            weightInputText = currentSession?.bodyWeight.map { String($0) } ?? ""
            showWeightInput = true
        } label: {
            VStack(spacing: 2) {
                Text("Weight")
                    .font(.gridSmall)
                    .foregroundColor(isPurple ? .white.opacity(0.65) : .gridTextSecondary)
                    .kerning(1)
                if hasWeight {
                    Text("\(currentSession!.bodyWeight!, specifier: "%.1f") kg")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.gridTextPrimary)
                } else {
                    Text("+ KG")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(isPurple ? .white.opacity(0.5) : .gridAccent)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(isPurple ? Color.white.opacity(0.12) : Color.gridCard)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.35), value: isPurple)
    }

    // MARK: - チャート高速スクロールジェスチャー

    private var chartFastScrollGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                // 長押しタイマー起動（初回のみ）
                if longPressWork == nil && !isFastScroll {
                    chartDragBaseIndex = currentIndex
                    selectionFeedback.prepare()
                    impactFeedback.prepare()
                    let work = DispatchWorkItem {
                        isFastScroll = true
                        impactFeedback.impactOccurred()
                    }
                    longPressWork = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
                }

                // 高速モード中のみ追従
                guard isFastScroll else { return }
                let delta  = value.location.x - value.startLocation.x
                let offset = Int(-delta / 16)
                let newIdx = max(0, min(sessions.count - 1, chartDragBaseIndex + offset))
                if newIdx != currentIndex {
                    selectionFeedback.selectionChanged()
                    withAnimation(.easeInOut(duration: 0.12)) {
                        currentIndex = newIdx
                    }
                }
            }
            .onEnded { _ in
                longPressWork?.cancel()
                longPressWork = nil
                isFastScroll = false
            }
    }

    // MARK: - ページ変更ハンドラ

    private func onPageChanged(_ newIdx: Int) {
        dwellTimer?.invalidate()
        isPurple = false

        let session = sessions[safe: newIdx]
        guard let session, !Calendar.current.isDateInToday(session.date) else { return }

        dwellTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.45)) {
                isPurple = true
            }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - 過去セッション追加シート

struct AddPastSessionSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedDate: Date
    let onConfirm: (Date) -> Void

    var body: some View {
        ZStack {
            Color.gridBg.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("過去のログを追加")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.gridTextPrimary)
                    Spacer()
                    Button("キャンセル") { dismiss() }
                        .foregroundColor(.gridAccent)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 20)

                DatePicker(
                    "日付を選択",
                    selection: $selectedDate,
                    in: ...Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(.gridAccent)
                .environment(\.locale, Locale(identifier: "ja_JP"))
                .padding(.horizontal, 16)

                Spacer()

                Button {
                    onConfirm(selectedDate)
                    dismiss()
                } label: {
                    Text("この日のログを追加")
                        .font(.gridHeadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.gridAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - トレーニングカレンダーシート

struct TrainingCalendarSheet: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss

    enum Mode { case view, add }
    let mode: Mode
    let onSelectDate: (Date) -> Void

    @State private var displayMonth = Date()
    @State private var selectedDate: Date? = nil
    private let cal = Calendar(identifier: .gregorian)

    private var daysInMonth: [Date?] {
        guard let range = cal.range(of: .day, in: .month, for: displayMonth),
              let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: displayMonth))
        else { return [] }

        var weekday = cal.component(.weekday, from: firstDay) - 1 // 0=日
        // 月曜始まりに変換
        weekday = (weekday + 6) % 7
        return Array(repeating: nil, count: weekday) + range.map { d -> Date? in
            cal.date(byAdding: .day, value: d - 1, to: firstDay)
        }
    }

    private func session(for date: Date) -> Session? {
        vm.sessions.first { cal.isDate($0.date, inSameDayAs: date) }
    }

    private var monthLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年 M月"
        return f.string(from: displayMonth)
    }

    var body: some View {
        ZStack {
            Color.gridBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // ヘッダー
                HStack {
                    Text("カレンダー")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.gridTextPrimary)
                    Spacer()
                    Button("閉じる") { dismiss() }
                        .foregroundColor(.gridAccent)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 16)

                // 月ナビゲーション
                HStack {
                    Button {
                        displayMonth = cal.date(byAdding: .month, value: -1, to: displayMonth) ?? displayMonth
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.gridAccent)
                            .frame(width: 36, height: 36)
                    }

                    Spacer()

                    Text(monthLabel)
                        .font(.gridHeadline)
                        .foregroundColor(.gridTextPrimary)

                    Spacer()

                    Button {
                        let next = cal.date(byAdding: .month, value: 1, to: displayMonth) ?? displayMonth
                        if next <= Date() { displayMonth = next }
                    } label: {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gridAccent)
                            .frame(width: 36, height: 36)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                // 曜日ヘッダー
                HStack(spacing: 0) {
                    ForEach(["月","火","水","木","金","土","日"], id: \.self) { d in
                        Text(d)
                            .font(.gridSmall)
                            .foregroundColor(.gridTextSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                // 日付グリッド
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                    ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                        if let date {
                            dayCell(date: date)
                        } else {
                            Color.clear.frame(height: 44)
                        }
                    }
                }
                .padding(.horizontal, 16)

                Spacer()

                // 記録なし日付が選択されている時の確認ボタン
                if let selected = selectedDate {
                    let f: DateFormatter = {
                        let f = DateFormatter()
                        f.locale = Locale(identifier: "ja_JP")
                        f.dateFormat = "M月d日"
                        return f
                    }()
                    Button {
                        onSelectDate(selected)
                        dismiss()
                    } label: {
                        Text("\(f.string(from: selected))の記録を追加")
                            .font(.gridHeadline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.gridAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedDate == nil)
        .preferredColorScheme(.dark)
    }

    private func dayCell(date: Date) -> some View {
        let s = session(for: date)
        let hasLog = !(s?.entries.isEmpty ?? true)
        let isToday = cal.isDateInToday(date)
        let isFuture = date > Date()

        let isPast = date < Date() && !isToday
        let isSelectable = mode == .add ? isPast : (s != nil && !isFuture)
        let isSelected = selectedDate.map { cal.isDate($0, inSameDayAs: date) } ?? false

        return Button {
            guard isSelectable else { return }
            if mode == .add && !hasLog {
                // 記録なし → 選択状態へ（同じ日を再タップで解除）
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedDate = isSelected ? nil : date
                }
            } else {
                // 記録あり → 即時確定
                onSelectDate(date)
                dismiss()
            }
        } label: {
            ZStack {
                // 選択中（記録なし）
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gridAccent.opacity(0.35))
                }
                // トレーニング記録あり → アクセントカラー背景
                else if hasLog {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gridAccent.opacity(0.25))
                }
                // 今日 → 枠線
                if isToday {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gridAccent, lineWidth: 1.5)
                }

                VStack(spacing: 2) {
                    Text("\(cal.component(.day, from: date))")
                        .font(.system(size: 15, weight: (hasLog || isSelected) ? .semibold : .regular))
                        .foregroundColor(
                            isFuture   ? .gridTextTertiary :
                            isSelected ? .white :
                            hasLog     ? .gridAccent :
                            isToday    ? .gridTextPrimary :
                                         .gridTextSecondary
                        )

                    // ログありの場合は小さいドット
                    if hasLog {
                        Circle()
                            .fill(Color.gridAccent)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 44)
            }
        }
        .disabled(!isSelectable)
    }
}

// MARK: - MuscleGroupChipsView

struct MuscleGroupChipsView: View {
    let groups: [MuscleGroup]
    let isPurple: Bool

    // 1チップの推定幅：1文字(12pt) + 水平padding(10*2) + 少しの余裕
    private let chipWidth: CGFloat = 34
    private let spacing: CGFloat = 6
    private let ellipsisWidth: CGFloat = 30

    var body: some View {
        GeometryReader { geo in
            let available = geo.size.width
            let (visible, hasMore) = visibleCount(in: available)

            HStack(spacing: spacing) {
                ForEach(groups.prefix(visible)) { group in
                    chip(group.rawValue)
                }
                if hasMore {
                    chip("…")
                }
            }
        }
        .frame(height: 24)
    }

    private func visibleCount(in width: CGFloat) -> (Int, Bool) {
        let total = groups.count
        var usedWidth: CGFloat = 0
        var count = 0

        for i in 0..<total {
            let w = chipWidth + (count > 0 ? spacing : 0)
            let remaining = total - i - 1
            // 次のチップが入らない場合、「…」のスペースが必要
            let needsEllipsis = remaining > 0
            let extra = needsEllipsis ? (ellipsisWidth + spacing) : 0

            if usedWidth + w + extra <= width {
                usedWidth += w
                count += 1
            } else {
                return (count, true)
            }
        }
        return (count, false)
    }

    @ViewBuilder
    private func chip(_ label: String) -> some View {
        Text(label)
            .font(.gridCaption)
            .foregroundColor(isPurple ? .white.opacity(0.85) : .gridAccent)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(isPurple ? Color.white.opacity(0.15) : Color.gridAccent.opacity(0.18))
            .clipShape(Capsule())
    }
}

#Preview {
    SessionTimelineView()
        .environmentObject(AppViewModel())
}
