import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(Yard.self) private var yard
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        HenImage(name: Artwork.coach, size: 56)
                        VStack(alignment: .leading) {
                            Text("Crazy Hen Run").font(Typeface.title(17))
                            Text("Version \(Tuning.version) · stays on this phone")
                                .font(Typeface.caption(12)).foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Look") {
                    NavigationLink("Appearance") { AppearanceBoard() }
                    Toggle("Haptics", isOn: Binding(
                        get: { yard.settings.haptics },
                        set: { var s = yard.settings; s.haptics = $0; yard.applySettings(s) }
                    ))
                }

                Section("Tracking") {
                    HStack {
                        Label("Apple Health", systemImage: "heart.fill")
                        Spacer()
                        if yard.health.authorized {
                            Text("Connected").foregroundStyle(.secondary)
                        } else if yard.health.available {
                            Button("Connect") { yard.reconnectHealth() }
                        } else {
                            Text("Unavailable").foregroundStyle(.secondary)
                        }
                    }
                    Toggle("Week starts Monday", isOn: Binding(
                        get: { yard.settings.mondayFirst },
                        set: { var s = yard.settings; s.mondayFirst = $0; yard.applySettings(s) }
                    ))
                    Toggle("Hide completed habits", isOn: Binding(
                        get: { yard.settings.hideCompleted },
                        set: { var s = yard.settings; s.hideCompleted = $0; yard.applySettings(s) }
                    ))
                    NavigationLink("Habit ideas") { HabitLibrary() }
                    NavigationLink("Archived habits") { ArchiveBoard() }
                    NavigationLink("Steps & goals") { StepsBoard() }
                    NavigationLink("Intervals") { IntervalBoard() }
                    NavigationLink("Challenges") { ChallengeBoard() }
                }

                Section("Data") {
                    NavigationLink("Data & storage") { DataBoard() }
                }

                Section("Legal") {
                    NavigationLink("Privacy Policy") { WebSheet(title: "Privacy Policy", url: Links.privacy) }
                    NavigationLink("Support") { WebSheet(title: "Support", url: Links.support) }
                    NavigationLink("About") { AboutView() }
                }
            }
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }
}

struct AppearanceBoard: View {
    @Environment(Yard.self) private var yard

    var body: some View {
        Form {
            Picker("Theme", selection: Binding(
                get: { yard.themeMode },
                set: { yard.themeMode = $0 }
            )) {
                ForEach(ThemeMode.allCases, id: \.self) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            Section("Accent") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                    ForEach(Meadow.habitPaints.indices, id: \.self) { i in
                        Circle()
                            .fill(Meadow.habit(i))
                            .frame(width: 40, height: 40)
                            .overlay { if yard.settings.accentIndex == i { Image(systemName: "checkmark").foregroundStyle(.white) } }
                            .onTapGesture {
                                var s = yard.settings
                                s.accentIndex = i
                                yard.applySettings(s)
                            }
                    }
                }
            }
        }
        .navigationTitle("Appearance")
    }
}

struct DataBoard: View {
    @Environment(Yard.self) private var yard
    @State private var confirm = false
    @State private var copied = false

    var body: some View {
        List {
            Section {
                Text("Crazy Hen Run has no product server. Habits, journal entries, runs and photos stay on this device. Step data is only ever read from Apple Health, never written back.")
                    .font(Typeface.body(14))
            }
            Section("What is stored") {
                LabeledContent("Active habits", value: "\(yard.activeHabits.count)")
                LabeledContent("Archived", value: "\(yard.archivedHabits.count)")
                LabeledContent("Completions", value: "\(yard.totalCompletions)")
                LabeledContent("Journal entries", value: "\(yard.journal.count)")
                LabeledContent("Runs", value: "\(yard.runs.count)")
                LabeledContent("Profile photo", value: yard.profile.avatarPath.isEmpty ? "None" : "Saved")
            }
            Section("Export") {
                Text("A full JSON snapshot — habits, logs, journal, runs, steps and settings.")
                    .font(Typeface.caption(13)).foregroundStyle(.secondary)
                Button("Copy backup JSON") {
                    UIPasteboard.general.string = yard.exportJSON()
                    copied = true
                }
                if copied { Text("Copied to clipboard").foregroundStyle(Meadow.moss) }
            }
            Section("Danger zone") {
                Button("Reset all data", role: .destructive) { confirm = true }
            }
        }
        .navigationTitle("Data & storage")
        .alert("Reset everything?", isPresented: $confirm) {
            Button("Reset", role: .destructive) { yard.resetAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All habits, logs, journal entries, runs and your profile will be deleted from this device. There is no undo.")
        }
    }
}
