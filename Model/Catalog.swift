import SwiftUI

enum Catalog {
    static let achievements: [Achievement] = [
        .init(id: "first_step", title: "First Step", description: "Complete your very first habit.", group: .consistency, symbol: "flag.fill", threshold: 1, paint: Meadow.lime),
        .init(id: "ten_checks", title: "Warm Up", description: "Complete 10 habits in total.", group: .consistency, symbol: "flame.fill", threshold: 10, paint: Meadow.corn),
        .init(id: "fifty_checks", title: "Cruise Control", description: "Complete 50 habits in total.", group: .consistency, symbol: "gauge.with.dots.needle.67percent", threshold: 50, paint: Meadow.yolk),
        .init(id: "two_hundred_checks", title: "Unstoppable", description: "Complete 200 habits in total.", group: .consistency, symbol: "rocket.fill", threshold: 200, paint: Meadow.comb),
        .init(id: "streak_3", title: "Three in a Row", description: "Hold a 3 day streak on any habit.", group: .streak, symbol: "3.circle.fill", threshold: 3, paint: Meadow.sky),
        .init(id: "streak_7", title: "Full Lap", description: "Hold a 7 day streak on any habit.", group: .streak, symbol: "calendar", threshold: 7, paint: Meadow.moss),
        .init(id: "streak_30", title: "Marathon Mind", description: "Hold a 30 day streak on any habit.", group: .streak, symbol: "trophy.fill", threshold: 30, paint: Meadow.lavender),
        .init(id: "streak_100", title: "Iron Feather", description: "Hold a 100 day streak on any habit.", group: .streak, symbol: "shield.fill", threshold: 100, paint: Color(red: 0.48, green: 0.36, blue: 0.24)),
        .init(id: "distance_5k", title: "5 km Runner", description: "Cover 5 km on the shared track.", group: .distance, symbol: "figure.walk", threshold: 5_000, paint: Meadow.lime),
        .init(id: "distance_25k", title: "25 km Runner", description: "Cover 25 km on the shared track.", group: .distance, symbol: "figure.run", threshold: 25_000, paint: Meadow.moss),
        .init(id: "distance_100k", title: "100 km Legend", description: "Cover 100 km on the shared track.", group: .distance, symbol: "mountain.2.fill", threshold: 100_000, paint: Meadow.sunset),
        .init(id: "perfect_day", title: "Perfect Day", description: "Close every scheduled habit in a single day.", group: .consistency, symbol: "checkmark.circle.fill", threshold: 1, paint: Meadow.go),
        .init(id: "perfect_week", title: "Perfect Week", description: "Reach 7 perfect days.", group: .consistency, symbol: "star.circle.fill", threshold: 7, paint: Meadow.corn),
        .init(id: "variety_3", title: "Well Rounded", description: "Track habits from 3 different categories.", group: .variety, symbol: "square.grid.2x2.fill", threshold: 3, paint: Color(red: 0.09, green: 0.75, blue: 0.73)),
        .init(id: "variety_6", title: "Full Yard", description: "Track habits from 6 different categories.", group: .variety, symbol: "square.grid.3x3.fill", threshold: 6, paint: Meadow.lavender),
        .init(id: "journal_7", title: "Inner Voice", description: "Write 7 journal entries.", group: .care, symbol: "pencil.line", threshold: 7, paint: Meadow.blush),
        .init(id: "journal_30", title: "Open Book", description: "Write 30 journal entries.", group: .care, symbol: "book.fill", threshold: 30, paint: Meadow.comb),
        .init(id: "habits_5", title: "Flock Builder", description: "Keep 5 active habits at once.", group: .variety, symbol: "rectangle.3.group.fill", threshold: 5, paint: Meadow.sky)
    ]

    static let challenges: [RunningChallenge] = [
        .init(id: "c_week_5k", title: "Weekly 5K", blurb: "Cover 5 kilometres before the week resets.", metric: .weeklyDistance, target: 5_000, symbol: "flag.fill", paint: Meadow.go, unit: "m"),
        .init(id: "c_week_15k", title: "Weekly 15K", blurb: "A serious week — 15 km total.", metric: .weeklyDistance, target: 15_000, symbol: "trophy.fill", paint: Meadow.yolk, unit: "m"),
        .init(id: "c_week_3runs", title: "Three a week", blurb: "Lace up three separate times this week.", metric: .weeklyRuns, target: 3, symbol: "repeat", paint: Color(red: 0.24, green: 0.48, blue: 0.76), unit: "runs"),
        .init(id: "c_long_3k", title: "Go the distance", blurb: "Finish a single run of 3 km or more.", metric: .longestRun, target: 3_000, symbol: "point.topleft.down.to.point.bottomright.curvepath", paint: Meadow.lavender, unit: "m"),
        .init(id: "c_steps_10k", title: "10k steps", blurb: "Hit ten thousand steps in one day.", metric: .dailySteps, target: 10_000, symbol: "figure.walk", paint: Meadow.comb, unit: "steps"),
        .init(id: "c_streak_5", title: "Five day fire", blurb: "Move every day for five days straight.", metric: .dayStreak, target: 5, symbol: "flame.fill", paint: Meadow.sunset, unit: "days"),
        .init(id: "c_total_42k", title: "Marathon miles", blurb: "A full marathon across all your runs.", metric: .totalDistance, target: 42_195, symbol: "medal.fill", paint: Meadow.go, unit: "m")
    ]

