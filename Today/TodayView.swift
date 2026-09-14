import SwiftUI

struct TodayView: View {
    @Environment(Yard.self) private var yard
    @State private var selected = Date()
    @State private var editor: Habit?
    @State private var creating = false
    @State private var detail: Habit?
    @State private var showLibrary = false
    @State private var showSprint = false
    @State private var showJournal = false
    @State private var showCalendar = false
    @State private var showSettings = false

    var body: some View {
        let rows = yard.habits(on: selected)
        let visible = yard.settings.hideCompleted ? rows.filter { $0.1?.isComplete != true } : rows
        let sum = yard.summary(on: selected)
        let week = DayKey.week(of: selected, mondayFirst: yard.settings.mondayFirst)
        let summaries = Dictionary(uniqueKeysWithValues: week.map { (DayKey.start($0), yard.summary(on: $0)) })

        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    trackCard(sum: sum)
                    WeekStrip(days: week, selected: selected, summaries: summaries) { selected = $0 }
                        .padding(12)
                        .henGlass(corner: 22)

                    HStack(spacing: 10) {
                        mini("Weekly sprint", "\(yard.weeklyCompletions)/\(yard.settings.weeklySprint)", yard.weeklySprintProgress, Meadow.corn) { showSprint = true }
                        mini("Journal", yard.journal[DayKey.make(selected)]?.mood.label ?? "Not written", yard.journal[DayKey.make(selected)] == nil ? 0 : 1, Meadow.lavender) { showJournal = true }
                    }

                    HStack {
                        Text(Calendar.current.isDateInToday(selected) ? "On the track today" : selected.formatted(date: .abbreviated, time: .omitted))
                            .font(Typeface.title(18))
                        Spacer()
                        if !rows.isEmpty {
                            Button {
                                yard.settings.hideCompleted.toggle()
                                yard.applySettings(yard.settings)
                            } label: {
                                Image(systemName: yard.settings.hideCompleted ? "eye.slash" : "eye")
                            }
                            .accessibilityLabel(yard.settings.hideCompleted ? "Show completed" : "Hide completed")
                        }
                    }

                    if yard.activeHabits.isEmpty {
                        EmptyHen(title: "The road is empty", message: "Add your first habit and this screen turns into your daily track.")
                        HStack {
                            Button("Create a habit") { creating = true }
                                .henGlassProminent()
                            Button("Browse ideas") { showLibrary = true }
                        }
                    } else if visible.isEmpty {
                        GlassPanel {
                            HStack {
                                HenImage(name: Artwork.happy, size: 64)
                                VStack(alignment: .leading) {
                                    Text(rows.isEmpty ? "Rest day" : "Everything closed").font(Typeface.title(18))
                                    Text(rows.isEmpty ? "No habits are scheduled for this day." : "Your hen is doing a victory lap.")
                                        .font(Typeface.body(14)).foregroundStyle(.secondary)
                                }
                            }
                        }
                    } else {
                        ForEach(visible, id: \.0.id) { pair in
                            HabitRow(habit: pair.0, log: pair.1, day: selected) {
                                detail = pair.0
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 120)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showCalendar = true } label: { Image(systemName: "calendar") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button { creating = true } label: { Image(systemName: "plus") }
                            .accessibilityLabel("New habit")
                        Button { showSettings = true } label: { Image(systemName: "slider.horizontal.3") }
                    }
                }
            }
            .sheet(isPresented: $creating) { HabitEditor() }
            .sheet(item: $editor) { HabitEditor(existing: $0) }
            .sheet(item: $detail) { HabitDetail(habit: $0) }
            .sheet(isPresented: $showLibrary) { HabitLibrary() }
            .sheet(isPresented: $showSprint) { SprintView() }
            .sheet(isPresented: $showJournal) { JournalEditor(day: selected) }
            .sheet(isPresented: $showCalendar) { CalendarBoard() }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
    }

    private var header: some View {
        HStack {
            FaceMark(profile: yard.profile, size: 46)
            VStack(alignment: .leading, spacing: 2) {
                Text("Today").font(Typeface.caption(12, weight: .semibold)).foregroundStyle(.secondary)
                Text(yard.profile.name).font(Typeface.title(22))
            }
            Spacer()
            HenImage(name: yard.rank.art, size: 52)
        }
        .padding(.top, 4)
    }

    private func trackCard(sum: DaySummary) -> some View {
        GlassPanel {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(yard.rank.title.uppercased())
                        .font(Typeface.caption(11, weight: .bold))
                        .foregroundStyle(Meadow.moss)
                    Text(yard.distanceLabel).font(Typeface.display(28))
                    Text(Coach.line(closed: sum.completed, scheduled: sum.scheduled, streak: yard.longestStreak))
                        .font(Typeface.body(14))
                        .foregroundStyle(.secondary)
                    ProgressView(value: sum.ratio)
                        .tint(Meadow.moss)
                }
                Spacer()
                HenImage(name: yard.rank.art, size: 88)
            }
        }
    }

    private func mini(_ title: String, _ value: String, _ progress: Double, _ tone: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(Typeface.caption(12, weight: .semibold)).foregroundStyle(.secondary)
                Text(value).font(Typeface.title(16))
                ProgressView(value: progress).tint(tone)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .henGlass(corner: 20)
        }
        .buttonStyle(.plain)
    }
}

struct HabitRow: View {
    @Environment(Yard.self) private var yard
    var habit: Habit
    var log: HabitLog?
    var day: Date
    var onOpen: () -> Void

    var body: some View {
        let value = log?.value ?? 0
        let target = habit.effectiveTarget
        let done = value >= target
        HStack(spacing: 12) {
            Button(action: onOpen) {
                Circle()
                    .fill(Meadow.habit(habit.colorIndex).opacity(0.22))
                    .frame(width: 42, height: 42)
                    .overlay(Image(systemName: habit.category.symbol).foregroundStyle(Meadow.habit(habit.colorIndex)))
            }
            .buttonStyle(.plain)

            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(habit.title).font(Typeface.title(16)).strikethrough(done, color: .secondary)
                    Text(habit.targetLabel).font(Typeface.caption(12)).foregroundStyle(.secondary)
                    if habit.goalType != .check {
                        ProgressView(value: min(1, Double(value) / Double(max(target, 1)))).tint(Meadow.habit(habit.colorIndex))
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            controls(value: value, target: target)
        }
        .padding(14)
        .henGlass(corner: 20)
        .swipeActions(edge: .trailing) {
            Button("Archive") { yard.archive(habit, true) }.tint(.orange)
        }
    }

    @ViewBuilder
    private func controls(value: Int, target: Int) -> some View {
        switch habit.goalType {
        case .check:
            Button {
                yard.toggle(habit, on: day)
            } label: {
                Image(systemName: value >= target ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(value >= target ? Meadow.moss : .secondary)
            }
            .accessibilityLabel(value >= target ? "Mark incomplete" : "Mark complete")
        case .quantity, .duration:
            HStack(spacing: 8) {
                Button { yard.bump(habit, on: day, delta: -1) } label: {
                    Image(systemName: "minus.circle.fill")
                }
                Text("\(value)/\(target)")
                    .font(Typeface.caption(13, weight: .bold))
                    .monospacedDigit()
                Button { yard.bump(habit, on: day, delta: 1) } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
            .foregroundStyle(Meadow.habit(habit.colorIndex))
        }
    }
}
