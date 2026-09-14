import SwiftUI

struct RootFlow: View {
    @Environment(Yard.self) private var yard
    @State private var booted = false
    @State private var tab = 0
    @State private var toast: Achievement?

    var body: some View {
        Group {
            if !booted {
                BootView {
                    booted = true
                    // Returning users skip the onboarding guide entirely,
                    // so this is their equivalent "first thing after boot"
                    // moment to ask for Health access.
                    if yard.onboarded { yard.connectHealth() }
                }
            } else if !yard.onboarded {
                WelcomeView()
            } else {
                tabs
            }
        }
        .preferredColorScheme(yard.themeMode.colorScheme)
        .tint(yard.accent)
        .onChange(of: yard.pendingUnlocks.count) {
            showUnlock()
        }
    }

    private var tabs: some View {
        TabView(selection: $tab) {
            Tab("Today", systemImage: "bolt.fill", value: 0) {
                TodayView()
            }
            Tab("Run", systemImage: "figure.run", value: 1) {
                RunHub()
            }
            Tab("Stats", systemImage: "chart.xyaxis.line", value: 2) {
                StatsView()
            }
            Tab("Yard", systemImage: "bird.fill", value: 3) {
                YardView()
            }
            Tab("You", systemImage: "person.fill", value: 4) {
                ProfileView()
            }
        }
        .overlay(alignment: .top) {
            if let toast {
                UnlockToast(item: toast)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
        .animation(.spring(duration: 0.45), value: toast?.id)
    }

    private func showUnlock() {
        let batch = yard.consumeUnlocks()
        guard let first = batch.first else { return }
        withAnimation { toast = first }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            withAnimation { toast = nil }
        }
    }
}
