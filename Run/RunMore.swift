import SwiftUI

struct RunHistory: View {
    @Environment(Yard.self) private var yard
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if yard.runs.isEmpty {
                    EmptyHen(title: "No history yet", message: "Finished runs land here.", art: Artwork.runner)
                } else {
                    List {
                        ForEach(yard.runs) { session in
                            NavigationLink {
                                RunDetail(session: session)
                            } label: {
                                RunCell(session: session)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        .onDelete { idx in
                            idx.map { yard.runs[$0] }.forEach(yard.deleteRun)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("History")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }
}

struct RunDetail: View {
    @Environment(Yard.self) private var yard
    var session: RunSession

    var body: some View {
        List {
            Section {
                LabeledContent("Type", value: session.type.label)
                LabeledContent("Distance", value: session.distanceLabel)
                LabeledContent("Time", value: session.durationLabel)
                LabeledContent("Pace", value: session.paceSecPerKm.asPace)
                LabeledContent("Steps", value: "\(session.steps)")
                LabeledContent("Est. calories", value: "\(session.calories)")
            }
            if !session.note.isEmpty {
                Section("Note") { Text(session.note) }
            }
            ShareLink(item: "Crazy Hen Run · \(session.type.label) · \(session.distanceLabel) in \(session.durationLabel)")
        }
        .navigationTitle(session.startedAt.formatted(date: .abbreviated, time: .omitted))
    }
}

struct StepsBoard: View {
    @Environment(Yard.self) private var yard
    @Environment(\.dismiss) private var dismiss
    @State private var range = 7

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        ProgressRing(value: min(1, Double(yard.todaySteps) / Double(max(yard.settings.stepGoal, 1))), size: 110, line: 10, color: Meadow.lime)
                            .overlay {
                                VStack {
                                    Text("\(yard.todaySteps)").font(Typeface.title(20, weight: .bold))
                                    Text("of \(yard.settings.stepGoal)").font(Typeface.caption(11))
                                }
                            }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(yard.health.authorized ? "Synced with Apple Health" : "Motion sensor only — no GPS")
                                .font(Typeface.caption(12)).foregroundStyle(.secondary)
                            if yard.health.available, !yard.health.authorized {
                                Button("Connect Apple Health") { yard.reconnectHealth() }
                                    .henGlassProminent()
                            }
                            if !yard.sensor.authorized {
                                Button("Enable step counting for runs") { yard.enableSteps() }
                            } else if !yard.sensor.available {
                                Text("This device has no step sensor. On a simulator, live runs still tick so you can review the flow.")
                                    .font(Typeface.caption(12)).foregroundStyle(.secondary)
                            }
                            Text("Calories are a rough estimate, not medical data.")
                                .font(Typeface.caption(12)).foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .henGlass(corner: 22)

                    Picker("Range", selection: $range) {
                        Text("7D").tag(7)
                        Text("14D").tag(14)
                        Text("30D").tag(30)
                    }
                    .pickerStyle(.segmented)

                    let series = (0..<range).reversed().map { offset -> (Date, Int) in
                        let day = Calendar.current.date(byAdding: .day, value: -offset, to: DayKey.start()) ?? .now
                        return (day, yard.stepDays[DayKey.make(day)] ?? 0)
                    }
                    let peak = max(series.map(\.1).max() ?? 1, 1)

                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(series, id: \.0) { item in
                            VStack {
                                Capsule()
                                    .fill(Meadow.moss.opacity(0.8))
                                    .frame(height: max(6, 120 * CGFloat(item.1) / CGFloat(peak)))
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 130)
                    .padding()
                    .henGlass(corner: 20)

                    Stepper("Goal \(yard.settings.stepGoal)", value: Binding(
                        get: { yard.settings.stepGoal },
                        set: { var s = yard.settings; s.stepGoal = $0; yard.applySettings(s) }
                    ), in: 1_000...30_000, step: 500)

                    Stepper("Stride \(yard.settings.strideCm) cm", value: Binding(
                        get: { yard.settings.strideCm },
                        set: { var s = yard.settings; s.strideCm = $0; yard.applySettings(s) }
                    ), in: 40...120)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Steps")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .onAppear {
                yard.syncHealthToday()
                yard.backfillHealthHistory(days: 30)
            }
        }
    }
}

struct IntervalBoard: View {
    @Environment(Yard.self) private var yard
    @Environment(\.dismiss) private var dismiss
    @State private var live: IntervalPlan?

    var body: some View {
        NavigationStack {
            List {
                ForEach(yard.allPlans) { plan in
                    Button {
                        live = plan
                    } label: {
                        VStack(alignment: .leading) {
                            Text(plan.name).font(Typeface.title(17))
                            Text("\(plan.totalSeconds / 60) min · \(plan.repeats)×").foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Intervals")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .fullScreenCover(item: $live) { plan in
                LiveRun(kind: .interval, goal: .open, plan: plan)
            }
        }
    }
}

struct ChallengeBoard: View {
    @Environment(Yard.self) private var yard
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(Catalog.challenges) { item in
                let current = yard.challengeValue(item.metric)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: item.symbol).foregroundStyle(item.paint)
                        Text(item.title).font(Typeface.title(17))
                        Spacer()
                        if current >= item.target {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Meadow.moss)
                        }
                    }
                    Text(item.blurb).font(Typeface.caption(13)).foregroundStyle(.secondary)
                    ProgressView(value: item.progress(current)).tint(item.paint)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Challenges")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }
}
