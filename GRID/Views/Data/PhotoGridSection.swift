import SwiftUI

struct PhotoGridSection: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var selectedPhoto: AppViewModel.PhotoEntry? = nil

    // 日付ごとにグループ化
    private var grouped: [(String, [AppViewModel.PhotoEntry])] {
        let cal = Calendar.current
        var dict: [String: [AppViewModel.PhotoEntry]] = [:]
        var order: [String] = []

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"

        for photo in vm.allPhotos {
            let key = formatter.string(from: photo.date)
            if dict[key] == nil { order.append(key) }
            dict[key, default: []].append(photo)
        }
        return order.map { ($0, dict[$0]!) }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        if vm.allPhotos.isEmpty {
            Text("写真がありません")
                .font(.gridBody)
                .foregroundColor(.gridTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(vm.allPhotos) { photo in
                        Button {
                            selectedPhoto = photo
                        } label: {
                            GeometryReader { geo in
                                if let img = UIImage(data: photo.imageData) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geo.size.width, height: geo.size.width)
                                        .clipped()
                                } else {
                                    Color.gridCard
                                }
                            }
                            .aspectRatio(1, contentMode: .fit)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer().frame(height: 100)
            }
        }
    }
}

// MARK: - 全画面写真ビュー

struct FullScreenPhotoView: View {
    let photos: [AppViewModel.PhotoEntry]
    @Binding var selectedPhoto: AppViewModel.PhotoEntry?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: Binding(
                get: { selectedPhoto?.id },
                set: { id in selectedPhoto = photos.first { $0.id == id } }
            )) {
                ForEach(photos) { photo in
                    if let img = UIImage(data: photo.imageData) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .tag(photo.id as UUID?)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            // 閉じるボタン
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 60)
                }
                Spacer()
            }
        }
    }
}
