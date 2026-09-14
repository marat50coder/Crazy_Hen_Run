import Foundation
import SwiftUI
import UIKit

@Observable
final class Yard {
    var habits: [Habit] = []
    var logs: [String: HabitLog] = [:]
    var journal: [String: JournalEntry] = [:]
    var profile: Profile = .blank()
    var unlocked: Set<String> = []
    var pendingUnlocks: [Achievement] = []
    var runs: [RunSession] = []
    var stepDays: [String: Int] = [:]
    var plans: [IntervalPlan] = []
    var settings: SettingsBlob = .defaults
    var onboarded = false
    var ready = false

    var sensor = StepSensor()
    var health = HealthKitSensor()

    var running = false
    var paused = false
    var liveKind: RunKind = .free
    var liveGoal: RunGoal = .open
    var liveElapsed = 0
    var liveCadence: [Double] = []
    var liveStarted: Date?
    var intervalCursor = 0
    var intervalPlan: IntervalPlan?
    var goalHit = false

    private var ticker: Timer?
    private var persistWork: DispatchWorkItem?

    func boot() {
        let snap = SnapshotStore.load()
        habits = snap.habits
        logs = snap.logs
        journal = snap.journal
        profile = snap.profile
        unlocked = Set(snap.unlocked)
        runs = snap.runs
        stepDays = snap.stepDays
        plans = snap.plans
        settings = snap.settings
        onboarded = snap.onboarded
        if onboarded && habits.isEmpty {
            seedStarters()
        }
        ready = true
        refreshAchievements(announce: false)
    }

    func finishWelcome() {
        if habits.isEmpty { seedStarters() }
        onboarded = true
        persist()
    }

    // MARK: Habits

    var activeHabits: [Habit] { habits.filter { !$0.archived } }
    var archivedHabits: [Habit] { habits.filter(\.archived) }

    func habits(on day: Date) -> [(Habit, HabitLog?)] {
        let start = DayKey.start(day)
        return activeHabits
            .filter { $0.scheduled(on: start) && DayKey.start($0.createdAt) <= start }
            .map { ($0, log(for: $0.id, on: start)) }
    }

    func log(for habitId: String, on day: Date) -> HabitLog? {
        logs["\(habitId)@\(DayKey.make(day))"]
    }

    func summary(on day: Date) -> DaySummary {
        let rows = habits(on: day)
        let done = rows.filter { $0.1?.isComplete == true }.count
        return DaySummary(day: day, scheduled: rows.count, completed: done)
    }

    func bump(_ habit: Habit, on day: Date, delta: Int) {
        let key = "\(habit.id)@\(DayKey.make(day))"
        var row = logs[key] ?? HabitLog(habitId: habit.id, dayKey: DayKey.make(day), value: 0, target: habit.effectiveTarget, note: "")
        row.target = habit.effectiveTarget
        row.value = max(0, row.value + delta)
        logs[key] = row
        tap()
        refreshAchievements(announce: true)
        persistSoon()
    }

    func toggle(_ habit: Habit, on day: Date) {
        let current = log(for: habit.id, on: day)?.value ?? 0
        if current >= habit.effectiveTarget {
            bump(habit, on: day, delta: -habit.effectiveTarget)
        } else {
            bump(habit, on: day, delta: habit.effectiveTarget - current)
        }
    }

