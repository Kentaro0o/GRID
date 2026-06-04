import SwiftUI

struct WeightListView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss

    /// 基準セッションに移動するコールバック
    let onNavigate: (Session) -> Void

    @State private var referenceId: UUID? = nil

    private var weightSessions: [Session] {
        vm.sessions
            .filter { $0.bodyWeight != nil }
            .sorted { $0.date < $1.date }
    }

    private var referenceSession: Session? {
        guard let id = referenceId else { return nil }
        return weightSessions.first { $0.id == id }
    }

    var body: some View {
        ZStack {
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
                            Text("基準: \(ref.dateString)  \(w, specifier: "%.1f") kg")
                                .font(.gridBody)
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
                    List {
                        ForEach(weightSessions) { session in
                            weightRow(session: session)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 3, leading: 24, bottom: 3, trailing: 24))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: referenceId == nil)
        .preferredColorScheme(.dark)
    }

    // MARK: - 行

    private func weightRow(session: Session) -> some View {
        guard let w = session.bodyWeight else { return AnyView(EmptyView()) }

        let isRef = session.id == referenceId
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
                    // 日付
                    Text(session.dateString)
                        .font(.gridBody)
                        .foregroundColor(.gridTextSecondary)
                        .frame(width: 56, alignment: .leading)

                    // 体重
                    Text(String(format: "%.1f kg", w))
                        .font(.system(size: 17, weight: .semibold))
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
                .padding(.vertical, 12)
                .background(isRef ? Color.gridAccent.opacity(0.13) : Color.gridCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
    let vm = AppViewModel()
    return WeightListView(onNavigate: { _ in })
        .environmentObject(vm)
}
