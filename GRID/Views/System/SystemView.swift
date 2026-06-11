import SwiftUI
import UIKit
import LocalAuthentication

struct SystemView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var sharePayload: SharePayload? = nil
    @State private var showExportOptions = false
    @State private var pendingExportAfterDismiss = false
    @State private var exportIncludeTraining = true
    @State private var exportIncludeWeight = true
    @State private var showDeleteMenu = false
    @State private var deleteTarget: DeleteTarget? = nil
    @State private var showDeleteConfirm = false
    @State private var showDeleteInput = false
    @State private var deleteInputText = ""
    @State private var deleteConfirmWord = ""
    @State private var defaultRestTimer = 120
    @AppStorage("saveCameraPhotoToRoll") private var saveCameraPhotoToRoll = true
    @AppStorage("timerSoundEnabled") private var timerSoundEnabled = true

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    enum DeleteTarget {
        case training, weight, photos, all
        var label: String {
            switch self {
            case .training: return "トレーニング記録"
            case .weight:   return "体重記録"
            case .photos:   return "写真"
            case .all:      return "全データ"
            }
        }
        var confirmWord: String { "DELETE" }
    }

    var body: some View {
        ZStack {
            Color.gridBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        Text("SYSTEM")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.gridTextPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, GRIDLayout.headerTopPadding)
                    .padding(.bottom, 32)

                    // デフォルト レストタイマー
                    sectionCard(title: "デフォルト レストタイマー") {
                        HStack(spacing: 24) {
                            Button {
                                if defaultRestTimer > 10 { defaultRestTimer -= 10 }
                            } label: {
                                Image(systemName: "minus.circle")
                                    .font(.system(size: 28))
                                    .foregroundColor(.gridAccent)
                            }
                            Text(timerString(defaultRestTimer))
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .foregroundColor(.gridTextPrimary)
                                .frame(maxWidth: .infinity)
                            Button {
                                defaultRestTimer += 10
                            } label: {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 28))
                                    .foregroundColor(.gridAccent)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    }

                    // タイマー音
                    sectionCard(title: "タイマー音") {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("タイマー終了時に音を鳴らす")
                                    .font(.gridBody)
                                    .foregroundColor(.gridTextPrimary)
                                Text("オフにすると無音で終了します")
                                    .font(.gridCaption)
                                    .foregroundColor(.gridTextSecondary)
                                    .padding(.top, 1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Toggle("", isOn: $timerSoundEnabled)
                                .tint(.gridAccent)
                                .fixedSize()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }

                    // カメラ設定
                    sectionCard(title: "カメラ設定") {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("撮影した写真をカメラロールに保存")
                                    .font(.gridBody)
                                    .foregroundColor(.gridTextPrimary)
                                Text("オフにするとアプリ内にのみ保存されます")
                                    .font(.gridCaption)
                                    .foregroundColor(.gridTextSecondary)
                                    .padding(.top, 1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Toggle("", isOn: $saveCameraPhotoToRoll)
                                .tint(.gridAccent)
                                .fixedSize()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }

                    // データ管理
                    sectionCard(title: "データ管理") {
                        VStack(spacing: 0) {
                            let totalPhotos = vm.sessions.reduce(0) { $0 + $1.photosData.count }

                            menuRow(
                                icon: "square.and.arrow.up",
                                label: "ログを書き出す",
                                sublabel: "含める情報を選んでCSVで書き出す"
                            ) {
                                showExportOptions = true
                            }

                            Divider().background(Color.gridCardInner).padding(.horizontal, 20)

                            menuRow(
                                icon: "photo.on.rectangle.angled",
                                label: "すべての写真を書き出す",
                                sublabel: "アプリ内の写真 \(totalPhotos)枚を書き出す"
                            ) {
                                exportPhotos()
                            }

                            Divider().background(Color.gridCardInner).padding(.horizontal, 20)

                            menuRow(
                                icon: "trash",
                                label: "データを削除",
                                sublabel: "削除する対象を選ぶ",
                                isDestructive: true
                            ) {
                                showDeleteMenu = true
                            }
                        }
                    }

                    // このアプリについて
                    sectionCard(title: "このアプリについて") {
                        infoRow(label: "バージョン", value: appVersion)
                    }

                    // プライバシー
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield")
                                .foregroundColor(.gridAccent)
                            Text("プライバシーについて")
                                .font(.gridBody)
                                .foregroundColor(.gridTextPrimary)
                        }
                        Text("GRIDはすべてのデータをあなたのデバイスにのみ保存します。ログインや会員登録は不要で、個人情報は一切収集しません。")
                            .font(.gridCaption)
                            .foregroundColor(.gridTextSecondary)
                            .lineSpacing(4)
                    }
                    .padding(20)
                    .background(Color.gridCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    Spacer().frame(height: 120)
                }
            }
        }
        // ログを書き出す — 選択シート（dismiss後にCSVエクスポート実行）
        .sheet(isPresented: $showExportOptions, onDismiss: {
            if pendingExportAfterDismiss {
                pendingExportAfterDismiss = false
                exportCSV(training: exportIncludeTraining, weight: exportIncludeWeight)
            }
        }) {
            exportOptionsSheet
        }
        // 共有シート（CSV・写真共通）
        .sheet(item: $sharePayload) { payload in
            ShareSheet(items: payload.items)
        }
        // データを削除 — 対象選択
        .confirmationDialog("削除する対象を選んでください", isPresented: $showDeleteMenu, titleVisibility: .visible) {
            Button("トレーニング記録を削除", role: .destructive) {
                deleteTarget = .training; deleteConfirmWord = DeleteTarget.training.confirmWord; deleteInputText = ""; showDeleteInput = true
            }
            Button("体重記録を削除", role: .destructive) {
                deleteTarget = .weight; deleteConfirmWord = DeleteTarget.weight.confirmWord; deleteInputText = ""; showDeleteInput = true
            }
            Button("写真を削除", role: .destructive) {
                deleteTarget = .photos; deleteConfirmWord = DeleteTarget.photos.confirmWord; deleteInputText = ""; showDeleteInput = true
            }
            Button("全データを削除", role: .destructive) {
                deleteTarget = .all; deleteConfirmWord = DeleteTarget.all.confirmWord; deleteInputText = ""; showDeleteInput = true
            }
            Button("キャンセル", role: .cancel) {}
        }
        // 削除確認入力
        .alert("「\(deleteConfirmWord)」と入力してください", isPresented: $showDeleteInput) {
            TextField(deleteConfirmWord, text: $deleteInputText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
            Button("削除", role: .destructive) {
                if deleteInputText == deleteConfirmWord { showDeleteConfirm = true }
                deleteInputText = ""
            }
            Button("キャンセル", role: .cancel) { deleteInputText = "" }
        } message: {
            if let target = deleteTarget {
                Text("\(target.label)を削除するには「\(deleteConfirmWord)」と入力してください")
            }
        }
        // 削除確認
        .alert("削除しますか？", isPresented: $showDeleteConfirm) {
            Button("削除", role: .destructive) { performDelete() }
            Button("キャンセル", role: .cancel) {}
        } message: {
            if let target = deleteTarget {
                Text("\(target.label)を削除します。この操作は取り消せません。")
            }
        }
    }

    // MARK: - ログ書き出しシート

    private var exportOptionsSheet: some View {
        NavigationStack {
            ZStack {
                Color.gridBg.ignoresSafeArea()
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Text("含める情報")
                            .font(.gridSmall)
                            .foregroundColor(.gridTextSecondary)
                            .kerning(1.2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .padding(.bottom, 8)

                        toggleRow(label: "トレーニング記録", isOn: $exportIncludeTraining)
                        Divider().background(Color.gridCardInner).padding(.horizontal, 20)
                        toggleRow(label: "体重", isOn: $exportIncludeWeight)
                    }
                    .background(Color.gridCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                    Spacer()

                    Button {
                        pendingExportAfterDismiss = true
                        showExportOptions = false
                    } label: {
                        Text("書き出す")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(exportIncludeTraining || exportIncludeWeight ? .white : .gridTextTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(exportIncludeTraining || exportIncludeWeight ? Color.gridAccent : Color.gridCard)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!exportIncludeTraining && !exportIncludeWeight)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 48)
                }
            }
            .navigationTitle("ログを書き出す")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { showExportOptions = false }
                        .foregroundColor(.gridAccent)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func toggleRow(label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.gridBody)
                .foregroundColor(.gridTextPrimary)
            Spacer()
            Toggle("", isOn: isOn)
                .tint(.gridAccent)
                .fixedSize()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Components

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.gridSmall)
                .foregroundColor(.gridTextSecondary)
                .kerning(1.2)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
            content()
        }
        .background(Color.gridCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private func menuRow(icon: String, label: String, sublabel: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isDestructive ? .gridDanger : .gridAccent)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.gridBody)
                        .foregroundColor(isDestructive ? .gridDanger : .gridTextPrimary)
                    Text(sublabel)
                        .font(.gridCaption)
                        .foregroundColor(.gridTextSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.gridTextTertiary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.gridBody)
                .foregroundColor(.gridTextPrimary)
            Spacer()
            Text(value)
                .font(.gridBody)
                .foregroundColor(.gridTextSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Actions

    private func exportCSV(training: Bool, weight: Bool) {
        guard let url = CSVExporter.export(sessions: vm.sessions, items: vm.items,
                                           includeTraining: training, includeWeight: weight) else { return }
        sharePayload = SharePayload(items: [url])
    }

    private func exportPhotos() {
        let images = vm.sessions
            .sorted { $0.date < $1.date }
            .flatMap { $0.photosData }
            .compactMap { UIImage(data: $0) }
        guard !images.isEmpty else { return }
        sharePayload = SharePayload(items: images)
    }

    private func performDelete() {
        guard let target = deleteTarget else { return }
        switch target {
        case .training:
            vm.sessions = vm.sessions.map { s in
                var s = s; s.entries = []; return s
            }
            vm.sessions.forEach { vm.updateSession($0) }
        case .weight:
            vm.sessions = vm.sessions.map { s in
                var s = s; s.bodyWeight = nil; return s
            }
            vm.sessions.forEach { vm.updateSession($0) }
        case .photos:
            vm.sessions = vm.sessions.map { s in
                var s = s; s.photosData = []; return s
            }
            vm.sessions.forEach { vm.updateSession($0) }
        case .all:
            UserDefaults.standard.removeObject(forKey: "grid_sessions")
            vm.sessions = []
            _ = vm.ensureTodaySession()
        }
        deleteTarget = nil
    }

    private func timerString(_ seconds: Int) -> String {
        let m = seconds / 60; let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - SharePayload

struct SharePayload: Identifiable {
    let id = UUID()
    let items: [Any]
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    init(items: [Any]) { self.items = items }
    init(url: URL) { self.items = [url] }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SystemView()
        .environmentObject(AppViewModel())
}
