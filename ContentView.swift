import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NavigationStack {
                WorkoutsView()
            }
            .tabItem {
                Label("Workouts", systemImage: "dumbbell.fill")
            }

            NavigationStack {
                InsightsView()
            }
            .tabItem {
                Label("Progress", systemImage: "chart.bar.fill")
            }

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle.fill")
            }
        }
        .tint(.fitnessAccent)
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
