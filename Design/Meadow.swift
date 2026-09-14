import SwiftUI

enum Meadow {
    static let forest = Color(red: 0.055, green: 0.267, blue: 0.161)
    static let forestDeep = Color(red: 0.008, green: 0.192, blue: 0.114)
    static let moss = Color(red: 0.184, green: 0.490, blue: 0.310)
    static let go = Color(red: 0.180, green: 0.620, blue: 0.357)
    static let lime = Color(red: 0.561, green: 0.820, blue: 0.247)
    static let limeSoft = Color(red: 0.796, green: 0.910, blue: 0.427)
    static let corn = Color(red: 1.0, green: 0.780, blue: 0.173)
    static let yolk = Color(red: 0.965, green: 0.635, blue: 0.118)
    static let comb = Color(red: 0.894, green: 0.267, blue: 0.227)
    static let blush = Color(red: 0.969, green: 0.659, blue: 0.722)
    static let sky = Color(red: 0.435, green: 0.702, blue: 0.878)
    static let lavender = Color(red: 0.608, green: 0.549, blue: 0.878)
    static let sunset = Color(red: 1.0, green: 0.541, blue: 0.357)
    static let cream = Color(red: 0.980, green: 0.965, blue: 0.914)

    static let habitPaints: [Color] = [
        lime, moss, corn, sunset, comb, blush, lavender, sky,
        Color(red: 0.09, green: 0.745, blue: 0.733),
        Color(red: 0.478, green: 0.361, blue: 0.243)
    ]

    static func habit(_ index: Int) -> Color {
        habitPaints[abs(index) % habitPaints.count]
    }
}

enum Typeface {
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .custom(name(weight), size: size, relativeTo: .largeTitle)
    }

    static func title(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .custom(name(weight), size: size, relativeTo: .title2)
    }

    static func body(_ size: CGFloat = 16, weight: Font.Weight = .regular) -> Font {
        .custom(name(weight), size: size, relativeTo: .body)
    }

    static func caption(_ size: CGFloat = 13, weight: Font.Weight = .medium) -> Font {
        .custom(name(weight), size: size, relativeTo: .caption)
    }

    private static func name(_ weight: Font.Weight) -> String {
        switch weight {
        case .light: return "SpaceGrotesk-Light"
        case .medium: return "SpaceGrotesk-Medium"
        case .semibold: return "SpaceGrotesk-SemiBold"
        case .bold, .heavy, .black: return "SpaceGrotesk-Bold"
        default: return "SpaceGrotesk-Regular"
        }
    }
}

enum Artwork {
    static let logo = "crest_mark"
    static let meadow = "meadow_wash"
    static let bootPortrait = "boot_portrait"
    static let bootLandscape = "boot_landscape"
    static let chick = "pullet"
    static let standing = "perch"
    static let runner = "stride"
    static let sprinter = "dash"
    static let legend = "veteran"
    static let happy = "cheer"
    static let coach = "tutor"
    static let curious = "inquisitive"
}

extension View {
    @ViewBuilder
    func henGlass(corner: CGFloat = 24) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
        } else {
            self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
        }
    }

    @ViewBuilder
    func henGlassProminent() -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glassProminent)
        } else {
            self.buttonStyle(.borderedProminent)
        }
    }
}
