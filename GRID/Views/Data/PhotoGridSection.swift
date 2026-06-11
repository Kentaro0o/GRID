import SwiftUI

struct PhotoGridSection: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var tappedSessionId: UUID? = nil

    private var photos: [AppViewModel.PhotoEntry] {
        vm.allPhotos.sorted { $0.date < $1.date }
    }

    private func photosForSession(_ sessionId: UUID) -> [AppViewModel.PhotoEntry] {
        photos.filter { $0.sessionId == sessionId }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        if photos.isEmpty {
            Text("写真がありません")
                .font(.gridBody)
                .foregroundColor(.gridTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(photos) { photo in
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                Group {
                                    if let img = UIImage(data: photo.imageData) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        Color.gridCard
                                    }
                                }
                                .clipped()
                            )
                            .clipped()
                            .contentShape(Rectangle())
                            .onTapGesture {
                                tappedSessionId = photo.sessionId
                            }
                    }
                }
                Spacer().frame(height: GRIDLayout.tabBarBottomPadding)
            }
            .fullScreenCover(item: $tappedSessionId) { sessionId in
                FullScreenPhotoView(
                    photos: photosForSession(sessionId),
                    sessionId: sessionId
                )
                .environmentObject(vm)
            }
        }
    }
}

// MARK: - UUID Identifiable

extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}

// MARK: - 全画面写真ビュー

struct FullScreenPhotoView: View {
    let photos: [AppViewModel.PhotoEntry]
    let sessionId: UUID
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var pageIndex: Int = 0
    @State private var showShareSheet = false

    private var currentPhoto: AppViewModel.PhotoEntry? { photos[safe: pageIndex] }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $pageIndex) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { idx, photo in
                    if let img = UIImage(data: photo.imageData) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .tag(idx)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: photos.count > 1 ? .always : .never))

            VStack {
                HStack {
                    // 共有
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 20)

                    Spacer()

                    if photos.count > 1 {
                        Text("\(pageIndex + 1) / \(photos.count)")
                            .font(.gridCaption)
                            .foregroundColor(.white.opacity(0.8))
                    }

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
                }
                .padding(.top, GRIDLayout.headerTopPadding)

                Spacer()

                HStack {
                    if let photo = currentPhoto {
                        Text(dateString(photo.date))
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    // このセッションへ
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            vm.navigateToSessionId = sessionId
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text("このセッションへ")
                                .font(.gridCaption)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let photo = currentPhoto, let img = UIImage(data: photo.imageData) {
                ShareSheet(items: [img])
            }
        }
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy.MM.dd"; return f.string(from: date)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
