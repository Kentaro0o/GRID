import Foundation
import SwiftUI

class AppViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var sessions: [Session] = []

    /// DATAタブなどから LOG タブの特定セッションへジャンプするためのリクエスト
    @Published var navigateToSessionId: UUID? = nil
    /// AddItemViewなどサブ画面表示中はタブバーを隠す
    @Published var hideTabBar: Bool = false
    /// LOGタブボタンが押されるたびにインクリメント（同タブ再タップ検知用）
    @Published var logTabTappedCount: Int = 0

    private let itemsKey   = "grid_items"
    private let sessionsKey = "grid_sessions"

    init() {
        load()
        if items.isEmpty { items = Item.defaults }
        if sessions.isEmpty { seedSampleSessions() }
        save()
    }

    // MARK: - Item operations

    func addItem(_ item: Item) {
        items.append(item)
        save()
    }

    func updateItem(_ item: Item) {
        if let i = items.firstIndex(where: { $0.id == item.id }) {
            items[i] = item
            save()
        }
    }

    func deleteItem(_ item: Item) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func item(for id: UUID) -> Item? {
        items.first { $0.id == id }
    }

    func items(for group: MuscleGroup) -> [Item] {
        items.filter { $0.muscleGroup == group }
    }

    /// グループ内でのアイテム順序変更（List の onMove 用）
    func moveItems(in group: MuscleGroup, from source: IndexSet, to destination: Int) {
        // グループ内の items を取得（元のインデックス付き）
        let groupIndices = items.indices.filter { items[$0].muscleGroup == group }
        var groupItems   = groupIndices.map { items[$0] }
        groupItems.move(fromOffsets: source, toOffset: destination)
        // 変更後の順序を items 配列へ反映
        for (offset, globalIdx) in groupIndices.enumerated() {
            items[globalIdx] = groupItems[offset]
        }
        save()
    }

    // MARK: - Session operations

    var todaySession: Session? {
        let cal = Calendar.current
        return sessions.first { cal.isDateInToday($0.date) }
    }

    func ensureTodaySession() -> Session {
        if let s = todaySession { return s }
        let s = Session(sessionNumber: (sessions.map { $0.sessionNumber }.max() ?? 0) + 1,
                        date: Date())
        sessions.insert(s, at: 0)
        save()
        return s
    }

    /// 写真・ログ・体重が全てない空セッションを削除（今日のセッションは残す）
    func removeEmptySessions() {
        let cal = Calendar.current
        sessions.removeAll { s in
            !cal.isDateInToday(s.date)
            && s.entries.isEmpty
            && s.photosData.isEmpty
            && s.bodyWeight == nil
        }
        save()
    }

    func deleteSession(_ session: Session) {
        sessions.removeAll { $0.id == session.id }
        save()
    }

    func updateSession(_ session: Session) {
        if let i = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[i] = session
        } else {
            sessions.insert(session, at: 0)
        }
        sessions.sort { $0.date > $1.date }
        save()
    }

    func muscleGroups(for session: Session) -> [MuscleGroup] {
        var groups: [MuscleGroup] = []
        for entry in session.entries {
            if let item = item(for: entry.itemId), !groups.contains(item.muscleGroup) {
                groups.append(item.muscleGroup)
            }
        }
        return groups
    }

    func entriesByMuscle(for session: Session) -> [(MuscleGroup, [WorkoutEntry])] {
        var dict: [MuscleGroup: [WorkoutEntry]] = [:]
        for entry in session.entries {
            if let item = item(for: entry.itemId) {
                dict[item.muscleGroup, default: []].append(entry)
            }
        }
        return MuscleGroup.allCases.compactMap { group in
            guard let entries = dict[group], !entries.isEmpty else { return nil }
            return (group, entries)
        }
    }

    // MARK: - Exercise stats

    struct ExerciseStat {
        let item: Item
        let allTimeMax: Double
        let recentMonthMax: Double?   // nil = 直近1ヶ月にデータなし
    }

    /// 種目ごとの MAX 重量（全期間 & 直近1ヶ月）※reps=0 は除外
    func exerciseStats(for group: MuscleGroup) -> [ExerciseStat] {
        let targetItems = items.filter { $0.muscleGroup == group }
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()

        return targetItems.compactMap { item in
            let allSets = sessions.flatMap { session -> [(Date, Double)] in
                session.entries
                    .filter { $0.itemId == item.id }
                    .flatMap { entry in
                        entry.sets
                            .filter { $0.reps > 0 }   // 0回は除外
                            .map { (session.date, $0.weight) }
                    }
            }
            guard !allSets.isEmpty else { return nil }

            let allTimeMax = allSets.map(\.1).max() ?? 0
            let recentSets = allSets.filter { $0.0 >= oneMonthAgo }
            let recentMax  = recentSets.isEmpty ? nil : recentSets.map(\.1).max()

            return ExerciseStat(item: item, allTimeMax: allTimeMax, recentMonthMax: recentMax)
        }
    }

    /// 種目ごとの日付別セッションログ
    struct ExerciseSessionLog: Identifiable {
        let id: UUID        // session.id
        let date: Date
        let dateString: String
        let maxWeight: Double   // そのセッション内のこの種目の最大重量
        let sets: [WorkoutSet]  // reps>0 のセットのみ
        let memo: String        // WorkoutEntry の memo
    }

    /// ある種目の日付別ログ一覧（古い順）※reps=0 は除外
    func sessionLogs(for item: Item) -> [ExerciseSessionLog] {
        sessions
            .sorted { $0.date < $1.date }
            .compactMap { session in
                guard let entry = session.entries.first(where: { $0.itemId == item.id }) else { return nil }
                let validSets = entry.sets.filter { $0.reps > 0 }
                guard let max = validSets.map({ $0.weight }).max() else { return nil }
                return ExerciseSessionLog(
                    id: session.id,
                    date: session.date,
                    dateString: session.dateString,
                    maxWeight: max,
                    sets: validSets,
                    memo: entry.memo
                )
            }
    }

    // MARK: - Photo data

    struct PhotoEntry: Identifiable {
        let id = UUID()
        let date: Date
        let imageData: Data
        let sessionId: UUID
    }

    /// 全セッションの写真を日付降順で返す
    var allPhotos: [PhotoEntry] {
        sessions
            .sorted { $0.date > $1.date }
            .flatMap { session in
                session.photosData.map { data in
                    PhotoEntry(date: session.date, imageData: data, sessionId: session.id)
                }
            }
    }

    // MARK: - Weight chart data

    /// 全セッションを対象。bodyWeightがない場合は前後の値から線形補間
    var weightChartData: [(Date, Double)] {
        let sorted = sessions.sorted { $0.date < $1.date }
        guard !sorted.isEmpty else { return [] }

        // まずbodyWeightがあるものだけ取り出す
        let knownWeights: [(Int, Double)] = sorted.enumerated().compactMap { i, s in
            s.bodyWeight.map { (i, $0) }
        }
        guard !knownWeights.isEmpty else {
            // 体重データが一切ない場合は全セッションをデフォルト値で返す
            return sorted.map { ($0.date, 70.0) }
        }

        // 各セッションに補間した体重を割り当て
        var result: [(Date, Double)] = []
        for (i, session) in sorted.enumerated() {
            if let w = session.bodyWeight {
                result.append((session.date, w))
            } else {
                // 前後のknownWeightsから線形補間
                let prev = knownWeights.last(where: { $0.0 < i })
                let next = knownWeights.first(where: { $0.0 > i })
                let interpolated: Double
                if let p = prev, let n = next {
                    let ratio = Double(i - p.0) / Double(n.0 - p.0)
                    interpolated = p.1 + ratio * (n.1 - p.1)
                } else if let p = prev {
                    interpolated = p.1
                } else if let n = next {
                    interpolated = n.1
                } else {
                    interpolated = 70.0
                }
                result.append((session.date, interpolated))
            }
        }
        return result
    }

    // MARK: - Persistence

    func save() {
        if let d = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(d, forKey: itemsKey)
        }
        if let d = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(d, forKey: sessionsKey)
        }
    }

    private func load() {
        if let d = UserDefaults.standard.data(forKey: itemsKey),
           let decoded = try? JSONDecoder().decode([Item].self, from: d) {
            items = decoded
        }
        if let d = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([Session].self, from: d) {
            sessions = decoded
        }
    }

    private func seedSampleSessions() {
        let cal = Calendar.current
        let baseWeight = 82.7
        let today = Date()
        for i in stride(from: 6, through: 0, by: -1) {
            guard let date = cal.date(byAdding: .day, value: -i, to: today) else { continue }
            var s = Session(
                sessionNumber: 41 + (6 - i),
                date: date,
                bodyWeight: ((baseWeight + Double.random(in: -1.5...1.5)) * 10).rounded() / 10
            )
            // Add sample entries for the first few sessions
            if i > 0, let benchId = items.first(where: { $0.name == "ベンチプレス" })?.id {
                let entry = WorkoutEntry(itemId: benchId, sets: [
                    WorkoutSet(weight: 90, reps: 8),
                    WorkoutSet(weight: 90, reps: 8),
                    WorkoutSet(weight: 80, reps: 7),
                ])
                s.entries = [entry]
            }
            sessions.append(s)
        }
        sessions.sort { $0.date > $1.date }
    }
}
