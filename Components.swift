import SwiftUI

struct FitnessCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.fitnessTextPrimary)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.fitnessTextSecondary)
                }
            }

            Spacer()
        }
    }
}

struct MetricCard: View {
    let metric: FitnessMetric

    var body: some View {
        FitnessCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(metric.tint.opacity(0.18))
                            .frame(width: 42, height: 42)
                        Image(systemName: metric.symbol)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(metric.tint)
                    }

                    Spacer(minLength: 0)

                    Text(metric.delta)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(metric.isPositive ? .fitnessAccent : .fitnessWarning)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(metric.value)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.fitnessTextPrimary)
                    Text(metric.title.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.fitnessTextSecondary)
                        .tracking(1.1)
                }
            }
        }
    }
}

struct WorkoutCard: View {
    let workout: WorkoutSession

    var body: some View {
        FitnessCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(workout.tint.opacity(0.18))
                            .frame(width: 54, height: 54)
                        Image(systemName: workout.icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(workout.tint)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(workout.title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.fitnessTextPrimary)
                        Text(workout.note)
                            .font(.subheadline)
                            .foregroundStyle(.fitnessTextSecondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)
                }

                HStack(spacing: 8) {
                    InfoPill(text: workout.duration, tint: workout.tint)
                    InfoPill(text: workout.calories, tint: .fitnessAccentSoft)
                    InfoPill(text: workout.difficulty, tint: .fitnessWarning)
                }
            }
        }
    }
}

struct InfoPill: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(tint.opacity(0.12), in: Capsule())
            .overlay(
                Capsule().strokeBorder(tint.opacity(0.25), lineWidth: 1)
            )
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(isSelected ? .fitnessBackground : .fitnessTextSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.fitnessAccent : Color.white.opacity(0.06), in: Capsule())
            .overlay(
                Capsule().strokeBorder(isSelected ? Color.fitnessAccent.opacity(0.6) : Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

struct ProgressRing: View {
    let progress: Double
    let accent: Color
    let title: String
    let subtitle: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: 14)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [accent, Color.fitnessAccentSoft, accent],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 6) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.fitnessTextPrimary)

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.fitnessTextSecondary)

                Text(subtitle)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.fitnessTextSecondary)
            }
        }
        .frame(width: 170, height: 170)
    }
}

struct MacroRow: View {
    let macro: NutritionMacro

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(macro.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.fitnessTextPrimary)

                Spacer()

                Text(macro.amount)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.fitnessTextSecondary)
            }

            ProgressView(value: macro.percentage)
                .tint(macro.tint)
                .scaleEffect(x: 1, y: 1.25, anchor: .center)
        }
    }
}

struct StatTile: View {
    let stat: ProfileStat

    var body: some View {
        FitnessCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(stat.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.fitnessTextSecondary)

                Text(stat.value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(stat.tint)
            }
        }
    }
}

struct WeeklyBarChart: View {
    let points: [WeeklyProgressPoint]

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ForEach(points) { point in
                VStack(spacing: 10) {
                    Spacer(minLength: 0)

                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.fitnessAccent, Color.fitnessAccentSoft],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: max(24, 120 * point.value))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )

                    Text(point.day)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.fitnessTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 170)
            }
        }
    }
}

struct AchievementRow: View {
    let title: String
    let subtitle: String
    let tint: Color
    let icon: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(tint.opacity(0.16))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.fitnessTextPrimary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.fitnessTextSecondary)
            }

            Spacer()
        }
    }
}
