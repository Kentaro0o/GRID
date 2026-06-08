import SwiftUI

struct LogTabView: View {
    var body: some View {
        LogHomeView()
    }
}

#Preview {
    LogTabView()
        .environmentObject(AppViewModel())
}
