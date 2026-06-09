import SwiftUI

/// 種目ごとのセッションログ一覧と詳細を表示するシート
struct ItemSessionLogView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) private var dismiss

    let item: Item

    @State private var selectedLog: AppViewModel.ExerciseSessionLog? = nil

    private var logs: [AppViewModel.ExerciseSessionLog] {
        vm.sessionLogs(for: item)
    }
    private var allTimeMax: Double {
        logs.map(\.maxWeight).max() ?? 0
    }
    private var bestLogId: UUID? {
        logs.first { $0.maxWeight == allTimeMax }?.id
    }

    var body: some View {
        ZStack {
            Color.gridBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // ─── ヘッダー ───
                HStack {
                    if let _ = selectedLog {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedLog = nil
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(item.name)
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.gridTextPrimary)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text(item.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.gridTextPrimary)
                    }

                    Spacer()

                    Button("閉じる") { dismiss() }
                        .font(.gridBody)
                        .foregroundColor(.gridAccent)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 16)

                if let log = selectedLog {
                    setDetailView(log: log)
                } else {
                    logListView
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - 日付一覧

    private var logListView: some View {
        Group {
            if logs.isEmpty {
                VStack {
                    Spacer()
                    Text("記録がありません")
                        .font(.gridBody)
                        .foregroundColor(.gridTextSecondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(logs.reversed()) { log in
                            let isBest = log.id == bestLogId
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

                                    Text(weightText(log.maxWeight))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.gridTextPrimary)
                                    Text(" kg")
                                        .font(.gridCaption)
                                        .foregroundColor(.gridTextSecondary)

                                    Spacer()

                                    if isBest {
                                        Text("Best")
                                            .font(.gridCaption)
                                            .foregroundColor(.gridAccent)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Color.gridAccent.opacity(0.15))
                                            .clipShape(Capsule())
                                    }

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gridTextTertiary)
                                        .padding(.leading, 10)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 13)
                                .background(isBest ? Color.gridAccent.opacity(0.10) : Color.gridCard)
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

    // MARK: - セット詳細

    private func setDetailView(log: AppViewModel.ExerciseSessionLog) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                // セットカード
                VStack(spacing: 0) {
                    ForEach(Array(log.sets.enumerated()), id: \.element.id) { idx, set in
                        VStack(spacing: 0) {
                            HStack(spacing: 16) {
                                Text("\(idx + 1)")
                                    .font(.gridCaption)
                                    .foregroundColor(.gridTextSecondary)
                                    .frame(width: 20)

                                HStack(spacing: 4) {
                                    Text(weightText(set.weight))
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.gridTextPrimary)
                                    Text("kg")
                                        .font(.gridCaption)
                                        .foregroundColor(.gridTextSecondary)
                                }
                                .frame(width: 80, alignment: .leading)

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

                // メモ
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
                    dismiss()
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

    private func weightText(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", w)
            : String(format: "%.1f", w)
    }
}
