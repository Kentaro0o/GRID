import SwiftUI
import PhotosUI

struct PastSessionDetailView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss

    let initialSession: Session

    @State private var session: Session
    @State private var photoPicker: [PhotosPickerItem] = []
    @State private var showPhotoSourceDialog = false
    @State private var showCamera = false
    @State private var showLibraryPicker = false
    @State private var cameraImageData: Data? = nil
    @State private var showPhotoViewer = false
    @State private var showAddMenu = false
    @State private var showWeightInput = false
    @State private var weightInputText = ""
    @AppStorage("saveCameraPhotoToRoll") private var saveCameraPhotoToRoll = true

    init(session: Session) {
        self.initialSession = session
        _session = State(initialValue: session)
    }

    var body: some View {
        ZStack {
            Color.gridBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // ヘッダー
                HStack {
                    Button {
                        vm.updateSession(session)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gridTextSecondary)
                            .frame(width: 32, height: 32)
                            .background(Color.gridCard)
                            .clipShape(Circle())
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text("SESSION #\(session.sessionNumber)")
                            .font(.gridSmall)
                            .foregroundColor(.gridTextSecondary)
                            .kerning(1.5)
                        Text(session.fullDateString)
                            .font(.gridHeadline)
                            .foregroundColor(.gridTextPrimary)
                    }
                    Spacer()
                    Color.clear.frame(width: 32, height: 32)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, GRIDLayout.headerBottomPadding)

                // セッションカード
                VStack(spacing: 16) {
                    // 写真エリア
                    Button {
                        if session.photosData.isEmpty {
                            showPhotoSourceDialog = true
                        } else {
                            showPhotoViewer = true
                        }
                    } label: {
                        Group {
                            if let data = session.photosData.first, let ui = UIImage(data: data) {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: ui)
                                        .resizable()
                                        .scaledToFill()
                                    if session.photosData.count > 1 {
                                        Text("\(session.photosData.count)")
                                            .font(.gridCaption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.black.opacity(0.5))
                                            .clipShape(Capsule())
                                            .padding(8)
                                    }
                                }
                            } else {
                                Image(systemName: "photo")
                                    .font(.system(size: 32))
                                    .foregroundColor(.gridTextSecondary)
                            }
                        }
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .background(Color.gridCardInner)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)

                    // ログを追加ボタン
                    let hasLog = !session.entries.isEmpty
                    Button {
                        showAddMenu = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: hasLog ? "doc.text" : "plus.circle")
                            Text(hasLog ? "ログを見る" : "ログを追加")
                                .font(.gridBody)
                        }
                        .foregroundColor(hasLog ? .gridTextSecondary : .gridAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(hasLog ? Color.gridCardInner : Color.gridAccent.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(20)
                .background(Color.gridCard)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .padding(.horizontal, 24)

                Spacer()

                // 体重ピル
                HStack {
                    Spacer()
                    Button {
                        weightInputText = session.bodyWeight.map { String($0) } ?? ""
                        showWeightInput = true
                    } label: {
                        VStack(spacing: 2) {
                            Text("Weight")
                                .font(.gridSmall)
                                .foregroundColor(.gridTextSecondary)
                                .kerning(1)
                            if let w = session.bodyWeight {
                                Text("\(w, specifier: "%.1f") kg")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.gridTextPrimary)
                            } else {
                                Text("+ KG")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.gridAccent)
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(Color.gridCard)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
            }
        }
        .confirmationDialog("写真を追加", isPresented: $showPhotoSourceDialog, titleVisibility: .visible) {
            Button("カメラで撮影") { showCamera = true }
            Button("カメラロールから選択") { showLibraryPicker = true }
            Button("キャンセル", role: .cancel) {}
        }
        .photosPicker(isPresented: $showLibraryPicker, selection: $photoPicker, maxSelectionCount: 10, matching: .images)
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(imageData: $cameraImageData, saveToRoll: saveCameraPhotoToRoll)
                .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showPhotoViewer) {
            PhotoViewerView(
                photosData: Binding(
                    get: { session.photosData },
                    set: { session.photosData = $0; vm.updateSession(session) }
                )
            )
        }
        .fullScreenCover(isPresented: $showAddMenu) {
            AddMenuView(session: session)
                .environmentObject(vm)
        }
        .alert("体重を入力", isPresented: $showWeightInput) {
            TextField("例: 72.5", text: $weightInputText)
                .keyboardType(.decimalPad)
            Button("保存") {
                if let w = Double(weightInputText) {
                    session.bodyWeight = (w * 10).rounded() / 10
                    vm.updateSession(session)
                }
            }
            Button("キャンセル", role: .cancel) {}
        }
        .onChange(of: photoPicker) { _, items in
            Task {
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        session.photosData.append(data)
                    }
                }
                vm.updateSession(session)
                photoPicker = []
            }
        }
        .onChange(of: cameraImageData) { _, data in
            guard let data else { return }
            session.photosData.append(data)
            vm.updateSession(session)
            cameraImageData = nil
        }
        // AddMenuViewが閉じたらsessionを最新に更新
        .onChange(of: showAddMenu) { _, isShowing in
            if !isShowing {
                session = vm.sessions.first { $0.id == session.id } ?? session
            }
        }
    }
}

#Preview {
    let vm = AppViewModel()
    let session = vm.sessions.first ?? vm.ensureTodaySession()
    return PastSessionDetailView(session: session)
        .environmentObject(vm)
}
