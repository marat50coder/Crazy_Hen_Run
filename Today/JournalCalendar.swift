import SwiftUI

struct JournalEditor: View {
    @Environment(Yard.self) private var yard
    @Environment(\.dismiss) private var dismiss
    var day: Date

    @State private var mood: Mood = .okay
    @State private var note = ""
    @State private var energy = 3

    var body: some View {
        NavigationStack {
            Form {
                Section("Mood") {
                    HStack {
                        ForEach(Mood.allCases, id: \.self) { m in
                            Button {
                                mood = m
                            } label: {
                                VStack {
                                    Text(m.emoji).font(.title)
                                    Text(m.label).font(Typeface.caption(10))
                                }
                                .padding(6)
                                .background(mood == m ? m.paint.opacity(0.25) : .clear, in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Section("Energy") {
                    Slider(value: Binding(get: { Double(energy) }, set: { energy = Int($0.rounded()) }), in: 1...5, step: 1)
                    Text("\(energy) / 5")
                }
                Section("Note") {
                    TextField("How did the day feel?", text: $note, axis: .vertical)
                        .lineLimit(4...10)
                }
            }
            .navigationTitle(day.formatted(date: .abbreviated, time: .omitted))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        yard.saveJournal(JournalEntry(dayKey: DayKey.make(day), mood: mood, note: note, energy: energy))
                        dismiss()
                    }
                }
                if yard.journal[DayKey.make(day)] != nil {
                    ToolbarItem(placement: .bottomBar) {
                        Button("Delete entry", role: .destructive) {
                            yard.deleteJournal(DayKey.make(day))
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                if let existing = yard.journal[DayKey.make(day)] {
                    mood = existing.mood
                    note = existing.note
                    energy = existing.energy
                }
            }
        }
    }
}

struct JournalList: View {
    @Environment(Yard.self) private var yard
    @State private var pick: Date?

    var body: some View {
        List {
            let keys = yard.journal.keys.sorted(by: >)
            if keys.isEmpty {
                EmptyHen(title: "No pages yet", message: "Write a few lines after a run or a closed habit.", art: Artwork.coach)
                    .listRowBackground(Color.clear)
            }
            ForEach(keys, id: \.self) { key in
                if let entry = yard.journal[key] {
                    Button {
                        pick = DayKey.date(key)
                    } label: {
                        HStack {
                            Text(entry.mood.emoji)
                            VStack(alignment: .leading) {
                                Text(DayKey.date(key).formatted(date: .abbreviated, time: .omitted)).font(Typeface.title(16))
                                Text(entry.note.isEmpty ? entry.mood.label : entry.note)
                                    .font(Typeface.caption(13)).foregroundStyle(.secondary).lineLimit(2)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Journal")
        .sheet(item: Binding(
            get: { pick.map { DateBox(date: $0) } },
            set: { pick = $0?.date }
        )) { box in
            JournalEditor(day: box.date)
        }
    }
}

struct DateBox: Identifiable {
    var date: Date
    var id: String { DayKey.make(date) }
}

struct CalendarBoard: View {
    @Environment(Yard.self) private var yard
    @Environment(\.dismiss) private var dismiss
    @State private var month = Date()
    @State private var journalDay: Date?

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("Month", selection: $month, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                let sum = yard.summary(on: month)
                GlassPanel {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(month.formatted(date: .complete, time: .omitted)).font(Typeface.title(17))
                        Text("\(sum.completed) of \(sum.scheduled) closed")
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Calendar")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .safeAreaInset(edge: .bottom) {
                Button("Journal this day") {
                    journalDay = month
                }
                .font(Typeface.title(16, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .henGlassProminent()
                .padding()
            }
            .sheet(item: Binding(
                get: { journalDay.map { DateBox(date: $0) } },
                set: { journalDay = $0?.date }
            )) { box in
                JournalEditor(day: box.date)
            }
        }
    }
}

struct SprintView: View {
    @Environment(Yard.self) private var yard
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HenImage(name: Artwork.sprinter, size: 140)
                Text("Weekly sprint").font(Typeface.display(28))
                Text("\(yard.weeklyCompletions) of \(yard.settings.weeklySprint) habits this week")
                    .foregroundStyle(.secondary)
                ProgressRing(value: yard.weeklySprintProgress, size: 140, line: 12, color: Meadow.corn)
                    .overlay { Text("\(Int(yard.weeklySprintProgress * 100))%").font(Typeface.title(20, weight: .bold)) }
                Stepper("Target: \(yard.settings.weeklySprint)", value: Binding(
                    get: { yard.settings.weeklySprint },
                    set: {
                        var s = yard.settings
                        s.weeklySprint = $0
                        yard.applySettings(s)
                    }
                ), in: 3...80)
                .padding()
                .henGlass(corner: 18)
                Spacer()
            }
            .padding()
            .navigationTitle("Sprint")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }
}
