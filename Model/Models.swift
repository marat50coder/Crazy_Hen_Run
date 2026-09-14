import Foundation
import SwiftUI

enum DayKey {
    static func make(_ date: Date = .now) -> String {
        let c = Calendar.current
        let p = c.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", p.year ?? 0, p.month ?? 0, p.day ?? 0)
    }

    static func date(_ key: String) -> Date {
        let bits = key.split(separator: "-").compactMap { Int($0) }
        guard bits.count == 3 else { return Calendar.current.startOfDay(for: .now) }
        return Calendar.current.date(from: DateComponents(year: bits[0], month: bits[1], day: bits[2]))
            ?? Calendar.current.startOfDay(for: .now)
    }

    static func start(_ date: Date = .now) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    static func week(of date: Date, mondayFirst: Bool) -> [Date] {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: date)
        let first = mondayFirst ? 2 : 1
        var delta = weekday - first
        if delta < 0 { delta += 7 }
        let origin = cal.date(byAdding: .day, value: -delta, to: start(date)) ?? start(date)
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: origin) }
    }
}

enum HabitCategory: String, CaseIterable, Codable {
    case movement, mind, health, nutrition, focus, rest, social, money

    var label: String {
        switch self {
        case .movement: "Movement"
        case .mind: "Mind"
        case .health: "Health"
        case .nutrition: "Nutrition"
        case .focus: "Focus"
        case .rest: "Rest"
        case .social: "Social"
        case .money: "Money"
        }
    }

    var symbol: String {
        switch self {
        case .movement: "figure.run"
        case .mind: "brain.head.profile"
        case .health: "heart.fill"
        case .nutrition: "fork.knife"
        case .focus: "bolt.fill"
        case .rest: "moon.fill"
        case .social: "person.2.fill"
        case .money: "banknote"
        }
    }
}

enum HabitGoal: String, CaseIterable, Codable {
    case check, quantity, duration

    var label: String {
        switch self {
        case .check: "Simple check"
        case .quantity: "Counter"
        case .duration: "Timer"
        }
    }
}

enum HabitDifficulty: String, CaseIterable, Codable {
    case easy, normal, hard

    var label: String {
        switch self {
        case .easy: "Jog"
        case .normal: "Run"
        case .hard: "Sprint"
        }
    }

    var multiplier: Int {
        switch self {
        case .easy: 1
        case .normal: 2
        case .hard: 3
        }
    }
}

struct Habit: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var category: HabitCategory
    var goalType: HabitGoal
    var difficulty: HabitDifficulty
    var colorIndex: Int
    var targetValue: Int
    var unit: String
    var weekdays: Set<Int>
    var createdAt: Date
    var note: String
    var archived: Bool

    var effectiveTarget: Int { goalType == .check ? 1 : max(targetValue, 1) }

    var targetLabel: String {
        switch goalType {
        case .check: "Once a day"
        case .quantity: "\(targetValue) \(unit)"
        case .duration: "\(targetValue) min"
        }
    }

    /// ISO weekday: 1 Monday … 7 Sunday, matching the Flutter store.
    func scheduled(on day: Date) -> Bool {
        let iso = isoWeekday(day)
        return weekdays.contains(iso)
    }
}

func isoWeekday(_ date: Date) -> Int {
    let wd = Calendar.current.component(.weekday, from: date)
    return wd == 1 ? 7 : wd - 1
}

struct HabitLog: Codable, Hashable {
    var habitId: String
    var dayKey: String
    var value: Int
    var target: Int
    var note: String

    var key: String { "\(habitId)@\(dayKey)" }
    var isComplete: Bool { target > 0 && value >= target }
    var progress: Double { target <= 0 ? 0 : min(1, Double(value) / Double(target)) }
}

enum Mood: String, CaseIterable, Codable {
    case rough, low, okay, good, flying

    var label: String {
        switch self {
        case .rough: "Rough"
        case .low: "Low"
        case .okay: "Okay"
        case .good: "Good"
        case .flying: "Flying"
        }
    }

    var emoji: String {
        switch self {
        case .rough: "😵"
        case .low: "😕"
        case .okay: "🙂"
        case .good: "😄"
        case .flying: "🚀"
        }
    }

    var paint: Color {
        switch self {
        case .rough: Meadow.comb
        case .low: Meadow.yolk
        case .okay: Meadow.corn
        case .good: Meadow.lime
        case .flying: Meadow.moss
        }
    }
}

