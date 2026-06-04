import Foundation

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest    = "胸"
    case back     = "背"
    case shoulder = "肩"
    case arm      = "腕"
    case leg      = "脚"
    case abs      = "腹"

    var id: String { rawValue }
}

enum ItemType: String, Codable, CaseIterable {
    case freeWeight = "フリーウェイト"
    case machine    = "マシン"
    case bodyweight = "自重"
}

struct Item: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var type: ItemType = .freeWeight
    var restTimerSeconds: Int = 120  // 0 = disabled
    var muscleGroup: MuscleGroup = .chest

    static let defaults: [Item] = [
        Item(name: "ベンチプレス",   type: .freeWeight, restTimerSeconds: 120, muscleGroup: .chest),
        Item(name: "チェストプレス", type: .machine,    restTimerSeconds: 90,  muscleGroup: .chest),
        Item(name: "ディップス",     type: .bodyweight, restTimerSeconds: 90,  muscleGroup: .chest),
        Item(name: "ダンベルフライ", type: .freeWeight, restTimerSeconds: 90,  muscleGroup: .chest),
        Item(name: "デッドリフト",   type: .freeWeight, restTimerSeconds: 180, muscleGroup: .back),
        Item(name: "ラットプルダウン", type: .machine,  restTimerSeconds: 90,  muscleGroup: .back),
        Item(name: "サイドレイズ",   type: .freeWeight, restTimerSeconds: 90,  muscleGroup: .shoulder),
        Item(name: "ショルダープレス", type: .freeWeight, restTimerSeconds: 120, muscleGroup: .shoulder),
        Item(name: "バーベルカール", type: .freeWeight, restTimerSeconds: 90,  muscleGroup: .arm),
        Item(name: "スクワット",     type: .freeWeight, restTimerSeconds: 180, muscleGroup: .leg),
        Item(name: "レッグプレス",   type: .machine,    restTimerSeconds: 120, muscleGroup: .leg),
        Item(name: "クランチ",       type: .bodyweight, restTimerSeconds: 60,  muscleGroup: .abs),
    ]
}
