import SwiftUI
import PhotosUI

struct SessionTimelineView: View {
    @EnvironmentObject var vm: AppViewModel

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
    @State private var photoPicker: PhotosPickerItem? = nil

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
                    centerIndex: chartCenterIndex,
                    accentColor: isPurple ? .white.opacity(0.85) : .gridAccent,
                    backgroundColor: isPurple
                        ? Color(red: 0.185, green: 0.170, blue: 0.475)
                        : .gridBg
                )
                .frame(height: 90)

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
            currentIndex = todayIndex
        }
        .onChange(of: photoPicker) { _, newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self),
                      var session = currentSession else { return }
                session.photoData = data
                vm.updateSession(session)
            }
        }
        .fullScreenCover(item: $addMenuSession) { session in
            AddMenuView(session: session)
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
        HStack {
            Image(systemName: "calendar")
                .font(.system(size: 22))
                .foregroundColor(isPurple ? .white.opacity(0.7) : .gridTextSecondary)

            Spacer()

            Text(headerTitle)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.gridTextPrimary)
                .animation(.none, value: currentIndex)

            Spacer()

            if !isToday {
                Button("Today") {
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
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 20)
        .animation(.easeInOut(duration: 0.3), value: isPurple)
    }

    private var headerTitle: String {
        guard let s = currentSession else { return "" }
        if isToday { return "Today" }
        let f = DateFormatter()
        f.dateFormat = "yyyy"
        return f.string(from: s.date)
    }

    // MARK: - セッションカード

    private func sessionCard(session: Session) -> some View {
        let isCurrent = Calendar.current.isDateInToday(session.date)

        return VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("SESSION #\(session.sessionNumber)")
                    .font(.gridSmall)
                    .foregroundColor(isPurple ? .white.opacity(0.65) : .gridTextSecondary)
                    .kerning(1.5)
                Text(session.dateString)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.gridTextPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isCurrent {
                PhotosPicker(selection: $photoPicker, matching: .images) {
                    photoContent(session: session)
                }
            } else {
                photoContent(session: session)
            }

            Button {
                addMenuSession = session
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isCurrent ? "plus.circle" : "doc.text")
                    Text(isCurrent ? "Menu" : "ログを見る")
                        .font(.gridBody)
                }
                .foregroundColor(isPurple ? .white.opacity(0.8) : .gridTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isPurple ? Color.white.opacity(0.12) : Color.gridCardInner)
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
            if let data = session.photoData, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                VStack(spacing: 8) {
                    Image(systemName: Calendar.current.isDateInToday(session.date) ? "plus.circle" : "photo")
                        .font(.system(size: 24))
                    if Calendar.current.isDateInToday(session.date) {
                        Text("Photo")
                            .font(.gridBody)
                    }
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
        VStack(spacing: 2) {
            Text("Weight")
                .font(.gridSmall)
                .foregroundColor(isPurple ? .white.opacity(0.65) : .gridTextSecondary)
                .kerning(1)
            Text(currentSession?.bodyWeight.map { "\($0, specifier: "%.1f")kg" } ?? "-- kg")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.gridTextPrimary)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 12)
        .background(isPurple ? Color.white.opacity(0.12) : Color.gridCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .animation(.easeInOut(duration: 0.35), value: isPurple)
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

#Preview {
    SessionTimelineView()
        .environmentObject(AppViewModel())
}