struct JournalEntry: Codable, Hashable {
    var dayKey: String
    var mood: Mood
    var note: String
    var energy: Int
}

struct Profile: Codable, Hashable {
    var name: String
    var avatarPath: String
    var tagline: String
    var joinedAt: Date
    var dailyGoal: Int

    static func blank() -> Profile {
        Profile(name: "Runner", avatarPath: "", tagline: "Habits that turn into miles", joinedAt: .now, dailyGoal: 3)
    }

    var initials: String {
        let parts = name.split(separator: " ").map(String.init)
        if parts.isEmpty { return "CH" }
        if parts.count == 1 { return String(parts[0].prefix(2)).uppercased() }
        return String(parts[0].prefix(1) + parts.last!.prefix(1)).uppercased()
    }
}

enum RunKind: String, CaseIterable, Codable {
    case free, interval, tempo, long, recovery, sprint

    var label: String {
        switch self {
        case .free: "Free Run"
        case .interval: "Intervals"
        case .tempo: "Tempo"
        case .long: "Long Run"
        case .recovery: "Recovery"
        case .sprint: "Sprint"
        }
    }

    var blurb: String {
        switch self {
        case .free: "Just you and the road. No rules — let the hen set the pace."
        case .interval: "Hard efforts with easy jogs. Speed and grit, fast."
        case .tempo: "Comfortably hard, held steady. The engine room."
        case .long: "Slow, patient miles. This is where endurance grows."
        case .recovery: "Feather-light shakeout. Stay consistent."
        case .sprint: "Short bursts. Empty the tank."
        }
    }

    var tag: String {
        switch self {
        case .free: "Open pace"
        case .interval: "Work / rest"
        case .tempo: "Steady hard"
        case .long: "Endurance"
        case .recovery: "Easy day"
        case .sprint: "All out"
        }
    }

    var symbol: String {
        switch self {
        case .free: "figure.run"
        case .interval: "speedometer"
        case .tempo: "flame.fill"
        case .long: "point.bottomleft.forward.to.point.topright.scurveto"
        case .recovery: "leaf.fill"
        case .sprint: "bolt.fill"
        }
    }

    var paint: Color {
        switch self {
        case .free: Meadow.go
        case .interval: Meadow.sunset
        case .tempo: Meadow.comb
        case .long: Color(red: 0.24, green: 0.48, blue: 0.76)
        case .recovery: Meadow.lavender
        case .sprint: Meadow.yolk
        }
    }

    var hen: String {
        switch self {
        case .free: Artwork.runner
        case .interval, .tempo, .sprint: Artwork.sprinter
        case .long: Artwork.standing
        case .recovery: Artwork.happy
        }
    }

    var met: Double {
        switch self {
        case .free: 8.5
        case .interval: 11.5
        case .tempo: 10
        case .long: 9
        case .recovery: 6
        case .sprint: 13
        }
    }
}

struct RunGoal: Hashable {
    enum Kind { case open, distance, duration }
    var kind: Kind
    var value: Int

    static let open = RunGoal(kind: .open, value: 0)
    static let chips: [RunGoal] = [
        .open,
        RunGoal(kind: .distance, value: 1000),
        RunGoal(kind: .distance, value: 3000),
        RunGoal(kind: .distance, value: 5000),
        RunGoal(kind: .duration, value: 15 * 60),
        RunGoal(kind: .duration, value: 30 * 60)
    ]

    var chip: String {
        switch kind {
        case .open: "Just move"
        case .distance: value % 1000 == 0 ? "\(value / 1000) km" : String(format: "%.1f km", Double(value) / 1000)
        case .duration: "\(value / 60) min"
        }
    }

    func progress(metres: Double, seconds: Int) -> Double {
        switch kind {
        case .open: 0
        case .distance: value <= 0 ? 0 : min(1, metres / Double(value))
        case .duration: value <= 0 ? 0 : min(1, Double(seconds) / Double(value))
        }
    }

    func reached(metres: Double, seconds: Int) -> Bool {
        switch kind {
        case .open: false
        case .distance: metres >= Double(value)
        case .duration: seconds >= value
        }
    }
}

struct RunSession: Identifiable, Codable, Hashable {
    var id: String
    var type: RunKind
    var startedAt: Date
    var durationSec: Int
    var steps: Int
    var distanceMeters: Double
    var calories: Int
    var cadence: [Double]
    var feeling: Int
    var note: String

    var paceSecPerKm: Int {
        guard distanceMeters >= 20, durationSec > 0 else { return 0 }
        return Int((Double(durationSec) / (distanceMeters / 1000)).rounded())
    }

