import SwiftUI

struct WeightLineChart: View {
    let data: [(Date, Double)]
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

            // 線
            var linePath = Path()
            for (i, pos) in positions.enumerated() {
                if i == 0 { linePath.move(to: pos) }
                else       { linePath.addLine(to: pos) }
            }
            ctx.stroke(linePath,
                       with: .color(accentColor.opacity(0.55)),
                       lineWidth: 2)

            // ドット（背景色で線をマスクしてから塗る）
            for (i, pos) in positions.enumerated() {
                let isCurrent = i == centerIndex
                let r: CGFloat = isCurrent ? 8 : 3.5

                // 背景色の円で線を隠す
                let maskRect = CGRect(x: pos.x - r, y: pos.y - r, width: r * 2, height: r * 2)
                ctx.fill(Path(ellipseIn: maskRect), with: .color(backgroundColor))

                // アクセントカラーで塗る（透明度なし＝完全な塗り）
                let opacity: Double = isCurrent ? 1.0 : 0.55
                ctx.fill(Path(ellipseIn: maskRect), with: .color(accentColor.opacity(opacity)))
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

    private func points(size: CGSize, center: Double) -> [CGPoint] {
        let cx = size.width / 2
        let h  = size.height
        let range = maxVal - minVal
        return data.enumerated().map { i, pt in
            let x = cx + CGFloat(Double(i) - center) * spacing
            let y = h - h * CGFloat((pt.1 - minVal) / range) * 0.8 - h * 0.1
            return CGPoint(x: x, y: y)
        }
    }
}
