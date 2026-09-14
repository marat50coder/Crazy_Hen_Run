import SwiftUI
import UIKit

struct HenImage: View {
    var name: String
    var size: CGFloat = 120

    var body: some View {
        Group {
            if let ui = UIImage(named: name) ?? bundled(name) {
                Image(uiImage: ui)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                Image(systemName: "bird.fill")
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(Meadow.moss)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func bundled(_ name: String) -> UIImage? {
        let url = Bundle.main.url(forResource: name, withExtension: "webp")
            ?? Bundle.main.url(forResource: name, withExtension: "png")
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}

struct GlassPanel<Content: View>: View {
    var radius: CGFloat = 24
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .henGlass(corner: radius)
    }
}

struct ProgressRing: View {
    var value: Double
    var size: CGFloat = 92
    var line: CGFloat = 9
    var color: Color = Meadow.moss

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.15), lineWidth: line)
            Circle()
                .trim(from: 0, to: min(1, max(0, value)))
                .stroke(color, style: StrokeStyle(lineWidth: line, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.55), value: value)
        }
        .frame(width: size, height: size)
    }
}

struct WeekStrip: View {
    var days: [Date]
    var selected: Date
    var summaries: [Date: DaySummary]
    var onPick: (Date) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(days, id: \.self) { day in
                let on = Calendar.current.isDate(day, inSameDayAs: selected)
                let sum = summaries[DayKey.start(day)]
                Button {
                    onPick(day)
                } label: {
                    VStack(spacing: 6) {
                        Text(day.formatted(.dateTime.weekday(.narrow)))
                            .font(Typeface.caption(11, weight: .semibold))
                        Text(day.formatted(.dateTime.day()))
                            .font(Typeface.title(16, weight: .bold))
                        Capsule()
                            .fill(sum?.perfect == true ? Meadow.lime : (sum?.completed ?? 0) > 0 ? Meadow.moss.opacity(0.45) : Color.clear)
                            .frame(width: 14, height: 4)
                    }
                    .foregroundStyle(on ? Color.white : Color.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(on ? Meadow.moss : Color.clear, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(day.formatted(date: .complete, time: .omitted))
            }
        }
    }
}

struct EmptyHen: View {
    var title: String
    var message: String
    var art: String = Artwork.curious

    var body: some View {
        VStack(spacing: 14) {
            HenImage(name: art, size: 140)
            Text(title).font(Typeface.title(22))
            Text(message)
                .font(Typeface.body(15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}

struct FaceMark: View {
    var profile: Profile
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            Circle().fill(Meadow.moss.opacity(0.18))
            if let path = profile.avatarPath.nilIfEmpty,
               let img = UIImage(contentsOfFile: path) {
                Image(uiImage: img).resizable().scaledToFill()
            } else {
                Text(profile.initials)
                    .font(Typeface.title(size * 0.34, weight: .bold))
                    .foregroundStyle(Meadow.forest)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(.white.opacity(0.55), lineWidth: 2))
    }
}

struct UnlockToast: View {
    var item: Achievement

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.symbol)
                .font(.title2)
                .foregroundStyle(item.paint)
            VStack(alignment: .leading, spacing: 2) {
                Text("Unlocked").font(Typeface.caption(11, weight: .semibold)).foregroundStyle(.secondary)
                Text(item.title).font(Typeface.title(17))
            }
            Spacer()
            HenImage(name: Artwork.happy, size: 46)
        }
        .padding(16)
        .henGlass(corner: 22)
        .padding(.horizontal, 20)
    }
}

extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
