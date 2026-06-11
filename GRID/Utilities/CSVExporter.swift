import Foundation
import UIKit

struct CSVExporter {

    static func export(sessions: [Session], items: [Item],
                       includeTraining: Bool = true,
                       includeWeight: Bool = true) -> URL? {
        var columns = ["セッション番号", "日付"]
        if includeWeight { columns.append("体重(kg)") }
        if includeTraining { columns += ["種目", "タイプ", "筋肉グループ", "セット", "重量(kg)", "回数"] }
        columns.append("メモ")
        var csv = columns.joined(separator: ",") + "\n"

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy/MM/dd"

        for session in sessions.sorted(by: { $0.date < $1.date }) {
            let dateStr   = fmt.string(from: session.date)
            let weightStr = includeWeight ? (session.bodyWeight.map { String($0) } ?? "") : nil

            if !includeTraining || session.entries.isEmpty {
                var row = "\(session.sessionNumber),\(dateStr)"
                if let w = weightStr { row += ",\(w)" }
                if includeTraining  { row += ",,,,,,," }
                row += ",\"\(session.memo)\"\n"
                csv += row
            } else {
                for entry in session.entries {
                    guard let item = items.first(where: { $0.id == entry.itemId }) else { continue }
                    for (idx, set) in entry.sets.enumerated() {
                        var row = "\(session.sessionNumber),\(dateStr)"
                        if let w = weightStr { row += ",\(w)" }
                        row += ",\(item.name),\(item.type.rawValue),\(item.muscleGroup.rawValue)"
                        row += ",\(idx + 1),\(set.weight),\(set.reps)"
                        row += ",\(idx == 0 ? "\"\(session.memo)\"" : "")\n"
                        csv += row
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
