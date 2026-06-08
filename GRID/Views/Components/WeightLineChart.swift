import SwiftUI

struct WeightLineChart: View {
    let data: [(Date, Double)]
    /// bodyWeightが実際に記録されているセッションの日付セット
    var knownWeightDates: Set<Date> = []
    var centerIndex: Int = 0
    var accentColor: Color = .gridAccent
    var backgroundColor: Color = .gridBg
    /// Canvas 上部の余白（上方向にはみ出す量）
    var overflowTop: CGFloat = 0
    /// Canvas 下部の余白（下方向にはみ出す量）
    var overflowBottom: CGFloat = 0

    private let spacing: CGFloat = 64

    @State private var animatedCenter: Double

    init(data: [(Date, Double)],
         knownWeightDates: Set<Date> = [],
         centerIndex: Int = 0,
         accentColor: Color = .gridAccent,
         backgroundColor: Color = .gridBg,
         overflowTop: CGFloat = 0,
         overflowBottom: CGFloat = 0) {
        self.data = data
        self.knownWeightDates = knownWeightDates
        self.centerIndex = centerIndex
        self.accentColor = accentColor
        self.backgroundColor = backgroundColor
        self.overflowTop = overflowTop
        self.overflowBottom = overflowBottom
        // centerIndex を初期値に使うことで初回描画から正しい位置を表示
        _animatedCenter = State(initialValue: Double(centerIndex))
    }

    // 現在地点の体重を中心に ±0.5kg の固定レンジ
    private var centerWeight: Double {
        guard data.indices.contains(centerIndex) else { return 70 }
        return data[centerIndex].1
    }
    private var minVal: Double { centerWeight - 1.5 }
    private var maxVal: Double { centerWeight + 1.5 }

    var body: some View {
        Canvas { ctx, size in
            let positions = points(size: size, center: animatedCenter)
            guard positions.count >= 1 else { return }

            // 実データのインデックス一覧
            let knownIndices = positions.indices.filter { hasKnownWeight(index: $0) }

            // 実線：隣接する実データ同士を繋ぐ
            var solidPath = Path()
            for k in 0..<knownIndices.count {
                let i = knownIndices[k]
                if k == 0 {
                    solidPath.move(to: positions[i])
                } else {
                    let prev = knownIndices[k - 1]
                    // 間に補間値がない（直前の実データ）場合のみ実線
                    if i == prev + 1 {
                        solidPath.addLine(to: positions[i])
                    } else {
                        solidPath.move(to: positions[i])
                    }
                }
            }
            ctx.stroke(solidPath, with: .color(accentColor.opacity(0.55)), lineWidth: 2)

            // 点線：補間値を挟んだ実データ同士を繋ぐ
            var dashedPath = Path()
            for k in 1..<knownIndices.count {
                let i    = knownIndices[k]
                let prev = knownIndices[k - 1]
                if i > prev + 1 {
                    dashedPath.move(to: positions[prev])
                    dashedPath.addLine(to: positions[i])
                }
            }
            ctx.stroke(dashedPath,
                       with: .color(accentColor.opacity(0.35)),
                       style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))

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
        let h     = size.height - overflowTop - overflowBottom  // 可視描画エリアの高さ
        let range = maxVal - minVal
        return data.enumerated().map { i, pt in
            let x = cx + CGFloat(Double(i) - center) * spacing
            let yInVisible = h - h * CGFloat((pt.1 - minVal) / range) * 0.8 - h * 0.1
            let y = overflowTop + yInVisible
            return CGPoint(x: x, y: y)
        }
    }
}

#Preview {
    let cal = Calendar.current
    let today = Date()
    let data: [(Date, Double)] = (0..<10).map { i in
        let date = cal.date(byAdding: .day, value: -9 + i, to: today)!
        return (date, 70.0 + Double(i) * 0.3)
    }
    let knownDates = Set(stride(from: 0, to: 10, by: 2).map {
        cal.date(byAdding: .day, value: -9 + $0, to: today)!
    })
    return ZStack {
        Color.gridBg.ignoresSafeArea()
        WeightLineChart(
            data: data,
            knownWeightDates: knownDates,
            centerIndex: 9,
            accentColor: .gridAccent,
            backgroundColor: .gridBg
        )
        .frame(height: 90)
        .padding(.horizontal, 24)
    }
}
