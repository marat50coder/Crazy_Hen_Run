import SwiftUI
import UIKit

struct BootView: View {
    var onReady: () -> Void

    @Environment(Yard.self) private var yard
    @State private var progress = 0.0
    @State private var percent = 0
    @State private var handed = false

    private let stages: [(Double, UInt64, UInt64)] = [
        (0.16, 280, 90),
        (0.34, 300, 100),
        (0.52, 280, 90),
        (0.71, 320, 110),
        (0.88, 300, 120),
        (1.00, 340, 180)
    ]

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height
            ZStack {
                bootArt(wide: wide, screen: geo.size)
                    .ignoresSafeArea()
                VStack {
                    Spacer()
                    VStack(spacing: wide ? 8 : 12) {
                        Text("Loading")
                            .font(Typeface.title(wide ? 16 : 20, weight: .bold))
                            .foregroundStyle(Meadow.forest)
                        track(width: geo.size.width * (wide ? 0.36 : 0.72), hen: wide ? 28 : 44)
                        Text("\(percent)%")
                            .font(Typeface.title(wide ? 15 : 20, weight: .bold))
                            .foregroundStyle(Meadow.forest)
                            .monospacedDigit()
                    }
                    .padding(.bottom, wide ? 16 : geo.size.height * 0.10)
                }
            }
        }
        .statusBarHidden(false)
        .task { await run() }
    }

    private func bootArt(wide: Bool, screen: CGSize) -> some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                // The iPhone boot art was drawn for a narrow, tall canvas and
                // doesn't translate to iPad's very different proportions in
                // either orientation. iPad gets its own simple treatment
                // instead: the same meadow palette as a gradient, with the
                // crest centered on top — no cropping, no stretching, same
                // look in portrait and landscape.
                let side = min(max(min(screen.width, screen.height) * 0.5, 220), 460)
                ZStack {
                    LinearGradient(
                        colors: [Meadow.limeSoft, Meadow.lime, Meadow.moss],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    // The mark's dark green wordmark and pale body all but
                    // vanish on a same-toned green field, so a soft cream
                    // halo lifts it off the gradient without breaking the look.
                    RadialGradient(
                        colors: [Meadow.cream.opacity(0.6), Meadow.cream.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: side * 0.85
                    )
                    .frame(width: side * 1.8, height: side * 1.8)
                    if let crest = UIImage(named: Artwork.logo) ?? bundleWebp(Artwork.logo) {
                        Image(uiImage: crest)
                            .resizable()
                            .scaledToFit()
                            .frame(width: side)
                            .shadow(color: Meadow.forest.opacity(0.22), radius: 16, y: 8)
                    }
                }
            } else if let img = UIImage(named: wide ? Artwork.bootLandscape : Artwork.bootPortrait) ?? bundleWebp(wide ? Artwork.bootLandscape : Artwork.bootPortrait) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            } else {
                Meadow.limeSoft
            }
        }
    }

    private func track(width: CGFloat, hen: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(.white.opacity(0.55))
                .overlay(Capsule().stroke(Meadow.forest.opacity(0.45), lineWidth: 1.4))
                .frame(width: width, height: hen * 0.38)
            Capsule()
                .fill(LinearGradient(colors: [Meadow.lime, Meadow.moss, Meadow.forest], startPoint: .leading, endPoint: .trailing))
                .frame(width: max(8, width * progress), height: hen * 0.28)
                .padding(.horizontal, 3)
            HenImage(name: Artwork.runner, size: hen)
                .offset(x: max(0, width * progress - hen * 0.55), y: -hen * 0.28)
        }
        .frame(width: width, height: hen * 0.95, alignment: .bottom)
    }

    private func run() async {
        yard.boot()
        var from = 0.0
        for (i, stage) in stages.enumerated() {
            if i == stages.count - 1 {
                // last beat waits for the store — never show 100% while still cold
                await Task.yield()
            }
            await ramp(from: from, to: stage.0, ms: stage.1)
            from = stage.0
            try? await Task.sleep(nanoseconds: stage.2 * 1_000_000)
        }
        guard !handed else { return }
        handed = true
        ScreenGate.lockAfterBoot()
        onReady()
    }

    private func ramp(from: Double, to: Double, ms: UInt64) async {
        let frames = max(1, Int(ms / 16))
        for step in 1...frames {
            let t = Double(step) / Double(frames)
            let eased = t * t * (3 - 2 * t)
            let value = from + (to - from) * eased
            await MainActor.run {
                progress = value
                percent = Int((value * 100).rounded())
            }
            try? await Task.sleep(nanoseconds: 16_000_000)
        }
    }

    private func bundleWebp(_ name: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "webp"),
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
