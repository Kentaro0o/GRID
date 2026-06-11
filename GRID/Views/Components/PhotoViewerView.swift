import SwiftUI
import PhotosUI
import Photos

struct PhotoViewerView: View {
    @Environment(\.dismiss) var dismiss

    @Binding var photosData: [Data]
    @State private var currentPage: Int
    @State private var showDeleteConfirm = false
    @State private var showReplaceDialog = false
    @State private var showAddDialog = false
    @State private var showLibraryPickerReplace = false
    @State private var showLibraryPickerAdd = false
    @State private var showCameraReplace = false
    @State private var showCameraAdd = false
    @State private var photoPickerReplace: PhotosPickerItem? = nil
    @State private var photoPickerAdd: [PhotosPickerItem] = []
    @State private var cameraReplaceData: Data? = nil
    @State private var cameraAddData: Data? = nil
    @AppStorage("saveCameraPhotoToRoll") private var saveCameraPhotoToRoll = true
    @State private var showShareSheet = false

    init(photosData: Binding<[Data]>, initialIndex: Int = 0) {
        _photosData = photosData
        _currentPage = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 写真スワイプ
            TabView(selection: $currentPage) {
                ForEach(Array(photosData.enumerated()), id: \.offset) { i, data in
                    if let ui = UIImage(data: data) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .tag(i)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: photosData.count > 1 ? .always : .never))
            .ignoresSafeArea()

            VStack {
                // 上部バー
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

                    Spacer()

                    if photosData.count > 1 {
                        Text("\(currentPage + 1) / \(photosData.count)")
                            .font(.gridCaption)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Capsule())
                    }

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
                }
                .padding(.horizontal, 24)
                .padding(.top, GRIDLayout.headerTopPadding)

                Spacer()

                // 下部ボタン
                HStack(spacing: 12) {
                    // 取り直し
                    Button {
                        showReplaceDialog = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 14))
                            Text("取り直す")
                                .font(.gridBody)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // 削除
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                            .frame(width: 50, height: 50)
                            .background(Color.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // 追加
                    Button {
                        showAddDialog = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 14))
                            Text("写真を追加")
                                .font(.gridBody)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.gridAccent.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        // 取り直しダイアログ
        .confirmationDialog("写真を取り直す", isPresented: $showReplaceDialog, titleVisibility: .visible) {
            Button("カメラで撮影") { showCameraReplace = true }
            Button("カメラロールから選択") { showLibraryPickerReplace = true }
            Button("キャンセル", role: .cancel) {}
        }
        // 追加ダイアログ
        .confirmationDialog("写真を追加", isPresented: $showAddDialog, titleVisibility: .visible) {
            Button("カメラで撮影") { showCameraAdd = true }
            Button("カメラロールから選択") { showLibraryPickerAdd = true }
            Button("キャンセル", role: .cancel) {}
        }
        .photosPicker(isPresented: $showLibraryPickerReplace, selection: $photoPickerReplace, matching: .images)
        .photosPicker(isPresented: $showLibraryPickerAdd, selection: $photoPickerAdd, maxSelectionCount: 10, matching: .images)
        .fullScreenCover(isPresented: $showCameraReplace) {
            CameraView(imageData: $cameraReplaceData, saveToRoll: saveCameraPhotoToRoll).ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showCameraAdd) {
            CameraView(imageData: $cameraAddData, saveToRoll: saveCameraPhotoToRoll).ignoresSafeArea()
        }
        .onChange(of: photoPickerReplace) { _, item in
            Task {
                guard let data = try? await item?.loadTransferable(type: Data.self) else { return }
                replaceCurrentPhoto(data)
                photoPickerReplace = nil
            }
        }
        .onChange(of: photoPickerAdd) { _, items in
            Task {
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        addPhoto(data)
                    }
                }
                photoPickerAdd = []
            }
        }
        .onChange(of: cameraReplaceData) { _, data in
            guard let data else { return }
            replaceCurrentPhoto(data)
            cameraReplaceData = nil
        }
        .onChange(of: cameraAddData) { _, data in
            guard let data else { return }
            addPhoto(data)
            cameraAddData = nil
        }
        .sheet(isPresented: $showShareSheet) {
            if photosData.indices.contains(currentPage),
               let img = UIImage(data: photosData[currentPage]) {
                ShareSheet(items: [img])
            }
        }
        .alert("この写真を削除しますか？", isPresented: $showDeleteConfirm) {
            Button("削除", role: .destructive) {
                guard photosData.indices.contains(currentPage) else { return }
                photosData.remove(at: currentPage)
                if photosData.isEmpty {
                    dismiss()
                } else {
                    currentPage = min(currentPage, photosData.count - 1)
                }
            }
            Button("キャンセル", role: .cancel) {}
        }
    }

    private func replaceCurrentPhoto(_ data: Data) {
        guard photosData.indices.contains(currentPage) else { return }
        photosData[currentPage] = data
    }

    private func addPhoto(_ data: Data) {
        photosData.append(data)
        currentPage = photosData.count - 1
    }
}

#Preview {
    // サンプル用にグラデーション画像をDataに変換
    let renderer = ImageRenderer(content:
        LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
            .frame(width: 400, height: 600)
    )
    let data1 = renderer.uiImage.flatMap { $0.jpegData(compressionQuality: 0.8) } ?? Data()
    let renderer2 = ImageRenderer(content:
        LinearGradient(colors: [.orange, .pink], startPoint: .top, endPoint: .bottom)
            .frame(width: 400, height: 600)
    )
    let data2 = renderer2.uiImage.flatMap { $0.jpegData(compressionQuality: 0.8) } ?? Data()
    return PhotoViewerView(photosData: .constant([data1, data2]))
}
