import Foundation

struct Session: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var sessionNumber: Int
    var date: Date
    var photosData: [Data] = []
    var bodyWeight: Double?
    var entries: [WorkoutEntry] = []
    var memo: String = ""

    // 旧データ（photoData: Data?）からの移行対応
    enum CodingKeys: String, CodingKey {
        case id, sessionNumber, date, photosData, bodyWeight, entries, memo
        case legacyPhotoData = "photoData"
    }

    init(id: UUID = UUID(), sessionNumber: Int, date: Date,
         photosData: [Data] = [], bodyWeight: Double? = nil,
         entries: [WorkoutEntry] = [], memo: String = "") {
        self.id = id
        self.sessionNumber = sessionNumber
        self.date = date
        self.photosData = photosData
        self.bodyWeight = bodyWeight
        self.entries = entries
        self.memo = memo
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,            forKey: .id)
        try c.encode(sessionNumber, forKey: .sessionNumber)
        try c.encode(date,          forKey: .date)
        try c.encode(photosData,    forKey: .photosData)
        try c.encodeIfPresent(bodyWeight, forKey: .bodyWeight)
        try c.encode(entries,       forKey: .entries)
        try c.encode(memo,          forKey: .memo)
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(UUID.self,          forKey: .id)
        sessionNumber = try c.decode(Int.self,           forKey: .sessionNumber)
        date         = try c.decode(Date.self,           forKey: .date)
        bodyWeight   = try c.decodeIfPresent(Double.self, forKey: .bodyWeight)
        entries      = try c.decodeIfPresent([WorkoutEntry].self, forKey: .entries) ?? []
        memo         = try c.decodeIfPresent(String.self, forKey: .memo) ?? ""

        if let photos = try c.decodeIfPresent([Data].self, forKey: .photosData) {
            photosData = photos
        } else if let legacy = try c.decodeIfPresent(Data.self, forKey: .legacyPhotoData) {
            photosData = [legacy]
        } else {
            photosData = []
        }
    }

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
        []
    }
}
