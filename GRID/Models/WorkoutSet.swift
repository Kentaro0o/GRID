import Foundation

struct WorkoutSet: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var weight: Double = 0
    var reps: Int = 0
}
