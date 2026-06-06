import SwiftUI

struct PhotoGridSection: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var currentIndex: Int = 0
    @State private var showCalendar   = false
    @State private var showFullScreen = false

    /// 日付ごとに先頭1枚のみ、古い順
    private var photos: [AppViewModel.PhotoEntry] {
        var seen = Set<String>()
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return vm.allPhotos
            .sorted { $0.date < $1.date }
            .filter { photo in
                let key = f.string(from: photo.date)
                return seen.insert(key).inserted
            }
    }

    var body: some View {
        if photos.isEmpty {
            Text("写真がありません")
                .font(.gridBody)
                .foregroundColor(.gridTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        } else {
            ZStack(alignment: .topLeading) {
                GeometryReader { geo in
                    let cardW = geo.size.width * 0.68
                    let cardH = cardW * 1.22
                    let cardX = (geo.size.width - cardW) / 2

                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 20) {
                                ForEach(Array(photos.enumerated()), id: \.element.id) { idx, photo in
                                    photoCard(photo: photo, cardW: cardW, cardH: cardH)
                                        .id(photo.id)
                                        .scrollTransition(.animated(.easeInOut(duration: 0.2))) { content, phase in
                                            content
                                                .scaleEffect(phase.isIdentity ? 1.0 : 0.84)
                                                .opacity(phase.isIdentity ? 1.0 : 0.45)
                                        }
                                        .onTapGesture {
                                            vm.navigateToSessionId = photo.sessionId
                                        }
                                }
                                Spacer().frame(height: GRIDLayout.tabBarBottomPadding)
                            }
                            .padding(.horizontal, cardX)
                            .padding(.vertical, (geo.size.height - cardH) / 2)
                        }
                        .onAppear {
                            currentIndex = max(0, photos.count - 1)
                            if let last = photos.last {
                                proxy.scrollTo(last.id, anchor: .center)
                            }
                        }
                        .onChange(of: showCalendar) { _, isShown in
                            if !isShown, let photo = photos[safe: currentIndex] {
                                withAnimation { proxy.scrollTo(photo.id, anchor: .center) }
                            }
                        }
                    }
                }

                // ─── カレンダーボタン（左上）───
                Button { showCalendar = true } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gridTextPrimary)
                        .frame(width: 40, height: 40)
                        .background(Color.gridCard)
                        .clipShape(Circle())
                }
                .padding(.leading, 20)
                .padding(.top, 8)
            }
            .onAppear {
                currentIndex = max(0, photos.count - 1)
            }
            .sheet(isPresented: $showCalendar) {
                PhotoCalendarPicker(photos: photos, currentIndex: $currentIndex)
            }
            .fullScreenCover(isPresented: $showFullScreen) {
                FullScreenPhotoView(photos: photos, currentIndex: $currentIndex)
            }
        }
    }

    private func photoCard(photo: AppViewModel.PhotoEntry, cardW: CGFloat, cardH: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let img = UIImage(data: photo.imageData) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: cardW, height: cardH)
                        .clipped()
                } else {
                    Color.gridCard
                        .frame(width: cardW, height: cardH)
                }
            }

            // ─── 日付ラベル（左下）───
            Text(shortDateString(photo.date))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.4), radius: 14, y: 8)
    }

    private func shortDateString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MM.dd"; return f.string(from: date)
    }
    private func yearString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy"; return f.string(from: date)
    }
    private func monthDayString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MM/dd"; return f.string(from: date)
    }
}

// MARK: - カレンダーピッカー

struct PhotoCalendarPicker: View {
    let photos: [AppViewModel.PhotoEntry]
    @Binding var currentIndex: Int
    @Environment(\.dismiss) var dismiss

    @State private var displayMonth: Date = Date()

    private var photoDates: Set<String> {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return Set(photos.map { f.string(from: $0.date) })
    }

    private var daysInMonth: [Date?] {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: displayMonth)
        guard let first = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: first) else { return [] }
        let weekday = cal.component(.weekday, from: first) - 1
        var days: [Date?] = Array(repeating: nil, count: weekday)
        for day in range {
            days.append(cal.date(byAdding: .day, value: day - 1, to: first))
        }
        return days
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Button {
                        displayMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayMonth) ?? displayMonth
                    } label: {
                        Image(systemName: "chevron.left").foregroundColor(.gridTextPrimary)
                    }
                    Spacer()
                    Text(monthLabel(displayMonth))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.gridTextPrimary)
                    Spacer()
                    Button {
                        displayMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayMonth) ?? displayMonth
                    } label: {
                        Image(systemName: "chevron.right").foregroundColor(.gridTextPrimary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

                let weekdays = ["日","月","火","水","木","金","土"]
                HStack(spacing: 0) {
                    ForEach(weekdays, id: \.self) { d in
                        Text(d).font(.gridCaption).foregroundColor(.gridTextSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                        if let date { dayCell(date: date) }
                        else { Color.clear.frame(height: 44) }
                    }
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .background(Color.gridBg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { dismiss() }.foregroundColor(.gridAccent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func dayCell(date: Date) -> some View {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        let key = f.string(from: date)
        let hasPhoto = photoDates.contains(key)
        let day = Calendar.current.component(.day, from: date)

        return Button {
            if hasPhoto, let idx = photos.lastIndex(where: {
                Calendar.current.isDate($0.date, inSameDayAs: date)
            }) {
                currentIndex = idx
                dismiss()
            }
        } label: {
            VStack(spacing: 3) {
                Text("\(day)")
                    .font(.system(size: 15, weight: hasPhoto ? .bold : .regular))
                    .foregroundColor(hasPhoto ? .gridTextPrimary : .gridTextTertiary)
                Circle().fill(hasPhoto ? Color.gridAccent : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(height: 44).frame(maxWidth: .infinity)
            .background(hasPhoto ? Color.gridAccent.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(!hasPhoto)
    }

    private func monthLabel(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy年 M月"; return f.string(from: date)
    }
}

// MARK: - 全画面写真ビュー

struct FullScreenPhotoView: View {
    let photos: [AppViewModel.PhotoEntry]
    @Binding var currentIndex: Int
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            TabView(selection: $currentIndex) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { idx, photo in
                    if let img = UIImage(data: photo.imageData) {
                        Image(uiImage: img).resizable().scaledToFit().tag(idx)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                    .padding(.top, GRIDLayout.headerTopPadding)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
