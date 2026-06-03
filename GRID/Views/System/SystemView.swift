import SwiftUI
import UIKit

struct SystemView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var exportURL: URL? = nil
    @State private var showShareSheet = false
    @State private var showClearConfirm = false
    @State private var defaultRestTimer = 120
    @State private var showWeightInput = false
    @State private var weightInput = ""
    @AppStorage("saveCameraPhotoToRoll") private var saveCameraPhotoToRoll = true

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    var body: some View {
        ZStack {
            Color.gridBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("SYSTEM")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.gridTextPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                    .padding(.bottom, 32)

                    // Body weight section
                    sectionCard(title: "今日の体重") {
                        HStack {
                            if let session = vm.todaySession, let w = session.bodyWeight {
                                Text("\(w, specifier: "%.1f") kg")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.gridTextPrimary)
                            } else {
                                Text("未入力")
                                    .font(.gridBody)
                                    .foregroundColor(.gridTextSecondary)
                            }
                            Spacer()
                            Button("入力") {
                                weightInput = vm.todaySession?.bodyWeight.map { String($0) } ?? ""
                                showWeightInput = true
                            }
                            .font(.gridBody)
                            .foregroundColor(.gridAccent)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(Color.gridAccent.opacity(0.15))
                            .clipShape(Capsule())
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                    }

                    // Camera setting
                    sectionCard(title: "カメラ設定") {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("撮影した写真をカメラロールに保存")
                                    .font(.gridBody)
                                    .foregroundColor(.gridTextPrimary)
                                Text("オフにするとアプリ内にのみ保存されます")
                                    .font(.gridCaption)
                                    .foregroundColor(.gridTextSecondary)
                            }
                            Spacer()
                            Toggle("", isOn: $saveCameraPhotoToRoll)
                                .tint(.gridAccent)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }

                    // Default rest timer
                    sectionCard(title: "デフォルト レストタイマー") {
                        HStack(spacing: 24) {
                            Button {
                                if defaultRestTimer > 30 { defaultRestTimer -= 30 }
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
                                defaultRestTimer += 30
                            } label: {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 28))
                                    .foregroundColor(.gridAccent)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    }

                    // Data section
                    sectionCard(title: "データ管理") {
                        VStack(spacing: 0) {
                            menuRow(
                                icon: "square.and.arrow.up",
                                label: "CSVエクスポート",
                                sublabel: "トレーニングログをCSVで書き出す"
                            ) {
                                exportCSV()
                            }
                            Divider().background(Color.gridCardInner).padding(.horizontal, 20)
                            menuRow(
                                icon: "tablecells",
                                label: "Excelエクスポート",
                                sublabel: "CSVはExcelで開くことができます"
                            ) {
                                exportCSV()
                            }
                            Divider().background(Color.gridCardInner).padding(.horizontal, 20)
                            menuRow(
                                icon: "trash",
                                label: "全データを削除",
                                sublabel: "すべてのセッションデータを削除します",
                                isDestructive: true
                            ) {
                                showClearConfirm = true
                            }
                        }
                    }

                    // About section
                    sectionCard(title: "このアプリについて") {
                        VStack(spacing: 0) {
                            infoRow(label: "バージョン", value: appVersion)
                            Divider().background(Color.gridCardInner).padding(.horizontal, 20)
                            infoRow(label: "データ保存先", value: "デバイス本体")
                            Divider().background(Color.gridCardInner).padding(.horizontal, 20)
                            infoRow(label: "アカウント", value: "不要")
                        }
                    }

                    // Privacy note
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
        .alert("体重を入力", isPresented: $showWeightInput) {
            TextField("82.5", text: $weightInput)
                .keyboardType(.decimalPad)
            Button("保存") {
                if let w = Double(weightInput) {
                    var session = vm.ensureTodaySession()
                    session.bodyWeight = w
                    vm.updateSession(session)
                }
            }
            Button("キャンセル", role: .cancel) {}
        }
        .alert("全データを削除しますか？", isPresented: $showClearConfirm) {
            Button("削除", role: .destructive) {
                UserDefaults.standard.removeObject(forKey: "grid_sessions")
                vm.sessions = []
                _ = vm.ensureTodaySession()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("すべてのセッションデータが削除されます。この操作は取り消せません。")
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(url: url)
            }
        }
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

    private func exportCSV() {
        if let url = CSVExporter.export(sessions: vm.sessions, items: vm.items) {
            exportURL = url
            showShareSheet = true
        }
    }

    private func timerString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SystemView()
        .environmentObject(AppViewModel())
}
