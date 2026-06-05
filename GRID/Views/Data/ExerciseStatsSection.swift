import SwiftUI

struct ExerciseStatsSection: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var selectedGroup: MuscleGroup = .chest

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ─── フィルター ───
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(MuscleGroup.allCases) { group in
                        Button { selectedGroup = group } label: {
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
            .padding(.bottom, 16)

            // ─── 種目リスト ───
            let stats = vm.exerciseStats(for: selectedGroup)

            if stats.isEmpty {
                Text("この部位のデータがありません")
                    .font(.gridBody)
                    .foregroundColor(.gridTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                VStack(spacing: 10) {
                    ForEach(stats, id: \.item.id) { stat in
                        exerciseCard(stat: stat)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func exerciseCard(stat: AppViewModel.ExerciseStat) -> some View {
        VStack(spacing: 0) {
            // 種目名
            HStack {
                Text(stat.item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gridTextPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Divider().background(Color.gridCardInner)

            // MAX 数値
            HStack(spacing: 0) {
                statCell(
                    label: "全期間 MAX",
                    value: String(format: "%.1f kg", stat.allTimeMax)
                )
                Divider()
                    .frame(width: 1)
                    .background(Color.gridCardInner)
                statCell(
                    label: "直近1ヶ月 MAX",
                    value: stat.recentMonthMax.map { String(format: "%.1f kg", $0) } ?? "—"
                )
            }
            .padding(.vertical, 12)
        }
        .background(Color.gridCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func statCell(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.gridCaption)
                .foregroundColor(.gridTextSecondary)
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.gridTextPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}
