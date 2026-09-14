import SwiftUI

struct WelcomeView: View {
    @Environment(Yard.self) private var yard
    @State private var page = 0

    private let slides: [(art: String, kicker: String, title: String, body: String, tint: Color)] = [
        (Artwork.curious, "Welcome", "Every habit is a\nstretch of road", "Crazy Hen Run turns your daily routine into a track. Add habits, close them, and watch the distance add up.", Meadow.lime),
        (Artwork.runner, "Run", "Close habits,\ncover distance", "Every completed habit puts metres behind you. Harder habits pay more, so the effort actually shows.", Meadow.moss),
        (Artwork.sprinter, "Grow", "Your hen levels\nup with you", "Chick, Hen, Runner, Sprinter, Legend. Keep showing up and the bird in your pocket gets faster.", Meadow.corn),
        (Artwork.legend, "Own it", "Your notes stay\non your phone", "No account, no ads, no cloud. Habits, notes and photos stay on this device.", Meadow.comb)
    ]

    var body: some View {
        let slide = slides[page]
        VStack(spacing: 0) {
            HStack {
                HenImage(name: Artwork.logo, size: 42)
                Spacer()
                Button("Skip") { yard.finishWelcome() }
                    .font(Typeface.body(16, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            TabView(selection: $page) {
                ForEach(slides.indices, id: \.self) { i in
                    slideView(slides[i]).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: 18) {
                HStack(spacing: 6) {
                    ForEach(slides.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Meadow.moss : Color.secondary.opacity(0.25))
                            .frame(width: i == page ? 22 : 7, height: 7)
                    }
                }
                Button {
                    if page == slides.count - 1 {
                        yard.finishWelcome()
                    } else {
                        withAnimation(.snappy) { page += 1 }
                    }
                } label: {
                    Text(page == slides.count - 1 ? "Get started" : "Continue")
                        .font(Typeface.title(17, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .henGlassProminent()
                .tint(Meadow.forest)
            }
            .padding(22)
        }
        .background(
            LinearGradient(colors: [slide.tint.opacity(0.28), Color(.systemBackground), Color(.systemBackground)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .onAppear {
            // Boot screen is already gone by the time this guide shows —
            // this is the first moment it's safe to surface the Health
            // system prompt without it competing with the splash screen.
            yard.connectHealth()
        }
    }

    private func slideView(_ slide: (art: String, kicker: String, title: String, body: String, tint: Color)) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Spacer()
            HStack {
                Spacer()
                HenImage(name: slide.art, size: 220)
                    .scaleEffect(page == slides.firstIndex(where: { $0.art == slide.art }) ? 1 : 0.92)
                Spacer()
            }
            Text(slide.kicker.uppercased())
                .font(Typeface.caption(12, weight: .bold))
                .tracking(1.3)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(slide.tint.opacity(0.2), in: Capsule())
            Text(slide.title)
                .font(Typeface.display(32))
                .lineSpacing(2)
            Text(slide.body)
                .font(Typeface.body(17))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}
