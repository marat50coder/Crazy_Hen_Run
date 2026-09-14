import SwiftUI

struct RunHub: View {
    @Environment(Yard.self) private var yard
    @State private var kind: RunKind = .free
    @State private var goal: RunGoal = .open
    @State private var goLive = false
    @State private var showSteps = false
    @State private var showHistory = false
    @State private var showIntervals = false
    @State private var showChallenges = false
    @State private var showTypes = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        FaceMark(profile: yard.profile, size: 46)
                        VStack(alignment: .leading) {
                            Text("Ready to run").font(Typeface.caption(12)).foregroundStyle(.secondary)
                            Text(yard.rank.title).font(Typeface.title(22))
                        }
                        Spacer()
                        Button { showSettings = true } label: {
                            Image(systemName: "slider.horizontal.3")
                                .padding(10)
                                .henGlass(corner: 20)
                        }
                    }

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(kind.label).font(Typeface.title(20))
                                    Text(goal.chip).font(Typeface.caption(13)).foregroundStyle(.secondary)
                                }
                                Spacer()
                                HenImage(name: kind.hen, size: 72)
                            }
                            Button {
                                goLive = true
                            } label: {
                                Label("Start", systemImage: "play.fill")
                                    .font(Typeface.title(18, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .henGlassProminent()
                            .tint(Meadow.go)
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(RunKind.allCases, id: \.self) { k in
                                Button {
                                    kind = k
                                } label: {
                                    Text(k.label)
                                        .font(Typeface.caption(13, weight: .semibold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(kind == k ? k.paint : Color.secondary.opacity(0.12), in: Capsule())
                                        .foregroundStyle(kind == k ? .white : .primary)
                                }
                            }
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(RunGoal.chips, id: \.value) { g in
                                Button {
                                    goal = g
                                } label: {
                                    Text(g.chip)
                                        .font(Typeface.caption(13, weight: .semibold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(goal == g ? Meadow.moss : Color.secondary.opacity(0.12), in: Capsule())
                                        .foregroundStyle(goal == g ? .white : .primary)
                                }
                            }
                        }
                    }

                    Button { showSteps = true } label: {
                        HStack {
                            ProgressRing(value: min(1, Double(yard.todaySteps) / Double(max(yard.settings.stepGoal, 1))), size: 64, line: 7, color: Meadow.lime)
                            VStack(alignment: .leading) {
                                Text("Steps today").font(Typeface.caption(12)).foregroundStyle(.secondary)
                                Text("\(yard.todaySteps)").font(Typeface.title(22))
                                Text("Goal \(yard.settings.stepGoal) · estimate \(Int(Double(yard.todaySteps) * 0.04)) kcal")
                                    .font(Typeface.caption(12)).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                        }
                        .padding(14)
                        .henGlass(corner: 22)
                    }
                    .buttonStyle(.plain)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        quick("History", "clock.arrow.circlepath") { showHistory = true }
                        quick("Intervals", "metronome.fill") { showIntervals = true }
                        quick("Challenges", "trophy.fill") { showChallenges = true }
                        quick("Run types", "square.grid.2x2") { showTypes = true }
                    }

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("This week").font(Typeface.title(18))
                            Text("\(yard.weekRuns().count) / \(yard.settings.weeklyRunTarget) runs · \(yard.weekDistance.asDistance)")
                                .foregroundStyle(.secondary)
                            ProgressView(value: min(1, Double(yard.weekRuns().count) / Double(max(yard.settings.weeklyRunTarget, 1)))).tint(Meadow.go)
                        }
                    }

                    HStack {
                        Text("Recent runs").font(Typeface.title(18))
                        Spacer()
                        if !yard.runs.isEmpty {
                            Button("See all") { showHistory = true }
                        }
                    }
                    if yard.runs.isEmpty {
                        EmptyHen(title: "No runs yet", message: "Start a free run. Distance comes from the step sensor — no GPS.", art: Artwork.runner)
                    } else {
                        ForEach(yard.runs.prefix(3)) { session in
                            RunCell(session: session)
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $goLive) {
                LiveRun(kind: kind, goal: goal)
            }
            .sheet(isPresented: $showSteps) { StepsBoard() }
            .sheet(isPresented: $showHistory) { RunHistory() }
            .sheet(isPresented: $showIntervals) { IntervalBoard() }
            .sheet(isPresented: $showChallenges) { ChallengeBoard() }
            .sheet(isPresented: $showTypes) { RunTypes() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .onAppear { yard.syncHealthToday() }
        }
    }

    private func quick(_ title: String, _ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: symbol).font(.title2).foregroundStyle(Meadow.moss)
                Text(title).font(Typeface.title(16))
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
            .henGlass(corner: 20)
        }
        .buttonStyle(.plain)
    }
}

struct RunCell: View {
    var session: RunSession

    var body: some View {
        HStack {
            Circle().fill(session.type.paint.opacity(0.2)).frame(width: 42, height: 42)
                .overlay(Image(systemName: session.type.symbol).foregroundStyle(session.type.paint))
            VStack(alignment: .leading) {
                Text(session.type.label).font(Typeface.title(16))
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(Typeface.caption(12)).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(session.distanceLabel).font(Typeface.title(16))
                Text(session.durationLabel).font(Typeface.caption(12)).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .henGlass(corner: 18)
    }
}

struct RunTypes: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(RunKind.allCases, id: \.self) { kind in
                HStack(spacing: 14) {
                    HenImage(name: kind.hen, size: 56)
                    VStack(alignment: .leading) {
                        Text(kind.label).font(Typeface.title(17))
                        Text(kind.blurb).font(Typeface.caption(13)).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Run types")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }
}
