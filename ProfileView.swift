import SwiftUI

struct ProfileView: View {
    var body: some View {
        ZStack {
            background

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    profileHeader
                    statsGrid
                    achievements
                    settingsCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Profile")
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

    private var profileHeader: some View {
        FitnessCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.fitnessAccent.opacity(0.18))
                        .frame(width: 72, height: 72)
                    Text("KN")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.fitnessAccent)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Kentaro")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.fitnessTextPrimary)
                    Text("Elite member since 2024")
                        .font(.subheadline)
                        .foregroundStyle(.fitnessTextSecondary)
                    HStack(spacing: 8) {
                        InfoPill(text: "Level 18", tint: .fitnessAccent)
                        InfoPill(text: "21 day streak", tint: .fitnessAccentSoft)
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(SampleFitnessData.profileStats) { stat in
                StatTile(stat: stat)
            }
        }
    }

    private var achievements: some View {
        FitnessCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader("Recent achievements", subtitle: "Momentum that you can keep building")

                AchievementRow(
                    title: "Best squat volume",
                    subtitle: "A new personal best from Tuesday's session.",
                    tint: .fitnessAccent,
                    icon: "trophy.fill"
                )

                AchievementRow(
                    title: "Hydration goal hit",
                    subtitle: "You completed the daily water target 6 days in a row.",
                    tint: .fitnessAccentSoft,
                    icon: "drop.fill"
                )
            }
        }
    }

    private var settingsCard: some View {
        FitnessCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader("Settings", subtitle: "Account and app preferences")

                settingRow(title: "Edit profile", icon: "person.crop.circle")
                settingRow(title: "Notifications", icon: "bell.badge")
                settingRow(title: "Connected devices", icon: "applewatch")
                settingRow(title: "Privacy", icon: "lock.fill")
            }
        }
    }

    private func settingRow(title: String, icon: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.fitnessTextSecondary)
            }

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.fitnessTextPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.fitnessTextSecondary)
        }
    }
}

#if DEBUG
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileView()
        }
    }
}
#endif