    func upsert(_ habit: Habit) {
        if let i = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[i] = habit
        } else {
            habits.append(habit)
        }
        persist()
        refreshAchievements(announce: true)
    }

    func archive(_ habit: Habit, _ yes: Bool) {
        guard let i = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[i].archived = yes
        persist()
    }

    func delete(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        logs = logs.filter { $0.value.habitId != habit.id }
        persist()
    }

    func streak(for habit: Habit, asOf: Date = .now) -> Int {
        let today = DayKey.start(asOf)
        let birth = DayKey.start(habit.createdAt)
        var n = 0
        var i = 0
        while i < 730 {
            guard let day = Calendar.current.date(byAdding: .day, value: -i, to: today) else { break }
            if day < birth { break }
            if habit.scheduled(on: day) {
                if log(for: habit.id, on: day)?.isComplete == true {
                    n += 1
                } else if i != 0 {
                    break
                }
            }
            i += 1
        }
        return n
    }

    var longestStreak: Int {
        activeHabits.map { streak(for: $0) }.max() ?? 0
    }

    var totalCompletions: Int {
        logs.values.filter(\.isComplete).count
    }

    var habitMetres: Int {
        let byId = Dictionary(uniqueKeysWithValues: habits.map { ($0.id, $0) })
        return logs.values.reduce(0) { sum, log in
            guard log.isComplete else { return sum }
            let m = byId[log.habitId]?.difficulty.multiplier ?? 1
            return sum + Tuning.metresPerCheck * m
        }
    }

    var runMetres: Double {
        runs.reduce(0) { $0 + $1.distanceMeters }
    }

    var stepMetres: Double {
        Double(stepDays.values.reduce(0, +)) * (Double(settings.strideCm) / 100)
    }

    /// One track: habits + recorded runs + leftover walking.
    var lifetimeMetres: Int {
        Int((Double(habitMetres) + runMetres + stepMetres).rounded())
    }

    var rank: HenRank { .forDistance(lifetimeMetres) }

    var rankProgress: Double { rank.progress(from: lifetimeMetres) }

    var distanceLabel: String { Double(lifetimeMetres).asDistance }

    var weeklySprintProgress: Double {
        let target = max(1, settings.weeklySprint)
        return min(1, Double(weeklyCompletions) / Double(target))
    }

    var weeklyCompletions: Int {
        let week = DayKey.week(of: .now, mondayFirst: settings.mondayFirst)
        guard let first = week.first, let last = week.last else { return 0 }
        return logs.values.filter { log in
            guard log.isComplete else { return false }
            let d = DayKey.date(log.dayKey)
            return d >= DayKey.start(first) && d <= DayKey.start(last)
        }.count
    }

    func saveJournal(_ entry: JournalEntry) {
        journal[entry.dayKey] = entry
        persist()
        refreshAchievements(announce: true)
    }

    func deleteJournal(_ key: String) {
        journal[key] = nil
        persist()
    }

    func updateProfile(_ next: Profile) {
        profile = next
        persist()
    }

    // MARK: Runs

    var todaySteps: Int {
        let key = DayKey.make()
        return max(stepDays[key] ?? 0, sensor.todaySteps, health.todaySteps)
    }

    func enableSteps() {
        sensor.askAndStart()
    }

    /// Asks for Health read access exactly once, right after the boot
    /// screen is gone. Called from the first onboarding guide for new
    /// users, and right as the tabs appear for people who are already
    /// onboarded — never from the splash screen itself.
    func connectHealth() {
        health.connectOnce()
    }

    /// Re-fires the Health prompt on demand (Settings, Steps board) after
    /// an earlier decline.
    func reconnectHealth(completion: @escaping (Bool) -> Void = { _ in }) {
        health.requestAgain(completion: completion)
    }

    /// Cheap refresh for whatever screen is currently showing today's steps.
    func syncHealthToday() {
        health.refreshToday()
    }

    /// Backfills the local day-by-day chart with real Health totals so the
    /// Steps board lines up with the Health app even on days the pedometer
    /// never ran a live session.
    func backfillHealthHistory(days: Int = 30) {
        guard health.authorized else { return }
        health.fetchDailySteps(days: days) { [weak self] byDay in
            guard let self else { return }
            var changed = false
            for (key, steps) in byDay where steps > (self.stepDays[key] ?? 0) {
                self.stepDays[key] = steps
                changed = true
            }
            if changed { self.persistSoon() }
        }
    }

    func startRun(_ kind: RunKind, goal: RunGoal, plan: IntervalPlan? = nil) {
        guard !running else { return }
        if !sensor.authorized { sensor.askAndStart() }
        liveKind = kind
        liveGoal = goal
        intervalPlan = plan
        intervalCursor = 0
        liveElapsed = 0
        liveCadence = []
        liveStarted = .now
        goalHit = false
        running = true
        paused = false
        sensor.markRunStart()
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        tap()
    }

    func pauseRun() {
        paused.toggle()
        tap()
    }

    func finishRun() -> RunSession? {
        guard running else { return nil }
        ticker?.invalidate()
        ticker = nil
        let steps = max(sensor.liveSteps, Int(Double(liveElapsed) * 1.4))
        let metres = Double(steps) * (Double(settings.strideCm) / 100)
        let kcal = max(1, Int(metres / 1000 * liveKind.met * Double(settings.weightKg) / 15))
        let session = RunSession(
            id: newId("r"),
            type: liveKind,
            startedAt: liveStarted ?? .now,
            durationSec: liveElapsed,
            steps: steps,
            distanceMeters: metres,
            calories: kcal,
            cadence: liveCadence,
            feeling: 3,
            note: ""
        )
        runs.insert(session, at: 0)
        let key = DayKey.make()
        stepDays[key] = todaySteps
        running = false
        paused = false
        sensor.markRunEnd()
        persist()
        tap()
        return session
    }

    func discardRun() {
        ticker?.invalidate()
        ticker = nil
        running = false
        paused = false
        sensor.markRunEnd()
    }

    func updateRun(_ session: RunSession) {
        if let i = runs.firstIndex(where: { $0.id == session.id }) {
            runs[i] = session
            persist()
        }
    }

    func deleteRun(_ session: RunSession) {
        runs.removeAll { $0.id == session.id }
        persist()
    }

    func upsertPlan(_ plan: IntervalPlan) {
        if let i = plans.firstIndex(where: { $0.id == plan.id }) {
            plans[i] = plan
        } else {
            plans.append(plan)
        }
        persist()
    }

    func deletePlan(_ id: String) {
        plans.removeAll { $0.id == id }
        persist()
    }

    var allPlans: [IntervalPlan] { plans + Catalog.intervalPresets }

    func weekRuns(from ref: Date = .now) -> [RunSession] {
        let week = DayKey.week(of: ref, mondayFirst: true)
        guard let start = week.first, let end = week.last else { return [] }
        let until = Calendar.current.date(byAdding: .day, value: 1, to: DayKey.start(end)) ?? end
        return runs.filter { $0.startedAt >= DayKey.start(start) && $0.startedAt < until }
    }

    var weekDistance: Double { weekRuns().reduce(0) { $0 + $1.distanceMeters } }

    var moveStreak: Int {
        var n = 0
        for i in 0..<400 {
            guard let day = Calendar.current.date(byAdding: .day, value: -i, to: DayKey.start()) else { break }
            let key = DayKey.make(day)
            let steps = stepDays[key] ?? 0
            let ran = runs.contains { DayKey.make($0.startedAt) == key }
            if ran || steps >= 1_000 {
                n += 1
            } else if i == 0 {
                continue
            } else {
                break
            }
        }
        return n
    }

    func challengeValue(_ metric: ChallengeMetric) -> Double {
        switch metric {
        case .weeklyDistance: weekDistance
        case .weeklyRuns: Double(weekRuns().count)
        case .totalDistance: runMetres
        case .longestRun: runs.map(\.distanceMeters).max() ?? 0
        case .dayStreak: Double(moveStreak)
        case .dailySteps: Double(todaySteps)
        }
    }

    func consumeUnlocks() -> [Achievement] {
        let batch = pendingUnlocks
        pendingUnlocks = []
        return batch
    }

    // MARK: Settings / data

    var themeMode: ThemeMode {
        get { ThemeMode(rawValue: settings.theme) ?? .system }
        set {
            settings.theme = newValue.rawValue
            persist()
        }
    }

    var accent: Color { Meadow.habit(settings.accentIndex) }

    func applySettings(_ next: SettingsBlob) {
        settings = next
        persist()
    }

    func exportJSON() -> String {
        let snap = currentSnap()
        guard let data = try? JSONEncoder.make.encode(snap),
              let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }

    func resetAll() {
        ticker?.invalidate()
        ticker = nil
        running = false
        SnapshotStore.wipe()
        let fresh = Snapshot.empty()
        habits = fresh.habits
        logs = fresh.logs
        journal = fresh.journal
        profile = fresh.profile
        unlocked = []
        pendingUnlocks = []
        runs = []
        stepDays = [:]
        plans = []
        settings = .defaults
        onboarded = false
        persist()
    }

    // MARK: private

    private func tick() {
        guard running, !paused else { return }
        liveElapsed += 1
        let intensity = currentIntensity()
        liveCadence.append(intensity)
        if liveCadence.count > 240 { liveCadence.removeFirst(liveCadence.count - 240) }
        if let plan = intervalPlan {
            var acc = 0
            var idx = 0
            for (i, seg) in plan.timeline.enumerated() {
                acc += seg.seconds
                if liveElapsed < acc {
                    idx = i
                    break
                }
                idx = i
            }
            intervalCursor = idx
        }
        let metres = Double(sensor.liveSteps) * (Double(settings.strideCm) / 100)
        if !goalHit, liveGoal.reached(metres: metres, seconds: liveElapsed) {
            goalHit = true
        }
        let key = DayKey.make()
        stepDays[key] = todaySteps
    }

    func currentIntensity() -> Double {
        guard let plan = intervalPlan, intervalCursor < plan.timeline.count else {
            return walkingBoost()
        }
        return plan.timeline[intervalCursor].intensity
    }

    private func walkingBoost() -> Double {
        sensor.walking ? 0.7 : 0.25
    }

    private func seedStarters() {
        let now = Date()
        let daily: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
        habits = [
            Habit(id: "seed-move", title: "Morning run", category: .movement, goalType: .duration, difficulty: .hard, colorIndex: 1, targetValue: 20, unit: "min", weekdays: [1, 3, 5], createdAt: now, note: "Out the door before the excuses wake up.", archived: false),
            Habit(id: "seed-water", title: "Drink water", category: .health, goalType: .quantity, difficulty: .easy, colorIndex: 7, targetValue: 8, unit: "glasses", weekdays: daily, createdAt: now, note: "", archived: false),
            Habit(id: "seed-read", title: "Read 10 pages", category: .mind, goalType: .check, difficulty: .normal, colorIndex: 6, targetValue: 1, unit: "times", weekdays: daily, createdAt: now, note: "", archived: false)
        ]
        let water = HabitLog(habitId: "seed-water", dayKey: DayKey.make(now), value: 2, target: 8, note: "")
        logs[water.key] = water
    }

    private func refreshAchievements(announce: Bool) {
        let values = achievementValues()
        var fresh: [Achievement] = []
        var next = unlocked
        for item in Catalog.achievements {
            let current = values[item.id] ?? 0
            if current >= item.threshold, !unlocked.contains(item.id) {
                next.insert(item.id)
                fresh.append(item)
            }
        }
        unlocked = next
        if announce { pendingUnlocks.append(contentsOf: fresh) }
        persistSoon()
    }

    func achievementValues() -> [String: Int] {
        let metres = lifetimeMetres
        let streak = longestStreak
        let cats = Set(activeHabits.map(\.category)).count
        let perfectTotal = countPerfectDays()
        return [
            "first_step": totalCompletions,
            "ten_checks": totalCompletions,
            "fifty_checks": totalCompletions,
            "two_hundred_checks": totalCompletions,
            "streak_3": streak,
            "streak_7": streak,
            "streak_30": streak,
            "streak_100": streak,
            "distance_5k": metres,
            "distance_25k": metres,
            "distance_100k": metres,
            "perfect_day": perfectTotal,
            "perfect_week": perfectTotal,
            "variety_3": cats,
            "variety_6": cats,
            "journal_7": journal.count,
            "journal_30": journal.count,
            "habits_5": activeHabits.count
        ]
    }

    private func countPerfectDays() -> Int {
        var days = Set<String>()
        for log in logs.values where log.isComplete {
            days.insert(log.dayKey)
        }
        return days.filter { key in
            summary(on: DayKey.date(key)).perfect
        }.count
    }

    private func currentSnap() -> Snapshot {
        Snapshot(
            habits: habits,
            logs: logs,
            journal: journal,
            profile: profile,
            unlocked: Array(unlocked),
            runs: runs,
            stepDays: stepDays,
            plans: plans,
            settings: settings,
            onboarded: onboarded
        )
    }

    private func persistSoon() {
        persistWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.persist() }
        persistWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }

    private func persist() {
        SnapshotStore.save(currentSnap())
    }

    private func tap() {
        guard settings.haptics else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

enum ThemeMode: String, CaseIterable {
    case system, light, dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}
