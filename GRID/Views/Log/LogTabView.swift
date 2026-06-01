import SwiftUI

struct LogTabView: View {
    var body: some View {
        SessionTimelineView()
    }
}

#Preview {
    LogTabView()
        .environmentObject(AppViewModel())
}
