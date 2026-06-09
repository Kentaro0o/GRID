import SwiftUI

struct ExerciseStatsSection: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var selectedGroup: MuscleGroup = .chest
    @State private var selectedItem: Item? = nil
    @State private var selectedLog: AppViewModel.ExerciseSessionLog? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ─── 筋肉グループ チップ ───
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(MuscleGroup.allCases) { group in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedGroup = group
                                selectedItem  = nil
                                selectedLog   = nil
                            }
                        } label: {
                            Text(group.rawValue)
                                .font(.gridBody)
                                .foregroundColor(selectedGroup == group ? .white : .gridTextSecondary)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 8)
                                .background(selectedGroup == group ? Color.gridAccent : Color.clear)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(
                                        selectedGroup == group ? Color.clear : Color.gridTextSecondary.opacity(0.3),
                                        lineWidth: 1
                                    )
                                )
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 12)

            let stats = vm.exerciseStats(for: selectedGroup)

            if stats.isEmpty {
                Text("この部位のデータがありません")
                    .font(.gridBody)
                    .foregroundColor(.gridTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .padding(.horizontal, 24)

            } else if let log = selectedLog,
                      let item = selectedItem {
                // ─── 階層3: セット詳細 ───
                setDetailView(log: log, itemName: item.name)

            } else if let selected = selectedItem,
                      let stat = stats.first(where: { $0.item.id == selected.id }) {
                // ─── 階層2: 日付別リスト ───
                exerciseDetailView(stat: stat)

            } else {
                // ─── 階層1: 種目一覧 ───
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
        }
    }

    // MARK: - 階層2: 日付別リスト

    private func exerciseDetailView(stat: AppViewModel.ExerciseStat) -> some View {
        let logs       = vm.sessionLogs(for: stat.item)
        let allTimeMax = stat.allTimeMax
        let recentMax  = stat.recentMonthMax
        let bestLog    = logs.first { $0.maxWeight == allTimeMax }
        let recentLog: AppViewModel.ExerciseSessionLog? = recentMax.flatMap { rm in
            logs.first { $0.maxWeight == rm }
        }

        return VStack(alignment: .leading, spacing: 0) {
            // 戻るボタン + 種目名
            backButton(title: stat.item.name) {
                selectedItem = nil
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 14)

            // ベスト / 直近1ヶ月Max チップ
            HStack(spacing: 12) {
                statChip(label: "ベストパフォーマンス",
                         value: String(format: "%.1f kg", allTimeMax))
                statChip(label: "直近1ヶ月のMax",
                         value: recentMax.map { String(format: "%.1f kg", $0) } ?? "—")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            // 日付別リスト
            if logs.isEmpty {
                Text("データがありません")
                    .font(.gridBody)
                    .foregroundColor(.gridTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .padding(.horizontal, 24)
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(logs) { log in
                            let isBest   = log.id == bestLog?.id
                            let isRecent = !isBest && log.id == recentLog?.id

                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedLog = log
                                }
                            } label: {
                                HStack(spacing: 0) {
                                    Text(log.dateString)
                                        .font(.gridBody)
                                        .foregroundColor(.gridTextSecondary)
                                        .frame(width: 72, alignment: .leading)

                                    Text(String(format: "%.1f kg", log.maxWeight))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.gridTextPrimary)

                                    Spacer()

                                    if isBest {
                                        badge(text: "Best", color: .gridAccent)
                                    } else if isRecent {
                                        badge(text: "Max", color: Color(red: 1.0, green: 0.6, blue: 0.2))
                                    }

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gridTextTertiary)
                                        .padding(.leading, 10)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 13)
                                .background(
                                    isBest   ? Color.gridAccent.opacity(0.10) :
                                    isRecent ? Color.orange.opacity(0.08) :
                                               Color.gridCard
                                )
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
        }
    }

    // MARK: - 階層3: セット詳細

    private func setDetailView(log: AppViewModel.ExerciseSessionLog, itemName: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 戻るボタン + 日付
            backButton(title: log.dateString) {
                selectedLog = nil
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

                    // このセッションへボタン
                    Button {
                        vm.navigateToSessionId = log.id
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 15))
                            Text("このセッションへ")
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .opacity(0.7)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Color.gridAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

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

    private func weightText(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", w)
            : String(format: "%.1f", w)
    }
}
