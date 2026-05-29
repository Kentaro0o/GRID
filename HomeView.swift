import SwiftUI

struct HomeView: View {
    private let ringProgress = 0.78

    var body: some View {
        ZStack {
            background

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    header
                    heroCard
                    metricsGrid
                    workoutsSection
                    nutritionSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Today")
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
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color.fitnessAccent.opacity(0.16))
                .frame(width: 240, height: 240)
                .blur(radius: 24)
                .offset(x: 120, y: -120)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(Color.fitnessAccentSoft.opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 32)
                .offset(x: -140, y: 160)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Good morning, Ken")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.fitnessTextPrimary)
                Text("Your body is ready. Let’s make today count.")
                    .font(.subheadline)
                    .foregroundStyle(.fitnessTextSecondary)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 48, height: 48)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.fitnessAccent)
            }
        }
    }

    private var heroCard: some View {
        FitnessCard {
            HStack(spacing: 18) {
                ProgressRing(
                    progress: ringProgress,
                    accent: .fitnessAccent,
                    title: "Training",
                    subtitle: "of daily goal"
                )

                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Today's focus")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.fitnessTextSecondary)
                            .tracking(1.1)
                        Text("Full Body Strength")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.fitnessTextPrimary)
                        Text("45 min, 620 kcal, intermediate pace")
                            .font(.subheadline)
                            .foregroundStyle(.fitnessTextSecondary)
                    }

                    HStack(spacing: 10) {
                        InfoPill(text: "45 min", tint: .fitnessAccent)
                        InfoPill(text: "620 kcal", tint: .fitnessAccentSoft)
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(SampleFitnessData.metrics) { metric in
                MetricCard(metric: metric)
            }
        }
    }

    private var workoutsSection: some View {
        VStack(spacing: 12) {
            SectionHeader("Upcoming workouts", subtitle: "Personalized for your current plan")

            ForEach(Array(SampleFitnessData.workouts.prefix(2))) { workout in
                WorkoutCard(workout: workout)
            }
        }
    }

    private var nutritionSection: some View {
        FitnessCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader("Nutrition", subtitle: "Macronutrient balance for today")

                VStack(spacing: 14) {
                    ForEach(SampleFitnessData.macros) { macro in
                        MacroRow(macro: macro)
                    }
                }
            }
        }
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView()
        }
    }
}
#endif
