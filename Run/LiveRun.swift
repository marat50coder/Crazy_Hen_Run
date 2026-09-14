import SwiftUI

struct LiveRun: View {
    @Environment(Yard.self) private var yard
    @Environment(\.dismiss) private var dismiss
    var kind: RunKind
    var goal: RunGoal
    var plan: IntervalPlan?

    @State private var summary: RunSession?
    @State private var gate = 3
    @State private var feeling = 3
    @State private var note = ""

    var body: some View {
        ZStack {
            Meadow.forestDeep.ignoresSafeArea()
            if let summary {
                recap(summary)
            } else if gate > 0 {
                countdown
            } else {
                live
            }
        }
        .onAppear {
            Task { await countIn() }
        }
        .onDisappear {
            if yard.running { yard.discardRun() }
        }
    }

    private var countdown: some View {
        VStack(spacing: 12) {
            Text(kind.label).foregroundStyle(.white.opacity(0.7)).font(Typeface.title(18))
            Text(gate == 0 ? "GO" : "\(gate)")
                .font(.system(size: 92, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
    }

    private var live: some View {
        VStack(spacing: 22) {
            Text(kind.label).font(Typeface.caption(13, weight: .bold)).foregroundStyle(.white.opacity(0.7))
            HenImage(name: kind.hen, size: 120)
                .scaleEffect(1 + yard.currentIntensity() * 0.06)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: yard.running)
            Text(yard.liveElapsed.asClock)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
            if !goal.kind.isOpenish {
                ProgressView(value: goal.progress(metres: liveMetres, seconds: yard.liveElapsed))
                    .tint(Meadow.lime)
                    .padding(.horizontal, 40)
                Text(goal.chip).foregroundStyle(.white.opacity(0.7))
            }
            HStack(spacing: 28) {
                metric("Steps", "\(yard.sensor.liveSteps)")
                metric("Distance", liveMetres.asDistance)
                metric("Est. kcal", "\(estKcal)")
            }
            if let plan, yard.intervalCursor < plan.timeline.count {
                let seg = plan.timeline[yard.intervalCursor]
                Text("\(seg.label) · \(seg.seconds)s")
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.12), in: Capsule())
            }
            HStack(spacing: 16) {
                Button(yard.paused ? "Resume" : "Pause") { yard.pauseRun() }
                    .buttonStyle(.bordered)
                    .tint(.white)
                Button("Finish") {
                    summary = yard.finishRun()
                }
                .buttonStyle(.borderedProminent)
                .tint(Meadow.lime)
            }
            Button("Discard", role: .destructive) {
                yard.discardRun()
                dismiss()
            }
            .foregroundStyle(.white.opacity(0.7))
        }
        .padding()
    }

    private func recap(_ session: RunSession) -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HenImage(name: Artwork.happy, size: 120)
                    Text(session.distanceLabel).font(Typeface.display(36)).foregroundStyle(.white)
                    Text(session.durationLabel).foregroundStyle(.white.opacity(0.7))
                    HStack {
                        metric("Steps", "\(session.steps)")
                        metric("Pace", session.paceSecPerKm.asPace)
                        metric("Est. kcal", "\(session.calories)")
                    }
                    Text("How did it feel?").foregroundStyle(.white.opacity(0.8))
                    HStack {
                        ForEach(1...5, id: \.self) { n in
                            Button {
                                feeling = n
                            } label: {
                                Image(systemName: n <= feeling ? "star.fill" : "star")
                                    .foregroundStyle(Meadow.corn)
                            }
                        }
                    }
                    TextField("Note", text: $note, axis: .vertical)
                        .padding()
                        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                    ShareLink(item: "I just ran \(session.distanceLabel) in Crazy Hen Run.") {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .foregroundStyle(.white)
                }
                .padding()
            }
            .background(Meadow.forestDeep.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        var next = session
                        next.feeling = feeling
                        next.note = note
                        yard.updateRun(next)
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack {
            Text(title).font(Typeface.caption(11)).foregroundStyle(.white.opacity(0.6))
            Text(value).font(Typeface.title(16)).foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }

    private var liveMetres: Double {
        Double(yard.sensor.liveSteps) * (Double(yard.settings.strideCm) / 100)
    }

    private var estKcal: Int {
        max(1, Int(liveMetres / 1000 * kind.met * Double(yard.settings.weightKg) / 15))
    }

    private func countIn() async {
        for n in [3, 2, 1] {
            await MainActor.run { gate = n }
            try? await Task.sleep(nanoseconds: 700_000_000)
        }
        await MainActor.run {
            gate = 0
            yard.startRun(kind, goal: goal, plan: plan)
        }
    }
}

private extension RunGoal.Kind {
    var isOpenish: Bool { self == .open }
}
