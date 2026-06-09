import SwiftUI

enum DataSection: String, CaseIterable {
    case training = "トレーニング"
    case photo    = "写真"
    case weight   = "体重"
}

struct DataView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var selectedSection: DataSection = .training

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
                .padding(.top, GRIDLayout.headerTopPadding)
                .padding(.bottom, 20)

                // ─── コンテンツ ───
                Group {
                    switch selectedSection {
                    case .photo:
                        PhotoGridSection()
                            .environmentObject(vm)
                    case .weight:
                        WeightSection()
                            .environmentObject(vm)
                    case .training:
                        ExerciseStatsSection()
                            .environmentObject(vm)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .transition(.opacity)
            }
        }
    }
}

// MARK: - 体重セクション（埋め込み用）

struct WeightSection: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var referenceId: UUID? = nil
    @State private var isLatestVisible = true

    private var weightSessions: [Session] {
        vm.sessions
            .filter { $0.bodyWeight != nil }
            .sorted { $0.date < $1.date }
    }

    private var referenceSession: Session? {
        guard let id = referenceId else { return nil }
        return weightSessions.first { $0.id == id }
    }

    private var latestSession: Session? { weightSessions.last }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // ─── チャート ───
                if !weightSessions.isEmpty {
                    WeightScrollChart(sessions: weightSessions, selectedId: $referenceId)
                }

                // ─── 基準ピル（チャート直下）───
                if let ref = referenceSession, let w = ref.bodyWeight {
                    Button {
                        vm.navigateToSessionId = ref.id
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "scope")
                                .font(.system(size: 14))
                            Text("\(ref.dateString)  \(String(format: "%.1f", w)) kg")
                                .font(.gridBody)
                                .lineLimit(1)
                            Spacer()
                            Text("このセッションへ")
                                .font(.gridCaption)
                                .opacity(0.75)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .opacity(0.75)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 13)
                        .background(Color.gridAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    Spacer().frame(height: 12)
                }

                // ─── リスト ───
                if weightSessions.isEmpty {
                    Text("体重の記録がありません")
                        .font(.gridBody)
                        .foregroundColor(.gridTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else {
                    ScrollViewReader { proxy in
                        List {
                            ForEach(weightSessions) { session in
                                weightRow(session: session)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 3, leading: 24, bottom: 3, trailing: 24))
                                    .if(session.id == latestSession?.id) { view in
                                        view
                                            .onAppear  { isLatestVisible = true }
                                            .onDisappear { isLatestVisible = false }
                                    }
                            }
                            Color.clear.frame(height: GRIDLayout.tabBarBottomPadding)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .overlay(alignment: .bottom) {
                            if !isLatestVisible, let latest = latestSession, let w = latest.bodyWeight {
                                latestFloatBar(session: latest, weight: w) {
                                    withAnimation { proxy.scrollTo(latest.id, anchor: .bottom) }
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .animation(.easeInOut(duration: 0.25), value: isLatestVisible)
                        .onAppear {
                            if let id = latestSession?.id {
                                proxy.scrollTo(id, anchor: .bottom)
                            }
                        }
                        .onChange(of: referenceId) { _, id in
                            guard let id else { return }
                            withAnimation { proxy.scrollTo(id, anchor: .center) }
                        }
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: referenceId == nil)
    }

    // MARK: - 最新フロートバー

    private func latestFloatBar(session: Session, weight: Double, onTap: @escaping () -> Void) -> some View {
        let isRef = session.id == referenceId
        let delta: Double? = {
            guard let refW = referenceSession?.bodyWeight, !isRef else { return nil }
            return weight - refW
        }()

        return Button(action: onTap) {
            HStack(spacing: 0) {
                Text("最新")
                    .font(.gridCaption)
                    .foregroundColor(.gridAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.gridAccent.opacity(0.15))
                    .clipShape(Capsule())
                    .padding(.trailing, 10)

                Text(session.dateString)
                    .font(.gridBody)
                    .foregroundColor(.gridTextSecondary)
                    .frame(width: 56, alignment: .leading)

                Text(String(format: "%.1f kg", weight))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.gridTextPrimary)

                Spacer()

                if isRef {
                    Text("基準")
                        .font(.gridCaption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.gridAccent)
                        .clipShape(Capsule())
                } else if let d = delta {
                    Text(deltaText(d))
                        .font(.gridBody)
                        .foregroundColor(deltaColor(d))
                }

                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(.gridTextTertiary)
                    .padding(.leading, 10)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
            .padding(.bottom, GRIDLayout.tabBarBottomPadding)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 通常行

    private func weightRow(session: Session) -> some View {
        guard let w = session.bodyWeight else { return AnyView(EmptyView()) }

        let isToday = Calendar.current.isDateInToday(session.date)
        let isRef   = session.id == referenceId
        let delta: Double? = {
            guard let refW = referenceSession?.bodyWeight, !isRef else { return nil }
            return w - refW
        }()

        return AnyView(
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    referenceId = isRef ? nil : session.id
                }
            } label: {
                HStack(spacing: 0) {
                    Text(isToday ? "今日" : session.dateString)
                        .font(isToday ? .system(size: 15, weight: .bold) : .gridBody)
                        .foregroundColor(isToday ? .gridAccent : .gridTextSecondary)
                        .frame(width: 56, alignment: .leading)

                    Text(String(format: "%.1f kg", w))
                        .font(.system(size: isToday ? 18 : 17, weight: isToday ? .bold : .semibold))
                        .foregroundColor(.gridTextPrimary)

                    Spacer()

                    if isRef {
                        Text("基準")
                            .font(.gridCaption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.gridAccent)
                            .clipShape(Capsule())
                    } else if let d = delta {
                        Text(deltaText(d))
                            .font(.gridBody)
                            .foregroundColor(deltaColor(d))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, isToday ? 14 : 12)
                .background(
                    isRef   ? Color.gridAccent.opacity(0.13) :
                    isToday ? Color.gridAccent.opacity(0.08) :
                              Color.gridCard
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    isToday && !isRef ?
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gridAccent.opacity(0.35), lineWidth: 1)
                    : nil
                )
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.15), value: isRef)
        )
    }

    // MARK: - ヘルパー

    private func deltaText(_ d: Double) -> String {
        let sign = d >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", d)) kg"
    }

    private func deltaColor(_ d: Double) -> Color {
        if abs(d) < 0.05 { return .gridTextTertiary }
        return d > 0 ? Color(red: 1.0, green: 0.4, blue: 0.4) : .gridAccent
    }
}

#Preview {
    DataView()
        .environmentObject(AppViewModel())
}
