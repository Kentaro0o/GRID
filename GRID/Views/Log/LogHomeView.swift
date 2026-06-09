import SwiftUI
import PhotosUI

struct LogHomeView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.scenePhase) private var scenePhase

    @State private var session: Session = Session(sessionNumber: 1, date: Date())
    @State private var calendarExpanded = false
    @State private var calendarMonth: Date = Date()

    // タイムライン表示（左スライドイン）
    @State private var showTimeline = false
    @State private var timelineSessionId: UUID? = nil
    @State private var timelineStartIndex: Int? = nil

    @State private var showItemPicker = false
    @State private var isEditing = false
    @State private var showOther = false

    @State private var weightInputText = ""
    @State private var showWeightInput = false
    @State private var showPhotoSourceDialog = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showPhotoViewer = false
    @State private var photoPicker: [PhotosPickerItem] = []
    @State private var cameraImageData: Data? = nil

    @State private var navPath = NavigationPath()

    @FocusState private var memoFocused: Bool
    @AppStorage("saveCameraPhotoToRoll") private var saveCameraPhotoToRoll = true

    private var entriesByMuscle: [(MuscleGroup, [WorkoutEntry])] {
        vm.entriesByMuscle(for: session)
    }
    private var muscleGroups: [MuscleGroup] {
        vm.muscleGroups(for: session)
    }

    var body: some View {
        ZStack {
            // ─── メインコンテンツ ───
            NavigationStack(path: $navPath) {
                ZStack {
                    Color.gridBgPurple.ignoresSafeArea()

                    VStack(spacing: 0) {
                        // カレンダーを最上部に
                        calendarSection
                            .padding(.top, GRIDLayout.headerTopPadding)
                            .padding(.bottom, 4)

                        // セッションヘッダー
                        headerView

                        // ─── セッション内容 ───
                        List {
                            exerciseListSections
                            memoSection
                            otherListSection
                            bottomSpacerRow
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
                    }
                }
                .navigationBarHidden(true)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        if memoFocused {
                            Button("完了") { memoFocused = false }
                                .foregroundColor(.gridAccent)
                        }
                    }
                }
                .navigationDestination(for: WorkoutEntry.self) { entry in
                    AddItemView(session: $session, entryId: entry.id)
                        .environmentObject(vm)
                }
                .sheet(isPresented: $showItemPicker) {
                    ItemPickerSheet(session: $session)
                        .environmentObject(vm)
                }
                .alert("体重を入力", isPresented: $showWeightInput) {
                    TextField("82.5", text: $weightInputText)
                        .keyboardType(.decimalPad)
                    Button("保存") {
                        if let w = Double(weightInputText), !weightInputText.isEmpty {
                            session.bodyWeight = w
                        } else {
                            session.bodyWeight = nil
                        }
                        vm.updateSession(session)
                    }
                    Button("キャンセル", role: .cancel) {}
                }
                .confirmationDialog("写真を追加", isPresented: $showPhotoSourceDialog) {
                    Button("カメラで撮影") { showCamera = true }
                    Button("ライブラリから選択") { showPhotoPicker = true }
                    Button("キャンセル", role: .cancel) {}
                }
                .photosPicker(isPresented: $showPhotoPicker, selection: $photoPicker, matching: .images)
                .onChange(of: photoPicker) { _, items in
                    Task {
                        for item in items {
                            if let data = try? await item.loadTransferable(type: Data.self) {
                                session.photosData.append(data)
                            }
                        }
                        photoPicker = []
                        vm.updateSession(session)
                    }
                }
                .fullScreenCover(isPresented: $showPhotoViewer) {
                    PhotoViewerView(photosData: $session.photosData)
                }
                .fullScreenCover(isPresented: $showCamera) {
                    CameraView(imageData: $cameraImageData, saveToRoll: saveCameraPhotoToRoll)
                        .ignoresSafeArea()
                }
                .onChange(of: cameraImageData) { _, data in
                    if let data {
                        session.photosData.append(data)
                        vm.updateSession(session)
                        cameraImageData = nil
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background { vm.removeEmptySessions() }
                    if phase == .active { refreshSession() }
                }
                .onChange(of: vm.sessions) { _, _ in
                    refreshSession()
                }
            }

            // ─── タイムライン（左スライドイン）───
            if showTimeline {
                ZStack {
                    Color.gridBg.ignoresSafeArea()
                    SessionTimelineView(
                        showBackButton: true,
                        initialSessionId: timelineSessionId,
                        onBack: {
                            withAnimation(.easeInOut(duration: 0.3)) { showTimeline = false }
                        },
                        startIndex: timelineStartIndex
                    )
                    .environmentObject(vm)
                }
                .transition(.move(edge: .leading))
                .zIndex(1)
            }
        }
        .onAppear {
            refreshSession()
            // 他タブからジャンプ：LogHomeが表示される前にセット済みの場合
            if let sessionId = vm.navigateToSessionId {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    openTimeline(targetSessionId: sessionId)
                    vm.navigateToSessionId = nil
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showTimeline)
        .onChange(of: vm.logTabTappedCount) { _, _ in
            if showTimeline {
                withAnimation(.easeInOut(duration: 0.3)) { showTimeline = false }
            }
        }
        .onChange(of: vm.navigateToSessionId) { _, sessionId in
            // LogHomeが既に表示されている間に値がセットされた場合
            guard let sessionId else { return }
            openTimeline(targetSessionId: sessionId)
            vm.navigateToSessionId = nil
        }
    }

    // MARK: - ヘッダー

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // セッション情報
            VStack(alignment: .leading, spacing: 4) {
                Text("SESSION #\(session.sessionNumber)")
                    .font(.gridSmall)
                    .foregroundColor(.gridTextSecondary)
                    .kerning(1.5)
                Text("今日 \(session.fullDateString)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.gridTextPrimary)

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
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 16)

            // 追加 / 編集ボタン（AddMenuViewと同じスタイル）
            HStack(spacing: 10) {
                Button {
                    isEditing = false
                    showItemPicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle")
                        Text("追加")
                            .font(.gridBody)
                    }
                    .foregroundColor(.gridTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.gridCardInner)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                if !entriesByMuscle.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { isEditing.toggle() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: isEditing ? "checkmark.circle" : "pencil")
                            Text(isEditing ? "完了" : "編集")
                                .font(.gridBody)
                        }
                        .foregroundColor(isEditing ? .white : .gridTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isEditing ? Color.gridAccent : Color.gridCardInner)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
    }

    // MARK: - カレンダーバー

    private var calendarSection: some View {
        VStack(spacing: 0) {
            if calendarExpanded {
                expandedCalendar
                    .transition(.move(edge: .top).combined(with: .opacity))
            } else {
                compactCalendar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: calendarExpanded)
    }

    // コンパクト：直近10日の円ストリップ
    private var compactCalendar: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let days: [Date] = (0..<10).reversed().compactMap {
            cal.date(byAdding: .day, value: -$0, to: today)
        }
        let sessionDates = Set(vm.sessions.map { cal.startOfDay(for: $0.date) })

        return HStack(spacing: 8) {
            // 左：スイッチアイコン（タイムラインへ）
            Button {
                openTimeline()
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gridTextSecondary)
                    .frame(width: 36, height: 36)
                    .background(Color.gridCard)
                    .clipShape(Circle())
            }
            .padding(.leading, 24)

            // 右：日付ストリップ（スクロール）＋末尾にカレンダーアイコン
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // 先頭：カレンダー展開ボタン（左にスクロールすると現れる）
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            calendarExpanded = true
                        }
                    } label: {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(.gridTextSecondary)
                            .frame(width: 36, height: 36)
                            .background(Color.gridCard)
                            .clipShape(Circle())
                    }

                    ForEach(days, id: \.self) { day in
                        dayCell(day: day, sessionDates: sessionDates, cal: cal, today: today)
                    }
                }
                .padding(.leading, 24)
                .padding(.trailing, 24)
            }
            .defaultScrollAnchor(.trailing)
        }
        .padding(.vertical, 4)
    }

    private func dayCell(day: Date, sessionDates: Set<Date>, cal: Calendar, today: Date) -> some View {
        let isToday = cal.isDate(day, inSameDayAs: today)
        let hasSession = sessionDates.contains(day)
        let dayNum = cal.component(.day, from: day)
        let weekday = shortWeekday(for: day)

        return Button {
            if !isToday {
                let targetId = vm.sessions.first {
                    cal.isDate($0.date, inSameDayAs: day)
                }?.id
                if targetId != nil || hasSession {
                    openTimeline(targetSessionId: targetId)
                }
            }
        } label: {
            VStack(spacing: 3) {
                Text(weekday)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(isToday ? .white.opacity(0.8) : .gridTextTertiary)

                Text("\(dayNum)")
                    .font(.system(size: 14, weight: isToday ? .bold : .regular))
                    .foregroundColor(isToday ? .white : (hasSession ? .gridTextPrimary : .gridTextTertiary))

                // トレーニングドット
                Circle()
                    .fill(hasSession ? (isToday ? Color.white.opacity(0.7) : Color.gridAccent) : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(width: 38, height: 52)
            .background(isToday ? Color.gridAccent : (hasSession ? Color.gridCard : Color.clear))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    // 展開カレンダー：月ビュー
    private var expandedCalendar: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let sessionDates = Set(vm.sessions.map { cal.startOfDay(for: $0.date) })
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: calendarMonth))!
        let daysInMonth = cal.range(of: .day, in: .month, for: monthStart)!.count
        let firstWeekday = (cal.component(.weekday, from: monthStart) + 5) % 7 // 月曜始まり
        let totalCells = firstWeekday + daysInMonth
        let rows = Int(ceil(Double(totalCells) / 7.0))

        return VStack(spacing: 0) {
            // 月ナビ
            HStack {
                Button {
                    calendarMonth = cal.date(byAdding: .month, value: -1, to: calendarMonth)!
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gridTextSecondary)
                        .frame(width: 32, height: 32)
                }

                Spacer()

                Text(monthTitle(calendarMonth))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.gridTextPrimary)

                Spacer()

                Button {
                    if !cal.isDate(calendarMonth, equalTo: today, toGranularity: .month) {
                        calendarMonth = cal.date(byAdding: .month, value: 1, to: calendarMonth)!
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundColor(cal.isDate(calendarMonth, equalTo: today, toGranularity: .month)
                                         ? .gridTextTertiary : .gridTextSecondary)
                        .frame(width: 32, height: 32)
                }

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        calendarExpanded = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gridTextTertiary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            // 曜日ヘッダー
            HStack(spacing: 0) {
                ForEach(["月","火","水","木","金","土","日"], id: \.self) { w in
                    Text(w)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gridTextTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)

            // 日付グリッド
            VStack(spacing: 4) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<7) { col in
                            let cellIndex = row * 7 + col
                            let dayOffset = cellIndex - firstWeekday
                            if dayOffset >= 0 && dayOffset < daysInMonth {
                                let date = cal.date(byAdding: .day, value: dayOffset, to: monthStart)!
                                let dayStart = cal.startOfDay(for: date)
                                let isToday = cal.isDate(dayStart, inSameDayAs: today)
                                let isFuture = dayStart > today
                                let hasSession = sessionDates.contains(dayStart)

                                Button {
                                    if !isFuture {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                            calendarExpanded = false
                                        }
                                        if !isToday {
                                            let targetId = vm.sessions.first {
                                                cal.isDate($0.date, inSameDayAs: date)
                                            }?.id
                                            if targetId != nil || hasSession {
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                                    openTimeline(targetSessionId: targetId)
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    VStack(spacing: 2) {
                                        Text("\(cal.component(.day, from: date))")
                                            .font(.system(size: 13, weight: isToday ? .bold : .regular))
                                            .foregroundColor(isToday ? .white : (isFuture ? .gridTextTertiary.opacity(0.4) : (hasSession ? .gridTextPrimary : .gridTextTertiary)))
                                        Circle()
                                            .fill(hasSession ? (isToday ? Color.white.opacity(0.7) : Color.gridAccent) : Color.clear)
                                            .frame(width: 4, height: 4)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(isToday ? Color.gridAccent : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                                .disabled(isFuture)
                            } else {
                                Color.clear
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(Color.gridCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    // MARK: - List セクション

    @ViewBuilder
    private var exerciseListSections: some View {
        ForEach(entriesByMuscle, id: \.0) { group, entries in
            Section {
                ForEach(entries) { entry in
                    entryRow(entry: entry)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .onMove { from, to in moveEntries(in: group, from: from, to: to) }
                .onDelete { idxSet in deleteEntries(in: group, at: idxSet) }
            } header: {
                Text(group.rawValue)
                    .font(.gridSmall)
                    .foregroundColor(.gridTextSecondary)
                    .kerning(1.2)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 6)
                    .textCase(nil)
                    .listRowInsets(EdgeInsets())
            }
        }
    }

    private var memoSection: some View {
        Section {
            memoEditor
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
    }

    private var memoEditor: some View {
        TextEditor(text: $session.memo)
            .font(.gridBody)
            .foregroundColor(.gridTextPrimary)
            .frame(minHeight: 80)
            .padding(12)
            .scrollContentBackground(.hidden)
            .focused($memoFocused)
            .background(Color.gridCardInner)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(alignment: .topLeading) {
                if session.memo.isEmpty {
                    Text("メモ")
                        .font(.gridBody)
                        .foregroundColor(.gridTextTertiary)
                        .padding(16)
                        .allowsHitTesting(false)
                }
            }
            .onChange(of: session.memo) { _, _ in vm.updateSession(session) }
    }

    private var otherListSection: some View {
        Section {
            otherSection
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
    }

    private var bottomSpacerRow: some View {
        Color.clear.frame(height: GRIDLayout.tabBarBottomPadding)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }

    // MARK: - タイムラインナビ行

    private var timelineNavRow: some View {
        Button {
            openTimeline()
        } label: {
            HStack {
                Text("すべてのセッション")
                    .font(.gridBody)
                    .foregroundColor(.gridTextSecondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(.gridTextTertiary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    // MARK: - 種目行

    private func entryRow(entry: WorkoutEntry) -> some View {
        let itemName = vm.item(for: entry.itemId)?.name ?? "Unknown"
        return VStack(spacing: 0) {
            HStack(spacing: 14) {
                Text(itemName)
                    .font(.gridBody)
                    .foregroundColor(.gridTextPrimary)
                Spacer()
                if !isEditing {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundColor(.gridTextTertiary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
            .onTapGesture {
                if !isEditing { navPath.append(entry) }
            }

            Divider()
                .background(Color.gridCardInner)
                .padding(.horizontal, 24)
        }
    }

    // MARK: - その他セクション

    private var otherSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showOther.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: showOther ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gridTextSecondary)
                    Text("その他")
                        .font(.gridBody)
                        .foregroundColor(.gridTextSecondary)
                }
            }
            .buttonStyle(.plain)

            if showOther {
                GeometryReader { geo in
                    let hasPhoto = !session.photosData.isEmpty
                    let squareSize = (geo.size.width - 12) / 2
                    HStack(spacing: 12) {
                        // 体重
                        Button {
                            weightInputText = session.bodyWeight.map { String($0) } ?? ""
                            showWeightInput = true
                        } label: {
                            if hasPhoto {
                                VStack(spacing: 6) {
                                    Image(systemName: "scalemass").font(.system(size: 22))
                                    if let w = session.bodyWeight {
                                        Text(String(format: "%.1f kg", w)).font(.system(size: 15, weight: .semibold))
                                    } else {
                                        Text("体重").font(.gridBody)
                                    }
                                }
                                .foregroundColor(session.bodyWeight != nil ? .gridAccent : .gridTextSecondary)
                                .frame(width: squareSize, height: squareSize)
                                .background(session.bodyWeight != nil ? Color.gridAccent.opacity(0.12) : Color.gridCardInner)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: "scalemass").font(.system(size: 15))
                                    if let w = session.bodyWeight {
                                        Text(String(format: "%.1f kg", w)).font(.gridBody)
                                    } else {
                                        Text("体重").font(.gridBody)
                                    }
                                }
                                .foregroundColor(session.bodyWeight != nil ? .gridAccent : .gridTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(session.bodyWeight != nil ? Color.gridAccent.opacity(0.12) : Color.gridCardInner)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .buttonStyle(.plain)

                        // 写真
                        if hasPhoto, let first = session.photosData.first, let img = UIImage(data: first) {
                            Button { showPhotoViewer = true } label: {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: squareSize, height: squareSize)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                    if session.photosData.count > 1 {
                                        Text("\(session.photosData.count)")
                                            .font(.gridCaption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Color.black.opacity(0.5))
                                            .clipShape(Capsule())
                                            .padding(6)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(LongPressGesture().onEnded { _ in showPhotoSourceDialog = true })
                        } else {
                            Button { showPhotoSourceDialog = true } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "camera").font(.system(size: 15))
                                    Text("写真").font(.gridBody)
                                }
                                .foregroundColor(.gridTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.gridCardInner)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(height: session.photosData.isEmpty ? 44 : (UIScreen.main.bounds.width - 48 - 12) / 2)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, showOther ? 8 : 0)
    }

    // MARK: - タイムライン表示ヘルパー

    private func openTimeline(targetSessionId: UUID? = nil) {
        let sorted = vm.sessions.sorted { $0.date < $1.date }
        if let targetId = targetSessionId,
           let idx = sorted.firstIndex(where: { $0.id == targetId }) {
            timelineSessionId = targetId
            timelineStartIndex = idx
        } else {
            // 今日
            let todayIdx = sorted.firstIndex { Calendar.current.isDateInToday($0.date) }
            timelineSessionId = nil
            timelineStartIndex = todayIdx
        }
        withAnimation(.easeInOut(duration: 0.3)) { showTimeline = true }
    }

    // MARK: - ヘルパー

    private func refreshSession() {
        _ = vm.ensureTodaySession()
        if let s = vm.sessions.first(where: { Calendar.current.isDateInToday($0.date) }) {
            session = s
        }
    }

    private func moveEntries(in group: MuscleGroup, from source: IndexSet, to destination: Int) {
        let groupEntryIds = entriesByMuscle.first(where: { $0.0 == group })?.1.map { $0.id } ?? []
        var ids = groupEntryIds
        ids.move(fromOffsets: source, toOffset: destination)
        var newEntries = session.entries.filter { !groupEntryIds.contains($0.id) }
        let sorted = ids.compactMap { id in session.entries.first { $0.id == id } }
        let insertIdx = session.entries.firstIndex(where: { groupEntryIds.contains($0.id) }) ?? newEntries.count
        newEntries.insert(contentsOf: sorted, at: min(insertIdx, newEntries.count))
        session.entries = newEntries
        vm.updateSession(session)
    }

    private func deleteEntries(in group: MuscleGroup, at indexSet: IndexSet) {
        let groupEntries = entriesByMuscle.first(where: { $0.0 == group })?.1 ?? []
        let ids = indexSet.map { groupEntries[$0].id }
        session.entries.removeAll { ids.contains($0.id) }
        vm.updateSession(session)
    }

    private func shortWeekday(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "E"
        return f.string(from: date)
    }

    private func monthTitle(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月"
        return f.string(from: date)
    }
}
