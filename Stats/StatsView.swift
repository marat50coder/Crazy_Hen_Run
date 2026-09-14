import SwiftUI

struct StatsView: View {
    @Environment(Yard.self) private var yard
    @State private var range = 14

    var body: some View {
        NavigationStack {
            Group {
                if yard.habits.isEmpty && yard.totalCompletions == 0 && yard.runs.isEmpty {
                    EmptyHen(title: "Nothing to measure yet", message: "Close a few habits or finish a run and this screen fills up.")
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Your numbers").font(Typeface.caption(12)).foregroundStyle(.secondary)
                                    Text("Statistics").font(Typeface.display(28))
                                }
                                Spacer()
                                NavigationLink { WeeklyReport() } label: {
                                    Image(systemName: "doc.text")
                                }
                                .accessibilityLabel("Weekly report")
                            }

                            Picker("Range", selection: $range) {
                                Text("7D").tag(7)
                                Text("14D").tag(14)
                                Text("30D").tag(30)
                            }
                            .pickerStyle(.segmented)

                            let days = (0..<range).reversed().compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: DayKey.start()) }
                            let sums = days.map { yard.summary(on: $0) }
                            let peak = max(sums.map(\.scheduled).max() ?? 1, 1)

                            GlassPanel {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Habits closed").font(Typeface.title(17))
                                    HStack(alignment: .bottom, spacing: 3) {
                                        ForEach(sums, id: \.day) { row in
                                            Capsule()
                                                .fill(row.perfect ? Meadow.lime : Meadow.moss.opacity(0.7))
                                                .frame(height: max(4, 110 * CGFloat(row.completed) / CGFloat(peak)))
                                                .frame(maxWidth: .infinity, alignment: .bottom)
                                        }
                                    }
                                    .frame(height: 120)
                                }
                            }

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                stat("Track", yard.distanceLabel, Meadow.moss)
                                stat("Checks", "\(yard.totalCompletions)", Meadow.corn)
                                stat("Best streak", "\(yard.longestStreak)d", Meadow.sunset)
                                stat("Runs", "\(yard.runs.count)", Meadow.sky)
                            }

                            GlassPanel {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("One track").font(Typeface.title(17))
                                    Text("Habits, recorded runs and daily steps share a single distance. The hen in Today and Yard always agrees.")
                                        .font(Typeface.body(14))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func stat(_ title: String, _ value: String, _ tone: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(Typeface.caption(12)).foregroundStyle(.secondary)
            Text(value).font(Typeface.title(20)).foregroundStyle(tone)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .henGlass(corner: 20)
    }
}

struct WeeklyReport: View {
    @Environment(Yard.self) private var yard
    let week: [Date]

    init() {
        self.week = DayKey.week(of: .now, mondayFirst: true)
    }

    var body: some View {
        List {
            Section("Habits") {
                let closed = week.map { yard.summary(on: $0).completed }.reduce(0, +)
                LabeledContent("Closed this week", value: "\(closed)")
                LabeledContent("Sprint", value: "\(yard.weeklyCompletions)/\(yard.settings.weeklySprint)")
            }
            Section("Running") {
                LabeledContent("Sessions", value: "\(yard.weekRuns().count)")
                LabeledContent("Distance", value: yard.weekDistance.asDistance)
                LabeledContent("Move streak", value: "\(yard.moveStreak) days")
            }
            ShareLink(item: reportText)
        }
        .navigationTitle("Weekly report")
    }

    private var reportText: String {
        "Crazy Hen Run · this week: \(yard.weeklyCompletions) habits, \(yard.weekRuns().count) runs, \(yard.weekDistance.asDistance)."
    }
}
