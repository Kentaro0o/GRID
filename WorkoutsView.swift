import SwiftUI

struct WorkoutsView: View {
    @State private var selectedCategory: WorkoutCategory = .all

    private var filteredWorkouts: [WorkoutSession] {
        guard selectedCategory != .all else { return SampleFitnessData.workouts }
        return SampleFitnessData.workouts.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ZStack {
            background

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    categoryChips
                    ForEach(filteredWorkouts) { workout in
                        WorkoutCard(workout: workout)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Workouts")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var background: some View {
        LinearGradient(
            colors: [Color.fitnessBackground, Color.fitnessBackgroundAlt],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Build your session")
                .font(.title2.weight(.bold))
                .foregroundStyle(.fitnessTextPrimary)
            Text("Pick a training style and jump into a focused plan.")
                .font(.subheadline)
                .foregroundStyle(.fitnessTextSecondary)
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(WorkoutCategory.allCases) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        FilterChip(title: category.rawValue, isSelected: selectedCategory == category)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#if DEBUG
struct WorkoutsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WorkoutsView()
        }
    }
}
#endif
