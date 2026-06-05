import SwiftUI

enum DataSection: String, CaseIterable {
    case photo    = "写真"
    case weight   = "体重"
    case training = "トレーニング"
}

struct DataView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var selectedSection: DataSection = .photo
    @State private var showWeightList = false

    var body: some View {
        ZStack {
            Color.gridBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // ─── ヘッダー ───
                HStack(alignment: .center, spacing: 0) {
                    Text("DATA")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.gridTextPrimary)

                    Spacer()

                    // セクション切り替えチップ
                    HStack(spacing: 6) {
                        ForEach(DataSection.allCases, id: \.self) { section in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedSection = section
                                }
                            } label: {
                                Text(section.rawValue)
                                    .font(.gridBody)
                                    .foregroundColor(selectedSection == section ? .white : .gridTextSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(selectedSection == section ? Color.gridAccent : Color.clear)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(
                                            selectedSection == section ? Color.clear : Color.gridTextSecondary.opacity(0.3),
                                            lineWidth: 1
                                        )
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 20)

                // ─── コンテンツ ───
                Group {
                    switch selectedSection {
                    case .photo:
                        PhotoGridSection()
                            .environmentObject(vm)
                    case .weight:
                        weightSection
                    case .training:
                        ExerciseStatsSection()
                            .environmentObject(vm)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showWeightList) {
            WeightListView(onNavigate: { _ in })
                .environmentObject(vm)
        }
    }

    // MARK: - 体重セクション

    private var weightSection: some View {
        let sessions = vm.sessions
            .filter { $0.bodyWeight != nil }
            .sorted { $0.date < $1.date }

        return ScrollView {
            VStack(spacing: 8) {
                ForEach(sessions) { session in
                    if let w = session.bodyWeight {
                        let isToday = Calendar.current.isDateInToday(session.date)
                        HStack {
                            Text(isToday ? "今日" : session.dateString)
                                .font(isToday ? .system(size: 15, weight: .bold) : .gridBody)
                                .foregroundColor(isToday ? .gridAccent : .gridTextSecondary)
                                .frame(width: 56, alignment: .leading)
                            Text(String(format: "%.1f kg", w))
                                .font(.system(size: isToday ? 18 : 17, weight: isToday ? .bold : .semibold))
                                .foregroundColor(.gridTextPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, isToday ? 14 : 11)
                        .background(isToday ? Color.gridAccent.opacity(0.08) : Color.gridCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            isToday ?
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gridAccent.opacity(0.35), lineWidth: 1)
                            : nil
                        )
                    }
                }

                if sessions.isEmpty {
                    Text("体重の記録がありません")
                        .font(.gridBody)
                        .foregroundColor(.gridTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                }

                Spacer().frame(height: 100)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
    }
}

#Preview {
    DataView()
        .environmentObject(AppViewModel())
}
