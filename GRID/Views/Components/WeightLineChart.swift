import SwiftUI

struct WeightLineChart: View {
    let data: [(Date, Double)]
    /// bodyWeightが実際に記録されているセッションの日付セット
    var knownWeightDates: Set<Date> = []
    var centerIndex: Int = 0
    var accentColor: Color = .gridAccent
    var backgroundColor: Color = .gridBg

    private let spacing: CGFloat = 64

    @State private var animatedCenter: Double = 0

    private var minVal: Double { (data.map { $0.1 }.min() ?? 70) - 3 }
    private var maxVal: Double { (data.map { $0.1 }.max() ?? 90) + 3 }

    var body: some View {
        Canvas { ctx, size in
            let positions = points(size: size, center: animatedCenter)
            guard positions.count >= 1 else { return }

            // 線（bodyWeightが実際にある点同士だけ繋ぐ）
            var linePath = Path()
            var inLine = false
            for (i, pos) in positions.enumerated() {
                if hasKnownWeight(index: i) {
                    if !inLine {
                        linePath.move(to: pos)
                        inLine = true
                    } else {
                        linePath.addLine(to: pos)
                    }
                } else {
                    inLine = false
                }
            }
            ctx.stroke(linePath, with: .color(accentColor.opacity(0.55)), lineWidth: 2)

            // ドット
            for (i, pos) in positions.enumerated() {
                let isCurrent  = i == centerIndex
                let hasWeight  = hasKnownWeight(index: i)
                let r: CGFloat = isCurrent ? 8 : 3.5

                let maskRect = CGRect(x: pos.x - r, y: pos.y - r, width: r * 2, height: r * 2)
                ctx.fill(Path(ellipseIn: maskRect), with: .color(backgroundColor))

                if hasWeight {
                    // 実データあり → 塗りつぶし
                    let opacity: Double = isCurrent ? 1.0 : 0.55
                    ctx.fill(Path(ellipseIn: maskRect), with: .color(accentColor.opacity(opacity)))
                } else {
                    // 補間値（bodyWeightなし）→ 枠のみの小さいドット
                    let smallR = r * 0.7
                    let smallRect = CGRect(x: pos.x - smallR, y: pos.y - smallR,
                                          width: smallR * 2, height: smallR * 2)
                    ctx.stroke(Path(ellipseIn: smallRect),
                               with: .color(accentColor.opacity(0.3)),
                               lineWidth: 1)
                }
            }
        }
        .onAppear {
            animatedCenter = Double(centerIndex)
        }
        .onChange(of: centerIndex) { _, newVal in
            withAnimation(.easeInOut(duration: 0.35)) {
                animatedCenter = Double(newVal)
            }
        }
    }

    private func hasKnownWeight(index: Int) -> Bool {
        guard index < data.count else { return false }
        let cal = Calendar.current
        return knownWeightDates.contains(where: { cal.isDate($0, inSameDayAs: data[index].0) })
    }

    private func points(size: CGSize, center: Double) -> [CGPoint] {
        let cx    = size.width / 2
        let h     = size.height
        let range = maxVal - minVal
        return data.enumerated().map { i, pt in
            let x = cx + CGFloat(Double(i) - center) * spacing
            let y = h - h * CGFloat((pt.1 - minVal) / range) * 0.8 - h * 0.1
            return CGPoint(x: x, y: y)
        }
    }
}
