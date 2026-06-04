import SwiftUI

struct WeightListView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss

    let onNavigate: (Session) -> Void

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
            Color.gridBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // ─── ヘッダー ───
                HStack {
                    Text("体重記録")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.gridTextPrimary)
                    Spacer()
                    Button("閉じる") { dismiss() }
                        .font(.gridBody)
                        .foregroundColor(.gridAccent)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 16)

                // ─── 基準ピル（選択中のみ表示）───
                if let ref = referenceSession, let w = ref.bodyWeight {
                    Button {
                        onNavigate(ref)
                        dismiss()
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
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // ─── リスト ───
                if weightSessions.isEmpty {
                    Spacer()
                    Text("体重の記録がありません")
                        .font(.gridBody)
                        .foregroundColor(.gridTextSecondary)
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        List {
                            ForEach(weightSessions) { session in
                                weightRow(session: session)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 3, leading: 24, bottom: 3, trailing: 24))
                                    // 最新行の可視状態を追跡
                                    .if(session.id == latestSession?.id) { view in
                                        view
                                            .onAppear  { isLatestVisible = true }
                                            .onDisappear { isLatestVisible = false }
                                    }
                            }
                            // フロートが出る場合の余白
                            Color.clear.frame(height: isLatestVisible ? 0 : 80)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        // ─── フロート最新行 ───
                        .overlay(alignment: .bottom) {
                            if !isLatestVisible, let latest = latestSession, let w = latest.bodyWeight {
                                latestFloatBar(session: latest, weight: w) {
                                    withAnimation {
                                        proxy.scrollTo(latest.id, anchor: .bottom)
                                    }
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .animation(.easeInOut(duration: 0.25), value: isLatestVisible)
                        .onAppear {
                            // 初回表示時は最下部へスクロール
                            if let id = latestSession?.id {
                                proxy.scrollTo(id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: referenceId == nil)
        .preferredColorScheme(.dark)
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
                // 最新ラベル
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
            .padding(.bottom, 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 通常行

    private func weightRow(session: Session) -> some View {
        guard let w = session.bodyWeight else { return AnyView(EmptyView()) }

        let isToday  = Calendar.current.isDateInToday(session.date)
        let isRef    = session.id == referenceId
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
                    // 日付（今日は「今日」表示）
                    Text(isToday ? "今日" : session.dateString)
                        .font(isToday ? .system(size: 15, weight: .bold) : .gridBody)
                        .foregroundColor(isToday ? .gridAccent : .gridTextSecondary)
                        .frame(width: 56, alignment: .leading)

                    // 体重
                    Text(String(format: "%.1f kg", w))
                        .font(.system(size: isToday ? 18 : 17, weight: isToday ? .bold : .semibold))
                        .foregroundColor(.gridTextPrimary)

                    Spacer()

                    // 差分 or 基準バッジ
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
                    isRef    ? Color.gridAccent.opacity(0.13) :
                    isToday  ? Color.gridAccent.opacity(0.08) :
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

// MARK: - View 条件付き modifier ヘルパー

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}

#Preview {
    let vm = AppViewModel()
    return WeightListView(onNavigate: { _ in })
        .environmentObject(vm)
}
