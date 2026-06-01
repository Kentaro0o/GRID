import Foundation
import SwiftUI

class AppViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var sessions: [Session] = []

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

    // MARK: - Weight chart data

    var weightChartData: [(Date, Double)] {
        sessions.compactMap { s in
            guard let w = s.bodyWeight else { return nil }
            return (s.date, w)
        }.sorted { $0.0 < $1.0 }
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
                bodyWeight: baseWeight + Double.random(in: -1.5...1.5)
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