    var distanceLabel: String {
        distanceMeters < 1000
            ? "\(Int(distanceMeters.rounded())) m"
            : String(format: "%.2f km", distanceMeters / 1000)
    }

    var durationLabel: String { durationSec.asClock }
}

struct IntervalSegment: Codable, Hashable, Identifiable {
    var id = UUID()
    var label: String
    var seconds: Int
    var intensity: Double

    var isEffort: Bool { intensity >= 0.5 }

    enum CodingKeys: String, CodingKey { case label, seconds, intensity }
}

struct IntervalPlan: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var segments: [IntervalSegment]
    var repeats: Int

    var timeline: [IntervalSegment] {
        (0..<max(repeats, 1)).flatMap { _ in segments }
    }

    var totalSeconds: Int {
        segments.reduce(0) { $0 + $1.seconds } * max(repeats, 1)
    }
}

enum HenRank: Int, CaseIterable {
    case chick, hen, runner, sprinter, legend

    var title: String {
        switch self {
        case .chick: "Chick"
        case .hen: "Hen"
        case .runner: "Runner"
        case .sprinter: "Sprinter"
        case .legend: "Legend"
        }
    }

    var blurb: String {
        switch self {
        case .chick: "Fresh out of the shell. Every long run starts with one tiny step."
        case .hen: "Standing tall. The routine is starting to stick."
        case .runner: "Headband on, pace found. Habits are no longer a fight."
        case .sprinter: "Full tracksuit. You are outrunning your excuses."
        case .legend: "Cape, medal, glory. The yard tells stories about you."
        }
    }

    var needed: Int {
        switch self {
        case .chick: 0
        case .hen: 5_000
        case .runner: 25_000
        case .sprinter: 75_000
        case .legend: 200_000
        }
    }

    var art: String {
        switch self {
        case .chick: Artwork.chick
        case .hen: Artwork.standing
        case .runner: Artwork.runner
        case .sprinter: Artwork.sprinter
        case .legend: Artwork.legend
        }
    }

    var next: HenRank? {
        HenRank(rawValue: rawValue + 1)
    }

    static func forDistance(_ metres: Int) -> HenRank {
        var current = HenRank.chick
        for rank in HenRank.allCases where metres >= rank.needed {
            current = rank
        }
        return current
    }

    func progress(from metres: Int) -> Double {
        guard let upcoming = next else { return 1 }
        let span = upcoming.needed - needed
        guard span > 0 else { return 1 }
        return min(1, max(0, Double(metres - needed) / Double(span)))
    }
}

enum ChallengeMetric: String, Codable {
    case weeklyDistance, weeklyRuns, totalDistance, longestRun, dayStreak, dailySteps
}

struct RunningChallenge: Identifiable {
    var id: String
    var title: String
    var blurb: String
    var metric: ChallengeMetric
    var target: Double
    var symbol: String
    var paint: Color
    var unit: String

    func progress(_ current: Double) -> Double {
        target <= 0 ? 0 : min(1, current / target)
    }
}

struct Achievement: Identifiable {
    enum Group: String, CaseIterable {
        case distance, streak, consistency, variety, care
        var label: String {
            switch self {
            case .distance: "Distance"
            case .streak: "Streaks"
            case .consistency: "Consistency"
            case .variety: "Variety"
            case .care: "Self care"
            }
        }
    }

    var id: String
    var title: String
    var description: String
    var group: Group
    var symbol: String
    var threshold: Int
    var paint: Color
}

struct DaySummary: Hashable {
    var day: Date
    var scheduled: Int
    var completed: Int

    var ratio: Double { scheduled <= 0 ? 0 : min(1, Double(completed) / Double(scheduled)) }
    var perfect: Bool { scheduled > 0 && completed >= scheduled }
}

extension Int {
    var asClock: String {
        let h = self / 3600
        let m = (self % 3600) / 60
        let s = self % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }

    var asPace: String {
        guard self > 0 else { return "—" }
        return String(format: "%d:%02d /km", self / 60, self % 60)
    }
}

extension Double {
    var asDistance: String {
        if self < 1000 { return "\(Int(self.rounded())) m" }
        let km = self / 1000
        return String(format: km < 10 ? "%.2f km" : "%.1f km", km)
    }
}

func newId(_ prefix: String = "h") -> String {
    "\(prefix)-\(UUID().uuidString.prefix(8).lowercased())"
}
