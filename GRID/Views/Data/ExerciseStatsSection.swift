import SwiftUI

enum ExerciseDisplayMode: String, CaseIterable {
    case volume    = "ボリューム"
    case maxWeight = "Max重量"
}

struct ExerciseStatsSection: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var showLatest: Bool = true
    @State private var selectedGroup: MuscleGroup = .chest
    @State private var selectedItem: Item? = nil
    @State private var selectedLog: AppViewModel.ExerciseSessionLog? = nil
    @State private var displayMode: ExerciseDisplayMode = .volume
    @State private var chartCenterIndex: Int = 0

    /// 直近セッション（エントリがある最新のもの）
    private var latestSession: Session? {
        vm.sessions.sorted { $0.date > $1.date }.first { !$0.entries.isEmpty }
    }

    /// 直近セッションのエントリを ExerciseSessionLog 形式に変換
    private var latestLogs: [(log: AppViewModel.ExerciseSessionLog, item: Item)] {
        guard let session = latestSession else { return [] }
        return session.entries.compactMap { entry in
            guard let item = vm.item(for: entry.itemId) else { return nil }
            let validSets = entry.sets.filter { $0.reps > 0 }
            guard !validSets.isEmpty, let maxW = validSets.map(\.weight).max() else { return nil }
            let log = AppViewModel.ExerciseSessionLog(
                id: session.id,
                date: session.date,
                dateString: session.dateString,
                maxWeight: maxW,
                sets: validSets,
                memo: entry.memo
            )
            return (log, item)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ─── フィルターチップ（種目未選択時のみ表示）───
            if selectedItem == nil {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // 最新チップ
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showLatest = true
                            selectedItem = nil
                            selectedLog  = nil
                        }
                    } label: {
                        Text("最新")
                            .font(.gridBody)
                            .foregroundColor(showLatest ? .white : .gridTextSecondary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(showLatest ? Color.gridAccent : Color.clear)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(
                                    showLatest ? Color.clear : Color.gridTextSecondary.opacity(0.3),
                                    lineWidth: 1
                                )
                            )
                    }

                    // 筋肉グループチップ
                    ForEach(MuscleGroup.allCases) { group in
                        let isSelected = !showLatest && selectedGroup == group
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showLatest    = false
                                selectedGroup = group
                                selectedItem  = nil
                                selectedLog   = nil
                            }
                        } label: {
                            Text(group.rawValue)
                                .font(.gridBody)
                                .foregroundColor(isSelected ? .white : .gridTextSecondary)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 8)
                                .background(isSelected ? Color.gridAccent : Color.clear)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(
                                        isSelected ? Color.clear : Color.gridTextSecondary.opacity(0.3),
                                        lineWidth: 1
                                    )
                                )
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 12)
            } // end if selectedItem == nil

            if showLatest {
                // ─── 最新セッション ───
                if let log = selectedLog, let item = selectedItem {
                    // 階層3: セット詳細
                    setDetailView(log: log, itemName: item.name)
                } else if let selected = selectedItem {
                    // 階層2: 日付別リスト（全履歴と同じ）
                    if let stat = vm.exerciseStats(for: selected) {
                        exerciseDetailView(stat: stat)
                    }
                } else {
                    // 階層1: 最新セッションの種目リスト
                    latestSessionView
                }
            } else {
                // ─── 全履歴（筋肉グループ別）───
                let stats = vm.exerciseStats(for: selectedGroup)

                if stats.isEmpty {
                    Text("この部位のデータがありません")
                        .font(.gridBody)
                        .foregroundColor(.gridTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .padding(.horizontal, 24)

                } else if let log = selectedLog, let item = selectedItem {
                    setDetailView(log: log, itemName: item.name)

                } else if let selected = selectedItem,
                          let stat = stats.first(where: { $0.item.id == selected.id }) {
                    exerciseDetailView(stat: stat)

                } else {
                    exerciseListView(stats: stats)
                }
            }
        }
    }

    // MARK: - 最新セッション 種目一覧

    private var latestSessionView: some View {
        Group {
            if let session = latestSession, !latestLogs.isEmpty {
                ScrollView {
                    VStack(spacing: 2) {
                        // セッション情報ヘッダー
                        HStack {
                            Text(session.dateString)
                                .font(.gridCaption)
                                .foregroundColor(.gridTextSecondary)
                            Text("SESSION #\(session.sessionNumber)")
                                .font(.gridCaption)
                                .foregroundColor(.gridTextTertiary)
                                .kerning(1)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)

                        ForEach(latestLogs, id: \.item.id) { pair in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedItem = pair.item
                                }
                            } label: {
                                HStack {
                                    Text(pair.item.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.gridTextPrimary)
                                    Spacer()
                                    Text("\(weightText(pair.log.maxWeight)) kg")
                                        .font(.gridBody)
                                        .foregroundColor(.gridTextSecondary)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13))
                                        .foregroundColor(.gridTextTertiary)
                                        .padding(.leading, 4)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color.gridCard)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 24)
                        }
                        Spacer().frame(height: GRIDLayout.tabBarBottomPadding)
                    }
                    .padding(.top, 4)
                }
            } else {
                Text("トレーニング記録がありません")
                    .font(.gridBody)
                    .foregroundColor(.gridTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - 全履歴 種目一覧

    private func exerciseListView(stats: [AppViewModel.ExerciseStat]) -> some View {
        ScrollView {
            VStack(spacing: 2) {
                ForEach(stats, id: \.item.id) { stat in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedItem = stat.item
                        }
                    } label: {
                        HStack {
                            Text(stat.item.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gridTextPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundColor(.gridTextTertiary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color.gridCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                }
                Spacer().frame(height: GRIDLayout.tabBarBottomPadding)
            }
            .padding(.top, 4)
        }
    }

    // MARK: - 階層2: 日付別リスト

    private func exerciseDetailView(stat: AppViewModel.ExerciseStat) -> some View {
        let logs        = vm.sessionLogs(for: stat.item)
        let isBodyweight = stat.item.type == .bodyweight
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let recentLogs  = logs.filter { $0.date >= oneMonthAgo }

        // 自重：最大回数で比較
        let bestMaxReps   = logs.map { $0.sets.map(\.reps).max() ?? 0 }.max() ?? 0
        let recentMaxReps = recentLogs.map { $0.sets.map(\.reps).max() ?? 0 }.max()

        // ベスト & 直近ベストのログを両モードで取得
        let bestLog: AppViewModel.ExerciseSessionLog? = isBodyweight
            ? logs.max { ($0.sets.map(\.reps).max() ?? 0) < ($1.sets.map(\.reps).max() ?? 0) }
            : displayMode == .volume
                ? logs.max { volumeOf($0) < volumeOf($1) }
                : logs.first { $0.maxWeight == stat.allTimeMax }

        let recentBestLog: AppViewModel.ExerciseSessionLog? = isBodyweight
            ? recentLogs.max { ($0.sets.map(\.reps).max() ?? 0) < ($1.sets.map(\.reps).max() ?? 0) }
            : displayMode == .volume
                ? recentLogs.max { volumeOf($0) < volumeOf($1) }
                : recentLogs.max { $0.maxWeight < $1.maxWeight }

        // 表示値
        let bestVal: String = isBodyweight
            ? "\(bestMaxReps) 回"
            : displayMode == .volume ? volumeText(logs.map { volumeOf($0) }.max() ?? 0)
                                     : String(format: "%.1f kg", stat.allTimeMax)
        let recentVal: String = isBodyweight
            ? recentMaxReps.map { "\($0) 回" } ?? "—"
            : displayMode == .volume
                ? recentLogs.map { volumeOf($0) }.max().map { volumeText($0) } ?? "—"
                : stat.recentMonthMax.map { String(format: "%.1f kg", $0) } ?? "—"

        // チャートジャンプ用ヘルパー
        func jumpChart(to log: AppViewModel.ExerciseSessionLog?) {
            guard let log, let idx = logs.firstIndex(where: { $0.id == log.id }) else { return }
            withAnimation(.easeInOut(duration: 0.2)) { chartCenterIndex = idx }
        }

        return VStack(alignment: .leading, spacing: 0) {
            // ヘッダー
            backButton(title: stat.item.name) { selectedItem = nil }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)

            // ① ボリューム / Max重量 セレクター（自重は非表示）
            if !isBodyweight {
                displayModeSelector
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
            }

            if logs.isEmpty {
                Text("データがありません")
                    .font(.gridBody)
                    .foregroundColor(.gridTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .padding(.horizontal, 24)
            } else {
                // ② チャート固定
                scrollableChart(logs: logs)
                    .padding(.bottom, 4)

                // ③ スクロール領域（ベストチップ＋日付リスト）
                ScrollViewReader { listProxy in
                    ScrollView {
                        VStack(spacing: 2) {
                            // ベスト / 直近1ヶ月のベスト チップ
                            HStack(spacing: 12) {
                                tappableStatChip(label: "ベスト", value: bestVal,
                                                 hasTarget: bestLog != nil) {
                                    jumpChart(to: bestLog)
                                }
                                tappableStatChip(label: "直近1ヶ月のベスト", value: recentVal,
                                                 hasTarget: recentBestLog != nil) {
                                    jumpChart(to: recentBestLog)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 8)
                            .padding(.top, 4)

                            ForEach(Array(logs.enumerated()), id: \.element.id) { idx, log in
                                let isBest        = log.id == bestLog?.id
                                let isChartCenter = idx == chartCenterIndex
                                HStack(spacing: 0) {
                                    // 左：チャート同期ボタン
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            chartCenterIndex = idx
                                        }
                                    } label: {
                                        Image(systemName: "chart.line.uptrend.xyaxis")
                                            .font(.system(size: 12))
                                            .foregroundColor(isChartCenter
                                                ? Color(red: 0.4, green: 0.8, blue: 1.0)
                                                : .gridTextTertiary.opacity(0.4))
                                            .frame(width: 40)
                                            .frame(maxHeight: .infinity)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)

                                    // 右：セット詳細へ
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) { selectedLog = log }
                                    } label: {
                                        HStack(spacing: 0) {
                                            Text(log.dateString)
                                                .font(.gridBody)
                                                .foregroundColor(.gridTextSecondary)
                                                .frame(width: 72, alignment: .leading)
                                            Text(isBodyweight
                                                 ? "\(log.sets.map(\.reps).max() ?? 0) 回"
                                                 : displayMode == .volume
                                                     ? volumeText(volumeOf(log))
                                                     : String(format: "%.1f kg", log.maxWeight))
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.gridTextPrimary)
                                            Spacer()
                                            if isChartCenter {
                                                badge(text: "チャート", color: Color(red: 0.4, green: 0.8, blue: 1.0))
                                            } else if isBest {
                                                badge(text: "Best", color: .gridAccent)
                                            }
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gridTextTertiary)
                                                .padding(.leading, 10)
                                        }
                                        .padding(.trailing, 20)
                                        .padding(.vertical, 13)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                                .background(
                                    isChartCenter ? Color(red: 0.4, green: 0.8, blue: 1.0).opacity(0.15) :
                                    isBest        ? Color.gridAccent.opacity(0.10) :
                                                    Color.gridCard
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal, 24)
                                .id(log.id)
                            }
                            Spacer().frame(height: GRIDLayout.tabBarBottomPadding)
                        }
                        .padding(.top, 4)
                    }
                    .onChange(of: chartCenterIndex) { _, idx in
                        guard idx < logs.count else { return }
                        withAnimation { listProxy.scrollTo(logs[idx].id, anchor: .center) }
                    }
                }
            }
        }
    }

    /// タップでチャートジャンプできるサマリーチップ
    private func tappableStatChip(label: String, value: String,
                                   hasTarget: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(label)
                        .font(.gridCaption)
                        .foregroundColor(.gridTextSecondary)
                    if hasTarget {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 9))
                            .foregroundColor(.gridTextTertiary)
                    }
                }
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.gridTextPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gridCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                hasTarget
                    ? RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gridTextTertiary.opacity(0.2), lineWidth: 1)
                    : nil
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 表示モードセレクター

    private var displayModeSelector: some View {
        HStack(spacing: 0) {
            ForEach(ExerciseDisplayMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { displayMode = mode }
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: 13, weight: displayMode == mode ? .semibold : .regular))
                        .foregroundColor(displayMode == mode ? .white : .gridTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(displayMode == mode ? Color.gridAccent : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.gridCard)
        .clipShape(RoundedRectangle(cornerRadius: 11))
    }

    // MARK: - 横スクロールチャート

    private let chartItemWidth: CGFloat = 56
    private let chartHPad: CGFloat = 24

    private func scrollableChart(logs: [AppViewModel.ExerciseSessionLog]) -> some View {
        let isBodyweight = selectedItem?.type == .bodyweight
        let values: [Double] = isBodyweight
            ? logs.map { Double($0.sets.map(\.reps).max() ?? 0) }
            : logs.map { displayMode == .volume ? volumeOf($0) : $0.maxWeight }
        let maxVal = (values.max() ?? 1)
        let minVal = (values.min() ?? 0)
        let range  = max(maxVal - minVal, 1)
        let chartH: CGFloat  = 110
        let labelH: CGFloat  = 18
        let plotH: CGFloat   = chartH - labelH
        let totalW: CGFloat  = chartItemWidth * CGFloat(values.count) + chartHPad * 2

        // 各インデックスの中心X・Y座標を計算するヘルパー
        func xPos(_ i: Int) -> CGFloat {
            chartHPad + chartItemWidth * CGFloat(i) + chartItemWidth / 2
        }
        func yPos(_ v: Double) -> CGFloat {
            plotH * (1 - CGFloat((v - minVal) / range) * 0.8 - 0.1)
        }

        return ScrollViewReader { chartProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    // ─── Canvas：線＋ドットを一括描画 ───
                    Canvas { ctx, size in
                        if values.count >= 2 {
                            var linePath = Path()
                            linePath.move(to: CGPoint(x: xPos(0), y: yPos(values[0])))
                            for i in 1..<values.count {
                                linePath.addLine(to: CGPoint(x: xPos(i), y: yPos(values[i])))
                            }
                            ctx.stroke(linePath, with: .color(Color.gridAccent.opacity(0.55)), lineWidth: 1.5)
                        }
                        for (i, v) in values.enumerated() {
                            let cx = xPos(i), cy = yPos(v)
                            let isCenter = i == chartCenterIndex
                            let r: CGFloat = isCenter ? 5 : 3.5
                            let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
                            ctx.fill(Path(ellipseIn: rect), with: .color(Color.gridBg))
                            ctx.fill(Path(ellipseIn: rect),
                                     with: .color(isCenter ? Color.gridAccent : Color.gridAccent.opacity(0.55)))
                        }
                    }
                    .frame(width: totalW, height: plotH)

                    // ─── タップ領域＋日付ラベル ───
                    HStack(spacing: 0) {
                        ForEach(Array(values.enumerated()), id: \.offset) { i, _ in
                            VStack(spacing: 0) {
                                Color.clear
                                    .frame(width: chartItemWidth, height: plotH)
                                Text(logs[i].date.formatted(.dateTime.month().day()))
                                    .font(.system(size: 10))
                                    .foregroundColor(i == chartCenterIndex ? .gridAccent : .gridTextTertiary)
                                    .frame(width: chartItemWidth, height: labelH)
                            }
                            .id(i)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) { chartCenterIndex = i }
                            }
                        }
                    }
                    .padding(.horizontal, chartHPad)
                }
                .frame(width: totalW, height: chartH)
            }
            .frame(height: chartH)
            .onAppear {
                chartCenterIndex = max(0, logs.count - 1)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation { chartProxy.scrollTo(chartCenterIndex, anchor: .center) }
                }
            }
            .onChange(of: chartCenterIndex) { _, idx in
                withAnimation { chartProxy.scrollTo(idx, anchor: .center) }
            }
            .onChange(of: logs.count) { _, count in chartCenterIndex = max(0, count - 1) }
        }
    }

    // MARK: - 階層3: セット詳細

    private func setDetailView(log: AppViewModel.ExerciseSessionLog, itemName: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 戻るボタン + 日付 / このセッションへ
            HStack {
                backButton(title: log.dateString) {
                    selectedLog = nil
                }
                Spacer()
                Button {
                    vm.navigateToSessionId = log.id
                } label: {
                    HStack(spacing: 5) {
                        Text("このセッションへ")
                            .font(.gridCaption)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.gridAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gridAccent.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            // セット一覧
            ScrollView {
                VStack(spacing: 12) {
                    // セットカード
                    VStack(spacing: 0) {
                        ForEach(Array(log.sets.enumerated()), id: \.element.id) { idx, set in
                            VStack(spacing: 0) {
                                HStack(spacing: 16) {
                                    // セット番号
                                    Text("\(idx + 1)")
                                        .font(.gridCaption)
                                        .foregroundColor(.gridTextSecondary)
                                        .frame(width: 20)

                                    // 重量
                                    HStack(spacing: 4) {
                                        Text(weightText(set.weight))
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundColor(.gridTextPrimary)
                                        Text("kg")
                                            .font(.gridCaption)
                                            .foregroundColor(.gridTextSecondary)
                                    }
                                    .frame(width: 80, alignment: .leading)

                                    // 回数
                                    HStack(spacing: 4) {
                                        Text("\(set.reps)")
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundColor(.gridTextPrimary)
                                        Text("回")
                                            .font(.gridCaption)
                                            .foregroundColor(.gridTextSecondary)
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)

                                if idx < log.sets.count - 1 {
                                    Divider()
                                        .background(Color.gridCardInner)
                                        .padding(.horizontal, 24)
                                }
                            }
                        }
                    }
                    .background(Color.gridCard)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // サマリー（自重は回数のみ）
                    HStack(spacing: 12) {
                        if selectedItem?.type == .bodyweight {
                            statChip(label: "最大回数", value: "\(log.sets.map(\.reps).max() ?? 0) 回")
                            statChip(label: "セット数", value: "\(log.sets.count) セット")
                        } else {
                            statChip(label: "ボリューム", value: volumeText(volumeOf(log)))
                            statChip(label: "Max重量", value: String(format: "%.1f kg", log.maxWeight))
                        }
                    }

                    // メモ（あれば）
                    if !log.memo.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("メモ")
                                .font(.gridCaption)
                                .foregroundColor(.gridTextSecondary)
                            Text(log.memo)
                                .font(.gridBody)
                                .foregroundColor(.gridTextPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Color.gridCard)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Spacer().frame(height: GRIDLayout.tabBarBottomPadding)
                }
                .padding(.horizontal, 24)
                .padding(.top, 4)
            }
        }
    }

    // MARK: - ヘルパー

    private func backButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.gridTextPrimary)
        }
        .buttonStyle(.plain)
    }

    private func statChip(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.gridCaption)
                .foregroundColor(.gridTextSecondary)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.gridTextPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gridCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func badge(text: String, color: Color) -> some View {
        Text(text)
            .font(.gridCaption)
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

    /// ボリューム計算（重量 × 回数 の全セット合計）
    private func volumeOf(_ log: AppViewModel.ExerciseSessionLog) -> Double {
        log.sets.reduce(0) { $0 + $1.weight * Double($1.reps) }
    }

    /// ボリュームの表示文字列（常にkg）
    private func volumeText(_ vol: Double) -> String {
        String(format: "%.0f kg", vol)
    }

    private func weightText(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", w)
            : String(format: "%.1f", w)
    }
}
