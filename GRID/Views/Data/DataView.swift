import SwiftUI

struct DataView: View {
    var body: some View {
        ZStack {
            Color.gridBg.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("DATA")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.gridTextPrimary)
                Text("Coming soon")
                    .font(.gridBody)
                    .foregroundColor(.gridTextSecondary)
            }
        }
    }
}

#Preview {
    DataView()
}
