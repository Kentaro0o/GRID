import Foundation
import UIKit

struct CSVExporter {

    static func export(sessions: [Session], items: [Item]) -> URL? {
        var csv = "セッション番号,日付,体重(kg),種目,タイプ,筋肉グループ,セット,重量(kg),回数,メモ\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"

        for session in sessions.sorted(by: { $0.date < $1.date }) {
            let dateStr  = dateFormatter.string(from: session.date)
            let weightStr = session.bodyWeight.map { String($0) } ?? ""

            if session.entries.isEmpty {
                csv += "\(session.sessionNumber),\(dateStr),\(weightStr),,,,,,, \"\(session.memo)\"\n"
            } else {
                for entry in session.entries {
                    guard let item = items.first(where: { $0.id == entry.itemId }) else { continue }
                    for (idx, set) in entry.sets.enumerated() {
                        let setMemo = idx == 0 ? "\"\(session.memo)\"" : ""
                        csv += "\(session.sessionNumber),\(dateStr),\(weightStr)"
                        csv += ",\(item.name),\(item.type.rawValue),\(item.muscleGroup.rawValue)"
                        csv += ",\(idx + 1),\(set.weight),\(set.reps),\(setMemo)\n"
                    }
                }
            }
        }

        let fileName = "GRID_export_\(Int(Date().timeIntervalSince1970)).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    static func share(url: URL, from viewController: UIViewController) {
        let ac = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        viewController.present(ac, animated: true)
    }
}
