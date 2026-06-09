import SwiftUI

/// 体重の横スクロールチャート
/// タップでポイントを選択 → selectedId が更新される（= 基準セット）
struct WeightScrollChart: View {
    let sessions: [Session]          // 古い順でソート済み
    @Binding var selectedId: UUID?

    private let itemWidth: CGFloat = 56
    private let hPad: CGFloat      = 24
    private let chartH: CGFloat    = 110
    private let labelH: CGFloat    = 18

    @State private var centerIndex: Int = 0

    private var plotH: CGFloat { chartH - labelH }

    private var values: [Double] { sessions.compactMap { $0.bodyWeight } }
    private var maxVal: Double { (values.max() ?? 70) + 0.5 }
    private var minVal: Double { (values.min() ?? 60) - 0.5 }
    private var range:  Double { max(maxVal - minVal, 1) }

    private func xPos(_ i: Int) -> CGFloat {
        hPad + itemWidth * CGFloat(i) + itemWidth / 2
    }
    private func yPos(_ v: Double) -> CGFloat {
        plotH * (1 - CGFloat((v - minVal) / range) * 0.8 - 0.1)
    }

    var body: some View {
        let totalW = itemWidth * CGFloat(sessions.count) + hPad * 2

        ScrollViewReader { chartProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    // ─── Canvas: 線＋ドット ───
                    Canvas { ctx, _ in
                        guard values.count >= 2 else { return }

                        var path = Path()
                        path.move(to: CGPoint(x: xPos(0), y: yPos(values[0])))
                        for i in 1..<values.count {
                            path.addLine(to: CGPoint(x: xPos(i), y: yPos(values[i])))
                        }
                        ctx.stroke(path, with: .color(Color.gridAccent.opacity(0.55)), lineWidth: 1.5)

                        for (i, v) in values.enumerated() {
                            let isCenter = i == centerIndex
                            let cx = xPos(i), cy = yPos(v)
                            let r: CGFloat = isCenter ? 5 : 3.5
                            let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
                            ctx.fill(Path(ellipseIn: rect), with: .color(Color.gridBg))
                            ctx.fill(Path(ellipseIn: rect),
                                     with: .color(isCenter ? Color.gridAccent : Color.gridAccent.opacity(0.55)))
                        }
                    }
                    .frame(width: totalW, height: plotH)

                    // ─── タップ領域＋日付ラベル ───
                    HStack(spacing: 0) {
                        ForEach(Array(sessions.enumerated()), id: \.element.id) { i, session in
                            VStack(spacing: 0) {
                                Color.clear
                                    .frame(width: itemWidth, height: plotH)
                                Text(session.date.formatted(.dateTime.month().day()))
                                    .font(.system(size: 10))
                                    .foregroundColor(i == centerIndex ? .gridAccent : .gridTextTertiary)
                                    .frame(width: itemWidth, height: labelH)
                            }
                            .id(i)  // ScrollViewReader用
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    centerIndex = i
                                    let id = session.id
                                    selectedId = (selectedId == id) ? nil : id
                                }
                            }
                        }
                    }
                    .padding(.horizontal, hPad)
                }
                .frame(width: totalW, height: chartH)
            }
            .frame(height: chartH)
            .onAppear {
                syncCenter()
                // 初期表示は最新位置へ
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation { chartProxy.scrollTo(centerIndex, anchor: .center) }
                }
            }
            .onChange(of: selectedId) { _, _ in
                syncCenter()
                withAnimation { chartProxy.scrollTo(centerIndex, anchor: .center) }
            }
            .onChange(of: sessions.count) { _, _ in
                if centerIndex >= sessions.count {
                    centerIndex = max(0, sessions.count - 1)
                }
            }
        }
    }

    private func syncCenter() {
        if let id = selectedId,
           let idx = sessions.firstIndex(where: { $0.id == id }) {
            centerIndex = idx
        } else {
            centerIndex = max(0, sessions.count - 1)
        }
    }
}
