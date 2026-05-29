import SwiftUI

struct FitnessMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let delta: String
    let isPositive: Bool
    let symbol: String
    let tint: Color
}

enum WorkoutCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case strength = "Strength"
    case cardio = "Cardio"
    case mobility = "Mobility"
    case recovery = "Recovery"

    var id: String { rawValue }
}

struct WorkoutSession: Identifiable {
    let id = UUID()
    let title: String
    let category: WorkoutCategory
    let duration: String
    let calories: String
    let difficulty: String
    let note: String
    let icon: String
    let tint: Color
}

struct NutritionMacro: Identifiable {
    let id = UUID()
    let name: String
    let amount: String
    let percentage: Double
    let tint: Color
}

struct WeeklyProgressPoint: Identifiable {
    let id = UUID()
    let day: String
    let value: Double
}

struct ProfileStat: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let tint: Color
}

enum SampleFitnessData {
    static let metrics: [FitnessMetric] = [
        FitnessMetric(title: "Steps", value: "12,480", delta: "+1,240", isPositive: true, symbol: "figure.walk", tint: .fitnessAccent),
        FitnessMetric(title: "Calories", value: "1,820", delta: "-210", isPositive: true, symbol: "flame.fill", tint: .fitnessWarning),
        FitnessMetric(title: "Heart Rate", value: "128 bpm", delta: "+8", isPositive: false, symbol: "heart.fill", tint: .fitnessAccentSoft),
        FitnessMetric(title: "Sleep", value: "7h 42m", delta: "+18m", isPositive: true, symbol: "moon.stars.fill", tint: .fitnessAccent)
    ]

    static let workouts: [WorkoutSession] = [
        WorkoutSession(
            title: "Full Body Strength",
            category: .strength,
            duration: "45 min",
            calories: "620 kcal",
            difficulty: "Intermediate",
            note: "Lower body focus, core finishers, and a short cooldown.",
            icon: "dumbbell.fill",
            tint: .fitnessAccent
        ),
        WorkoutSession(
            title: "Zone 2 Run",
            category: .cardio,
            duration: "30 min",
            calories: "310 kcal",
            difficulty: "Easy",
            note: "Keep the pace conversational and maintain steady breathing.",
            icon: "figure.run",
            tint: .fitnessAccentSoft
        ),
        WorkoutSession(
            title: "Mobility Flow",
            category: .mobility,
            duration: "18 min",
            calories: "90 kcal",
            difficulty: "Recovery",
            note: "Open hips, shoulders, and hamstrings before your next session.",
            icon: "figure.cooldown",
            tint: .fitnessWarning
        ),
        WorkoutSession(
            title: "Breath + Stretch",
            category: .recovery,
            duration: "12 min",
            calories: "45 kcal",
            difficulty: "Recovery",
            note: "A calm session designed to reset your nervous system.",
            icon: "lungs.fill",
            tint: .fitnessAccent
        ),
        WorkoutSession(
            title: "Upper Body Push",
            category: .strength,
            duration: "38 min",
            calories: "520 kcal",
            difficulty: "Intermediate",
            note: "Bench, push-ups, and shoulder work for a powerful finish.",
            icon: "figure.strengthtraining.traditional",
            tint: .fitnessAccentSoft
        ),
        WorkoutSession(
            title: "Hill Intervals",
            category: .cardio,
            duration: "24 min",
            calories: "280 kcal",
            difficulty: "Hard",
            note: "Short sprints uphill with recovery walks between sets.",
            icon: "figure.run.circle",
            tint: .fitnessWarning
        )
    ]

    static let macros: [NutritionMacro] = [
        NutritionMacro(name: "Protein", amount: "92 / 130 g", percentage: 0.71, tint: .fitnessAccent),
        NutritionMacro(name: "Carbs", amount: "186 / 240 g", percentage: 0.78, tint: .fitnessAccentSoft),
        NutritionMacro(name: "Fats", amount: "58 / 70 g", percentage: 0.83, tint: .fitnessWarning)
    ]

    static let weeklyProgress: [WeeklyProgressPoint] = [
        WeeklyProgressPoint(day: "Mon", value: 0.55),
        WeeklyProgressPoint(day: "Tue", value: 0.82),
        WeeklyProgressPoint(day: "Wed", value: 0.68),
        WeeklyProgressPoint(day: "Thu", value: 0.92),
        WeeklyProgressPoint(day: "Fri", value: 0.74),
        WeeklyProgressPoint(day: "Sat", value: 0.88),
        WeeklyProgressPoint(day: "Sun", value: 0.63)
    ]

    static let profileStats: [ProfileStat] = [
        ProfileStat(label: "Workouts", value: "142", tint: .fitnessAccent),
        ProfileStat(label: "Streak", value: "21 days", tint: .fitnessAccentSoft),
        ProfileStat(label: "PRs", value: "16", tint: .fitnessWarning)
    ]
}