    static let intervalPresets: [IntervalPlan] = [
        IntervalPlan(id: "preset-beginner", name: "Run / Walk starter", segments: [
            .init(label: "Run", seconds: 60, intensity: 0.8),
            .init(label: "Walk", seconds: 90, intensity: 0.2)
        ], repeats: 6),
        IntervalPlan(id: "preset-classic", name: "Classic 4×4", segments: [
            .init(label: "Hard", seconds: 240, intensity: 0.95),
            .init(label: "Easy", seconds: 180, intensity: 0.35)
        ], repeats: 4),
        IntervalPlan(id: "preset-speed", name: "Speed pyramid", segments: [
            .init(label: "Surge", seconds: 30, intensity: 1),
            .init(label: "Jog", seconds: 60, intensity: 0.3),
            .init(label: "Surge", seconds: 45, intensity: 1),
            .init(label: "Jog", seconds: 60, intensity: 0.3),
            .init(label: "Surge", seconds: 60, intensity: 1),
            .init(label: "Jog", seconds: 90, intensity: 0.3)
        ], repeats: 1)
    ]

    static let templates: [HabitDraft] = {
        let daily: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
        let weekdays: Set<Int> = [1, 2, 3, 4, 5]
        return [
            .init("Morning run", .movement, .duration, .hard, 20, "min", 1, [1, 3, 5], "Out the door before the excuses wake up."),
            .init("10 000 steps", .movement, .check, .normal, 1, "times", 0, daily, "Walk the long way on purpose."),
            .init("Stretch", .movement, .duration, .easy, 10, "min", 8, daily, "Ten minutes so your back forgives you."),
            .init("Drink water", .health, .quantity, .easy, 8, "glasses", 7, daily, "Eight glasses, no negotiation."),
            .init("Sleep before midnight", .rest, .check, .normal, 1, "times", 6, daily, "Tomorrow starts the night before."),
            .init("Read 10 pages", .mind, .quantity, .normal, 10, "pages", 6, daily, "Small pages, big library."),
            .init("Meditate", .mind, .duration, .normal, 10, "min", 9, daily, "Sit still long enough to hear yourself."),
            .init("No screens after 22:00", .rest, .check, .hard, 1, "times", 4, daily, "The feed will survive without you."),
            .init("Cook at home", .nutrition, .check, .normal, 1, "times", 3, weekdays, "Cheaper, better, and you know what is in it."),
            .init("Eat vegetables", .nutrition, .quantity, .easy, 3, "portions", 1, daily, "Green things, three times."),
            .init("Deep work block", .focus, .duration, .hard, 60, "min", 2, weekdays, "One hour, no pings, no excuses."),
            .init("Inbox to zero", .focus, .check, .easy, 1, "times", 7, weekdays, "Close the loops before they close you."),
            .init("Call someone you love", .social, .check, .easy, 1, "times", 5, [7], "Five minutes that make somebody's week."),
            .init("No impulse buys", .money, .check, .normal, 1, "times", 9, daily, "Sleep on it. Usually you stop wanting it."),
            .init("Track spending", .money, .check, .easy, 1, "times", 2, daily, "Two minutes now beats a nasty surprise later."),
            .init("Journal", .mind, .check, .easy, 1, "times", 5, daily, "Three lines is still journalling.")
        ]
    }()
}

struct HabitDraft {
    var title: String
    var category: HabitCategory
    var goalType: HabitGoal
    var difficulty: HabitDifficulty
    var target: Int
    var unit: String
    var colorIndex: Int
    var weekdays: Set<Int>
    var blurb: String

    init(_ title: String, _ category: HabitCategory, _ goalType: HabitGoal, _ difficulty: HabitDifficulty, _ target: Int, _ unit: String, _ colorIndex: Int, _ weekdays: Set<Int>, _ blurb: String) {
        self.title = title
        self.category = category
        self.goalType = goalType
        self.difficulty = difficulty
        self.target = target
        self.unit = unit
        self.colorIndex = colorIndex
        self.weekdays = weekdays
        self.blurb = blurb
    }

    func materialize() -> Habit {
        Habit(
            id: newId("t"),
            title: title,
            category: category,
            goalType: goalType,
            difficulty: difficulty,
            colorIndex: colorIndex,
            targetValue: target,
            unit: unit,
            weekdays: weekdays,
            createdAt: .now,
            note: blurb,
            archived: false
        )
    }
}

enum Coach {
    static func line(closed: Int, scheduled: Int, streak: Int) -> String {
        if scheduled == 0 { return "Rest day. The track will be here tomorrow." }
        if closed == 0 { return "First lap of the day. Pick one and go." }
        if closed >= scheduled { return "Every habit closed. Your hen is doing a victory lap." }
        if streak >= 7 { return "A week of showing up. Keep the line unbroken." }
        if closed >= scheduled / 2 { return "Halfway. The hard part is already behind you." }
        return "Close one more. Distance only grows when you move."
    }
}
