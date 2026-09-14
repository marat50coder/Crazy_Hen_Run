import Foundation

struct Snapshot: Codable {
    var habits: [Habit]
    var logs: [String: HabitLog]
    var journal: [String: JournalEntry]
    var profile: Profile
    var unlocked: [String]
    var runs: [RunSession]
    var stepDays: [String: Int]
    var plans: [IntervalPlan]
    var settings: SettingsBlob
    var onboarded: Bool

    static func empty() -> Snapshot {
        Snapshot(
            habits: [],
            logs: [:],
            journal: [:],
            profile: .blank(),
            unlocked: [],
            runs: [],
            stepDays: [:],
            plans: [],
            settings: .defaults,
            onboarded: false
        )
    }
}

struct SettingsBlob: Codable {
    var theme: String
    var accentIndex: Int
    var hideCompleted: Bool
    var mondayFirst: Bool
    var weeklySprint: Int
    var stepGoal: Int
    var strideCm: Int
    var weightKg: Int
    var weeklyRunTarget: Int
    var haptics: Bool

    static let defaults = SettingsBlob(
        theme: "system",
        accentIndex: 1,
        hideCompleted: false,
        mondayFirst: true,
        weeklySprint: 21,
        stepGoal: 8_000,
        strideCm: 72,
        weightKg: 70,
        weeklyRunTarget: 3,
        haptics: true
    )
}

enum SnapshotStore {
    private static let key = "hyard.snapshot.v3"
    private static let flag = "hyard.onboarded.v3"
    private static let defaults = UserDefaults.standard

    static func load() -> Snapshot {
        var snap = Snapshot.empty()
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder.make.decode(Snapshot.self, from: data) {
            snap = decoded
        }
        if defaults.object(forKey: flag) != nil {
            snap.onboarded = defaults.bool(forKey: flag)
        }
        return snap
    }

    static func save(_ snap: Snapshot) {
        if let data = try? JSONEncoder.make.encode(snap) {
            defaults.set(data, forKey: key)
        }
        defaults.set(snap.onboarded, forKey: flag)
    }

    static func wipe() {
        defaults.removeObject(forKey: key)
        defaults.removeObject(forKey: flag)
    }
}

extension JSONDecoder {
    static var make: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}

extension JSONEncoder {
    static var make: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }
}
