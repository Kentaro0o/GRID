import Foundation

struct WorkoutEntry: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var itemId: UUID
    var sets: [WorkoutSet] = [WorkoutSet()]
    var memo: String = ""
}
