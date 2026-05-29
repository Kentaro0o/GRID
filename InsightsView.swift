import SwiftUI

struct InsightsView: View {
    var body: some View {
        ZStack {
            background

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    header
                    chartCard
                    summaryGrid
                    goalsCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Progress")
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
            Text("Weekly trend")
                .font(.title2.weight(.bold))
                .foregroundStyle(.fitnessTextPrimary)
            Text("A quick snapshot of training consistency and recovery.")
                .font(.subheadline)
                .foregroundStyle(.fitnessTextSecondary)
        }
    }

    private var chartCard: some View {
        FitnessCard {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader("Training load", subtitle: "Last 7 days")

                WeeklyBarChart(points: SampleFitnessData.weeklyProgress)
            }
        }
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            StatTile(stat: SampleFitnessData.profileStats[0])
            StatTile(stat: SampleFitnessData.profileStats[1])
        }
    }

    private var goalsCard: some View {
        FitnessCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader("Goals", subtitle: "What you are chasing next")

                AchievementRow(
                    title: "Finish 5 sessions this week",
                    subtitle: "You are 4 sessions in and on pace.",
                    tint: .fitnessAccent,
                    icon: "target"
                )

                AchievementRow(
                    title: "Beat your run time",
                    subtitle: "Zone 2 pace is improving steadily.",
                    tint: .fitnessAccentSoft,
                    icon: "figure.run"
                )
            }
        }
    }
}

#if DEBUG
struct InsightsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            InsightsView()
        }
    }
}
#endif
