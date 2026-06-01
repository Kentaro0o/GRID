import Foundation

struct Session: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var sessionNumber: Int
    var date: Date
    var photoData: Data?
    var bodyWeight: Double?
    var entries: [WorkoutEntry] = []
    var memo: String = ""

    var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "MM.dd"
        return f.string(from: date)
    }

    var fullDateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd"
        return f.string(from: date)
    }

    var muscleGroups: [MuscleGroup] {
        []  // computed by AppViewModel after joining with Items
    }
}
