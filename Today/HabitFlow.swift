import SwiftUI

struct HabitEditor: View {
    @Environment(Yard.self) private var yard
    @Environment(\.dismiss) private var dismiss
    var existing: Habit?

    @State private var title = ""
    @State private var note = ""
    @State private var category = HabitCategory.movement
    @State private var goal = HabitGoal.check
    @State private var difficulty = HabitDifficulty.normal
    @State private var color = 0
    @State private var target = 1
    @State private var unit = "times"
    @State private var days: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
    @State private var step = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Step", selection: $step) {
                    Text("Basics").tag(0)
                    Text("Goal").tag(1)
                    Text("Rhythm").tag(2)
                    Text("Style").tag(3)
                }
                .pickerStyle(.segmented)
                .padding()

                TabView(selection: $step) {
                    basics.tag(0)
                    goalPage.tag(1)
                    rhythm.tag(2)
                    style.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                Button(step == 3 ? "Save habit" : "Continue") {
                    if step < 3 { step += 1 } else { save() }
                }
                .font(Typeface.title(17, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .henGlassProminent()
                .disabled(step == 0 && title.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(existing == nil ? "New habit" : "Edit habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .onAppear { hydrate() }
        }
    }

    private var basics: some View {
        Form {
            TextField("Name", text: $title)
            TextField("Note", text: $note, axis: .vertical)
            Picker("Category", selection: $category) {
                ForEach(HabitCategory.allCases, id: \.self) { c in
                    Label(c.label, systemImage: c.symbol).tag(c)
                }
            }
        }
    }

    private var goalPage: some View {
        Form {
            Picker("Type", selection: $goal) {
                ForEach(HabitGoal.allCases, id: \.self) { g in
                    Text(g.label).tag(g)
                }
            }
            if goal != .check {
                Stepper("Target: \(target) \(goal == .duration ? "min" : unit)", value: $target, in: 1...200)
                if goal == .quantity {
                    TextField("Unit", text: $unit)
                }
            }
            Picker("Effort", selection: $difficulty) {
                ForEach(HabitDifficulty.allCases, id: \.self) { d in
                    Text(d.label).tag(d)
                }
            }
        }
    }

    private var rhythm: some View {
        Form {
            Section("Days") {
                ForEach(1...7, id: \.self) { d in
                    let name = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][d - 1]
                    Toggle(name, isOn: Binding(
                        get: { days.contains(d) },
                        set: { on in if on { days.insert(d) } else { days.remove(d) } }
                    ))
                }
            }
        }
    }

    private var style: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 52))], spacing: 12) {
                ForEach(Meadow.habitPaints.indices, id: \.self) { i in
                    Circle()
                        .fill(Meadow.habit(i))
                        .frame(width: 46, height: 46)
                        .overlay { if color == i { Image(systemName: "checkmark").foregroundStyle(.white) } }
                        .onTapGesture { color = i }
                }
            }
            .padding()
        }
    }

    private func hydrate() {
        guard let existing else { return }
        title = existing.title
        note = existing.note
        category = existing.category
        goal = existing.goalType
        difficulty = existing.difficulty
        color = existing.colorIndex
        target = existing.targetValue
        unit = existing.unit
        days = existing.weekdays
    }

    private func save() {
        let habit = Habit(
            id: existing?.id ?? newId(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            goalType: goal,
            difficulty: difficulty,
            colorIndex: color,
            targetValue: target,
            unit: unit,
            weekdays: days.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : days,
            createdAt: existing?.createdAt ?? .now,
            note: note,
            archived: existing?.archived ?? false
        )
        yard.upsert(habit)
        dismiss()
    }
}

struct HabitDetail: View {
    @Environment(Yard.self) private var yard
    @Environment(\.dismiss) private var dismiss
    var habit: Habit
    @State private var editing = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        HenImage(name: Artwork.coach, size: 72)
                        VStack(alignment: .leading) {
                            Text(habit.title).font(Typeface.title(22))
                            Text(habit.category.label).foregroundStyle(.secondary)
                            Text(habit.targetLabel).font(Typeface.caption(13))
                        }
                    }
                    LabeledContent("Streak", value: "\(yard.streak(for: habit)) days")
                    LabeledContent("Completions", value: "\(yard.logs.values.filter { $0.habitId == habit.id && $0.isComplete }.count)")
                    if !habit.note.isEmpty { Text(habit.note) }
                }
                Section {
                    Button("Edit") { editing = true }
                    Button(habit.archived ? "Restore" : "Archive") { yard.archive(habit, !habit.archived); dismiss() }
                    Button("Delete", role: .destructive) { yard.delete(habit); dismiss() }
                }
            }
            .navigationTitle("Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .sheet(isPresented: $editing) { HabitEditor(existing: habit) }
        }
    }
}

struct HabitLibrary: View {
    @Environment(\.dismiss) private var dismiss
    @State private var filter: HabitCategory?
    @State private var draft: Habit?

    var body: some View {
        NavigationStack {
            ScrollView {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        chip("All", on: filter == nil) { filter = nil }
                        ForEach(HabitCategory.allCases, id: \.self) { c in
                            chip(c.label, on: filter == c) { filter = c }
                        }
                    }
                    .padding(.horizontal)
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Catalog.templates.filter { filter == nil || $0.category == filter }, id: \.title) { item in
                        Button {
                            draft = item.materialize()
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: item.category.symbol).foregroundStyle(Meadow.habit(item.colorIndex))
                                Text(item.title).font(Typeface.title(16)).foregroundStyle(.primary)
                                Text(item.blurb).font(Typeface.caption(12)).foregroundStyle(.secondary).lineLimit(3)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
                            .henGlass(corner: 20)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Ideas")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .sheet(item: $draft) { HabitEditor(existing: $0) }
        }
    }

    private func chip(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(Typeface.caption(13, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(on ? Meadow.moss : Color.secondary.opacity(0.12), in: Capsule())
            .foregroundStyle(on ? .white : .primary)
    }
}

struct ArchiveBoard: View {
    @Environment(Yard.self) private var yard

    var body: some View {
        Group {
            if yard.archivedHabits.isEmpty {
                EmptyHen(title: "Archive is empty", message: "Habits you archive land here. Nothing is deleted until you say so.")
            } else {
                List(yard.archivedHabits) { habit in
                    HStack {
                        Text(habit.title)
                        Spacer()
                        Button("Restore") { yard.archive(habit, false) }
                    }
                }
            }
        }
        .navigationTitle("Archive")
    }
}
