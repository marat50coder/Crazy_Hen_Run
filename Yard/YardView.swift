import SwiftUI
import UIKit

struct YardView: View {
    @Environment(Yard.self) private var yard

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ZStack(alignment: .bottom) {
                        meadow
                        HenImage(name: yard.rank.art, size: 180)
                            .padding(.bottom, 8)
                    }
                    .frame(height: 260)

                    VStack(alignment: .leading, spacing: 16) {
                        Text(yard.rank.title).font(Typeface.display(32))
                        Text(yard.rank.blurb).foregroundStyle(.secondary)
                        Text(yard.distanceLabel).font(Typeface.title(20))
                        ProgressView(value: yard.rankProgress).tint(Meadow.moss)
                        if let next = yard.rank.next {
                            Text("\(max(0, next.needed - yard.lifetimeMetres)) m to \(next.title)")
                                .font(Typeface.caption(13)).foregroundStyle(.secondary)
                        }

                        NavigationLink {
                            AchievementBoard()
                        } label: {
                            HStack {
                                Text("Achievements")
                                Spacer()
                                Text("\(yard.unlocked.count)/\(Catalog.achievements.count)")
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }
                            .padding()
                            .henGlass(corner: 20)
                        }
                        .buttonStyle(.plain)

                        Text("The ladder").font(Typeface.title(18))
                        ForEach(HenRank.allCases, id: \.self) { rank in
                            HStack {
                                HenImage(name: rank.art, size: 54)
                                VStack(alignment: .leading) {
                                    Text(rank.title).font(Typeface.title(16))
                                    Text(rank.needed == 0 ? "Start" : rank.needed.asDistanceNeeded)
                                        .font(Typeface.caption(12)).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if yard.rank.rawValue >= rank.rawValue {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Meadow.moss)
                                }
                            }
                            .padding(10)
                            .henGlass(corner: 18)
                            .opacity(yard.rank.rawValue >= rank.rawValue ? 1 : 0.55)
                        }
                    }
                    .padding(16)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("The Yard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var meadow: some View {
        Group {
            if let img = UIImage(named: Artwork.meadow) ?? bundle(Artwork.meadow) {
                Image(uiImage: img).resizable().scaledToFill()
            } else {
                LinearGradient(colors: [Meadow.limeSoft, Meadow.moss], startPoint: .top, endPoint: .bottom)
            }
        }
        .overlay(LinearGradient(colors: [.clear, Color(.systemGroupedBackground)], startPoint: .center, endPoint: .bottom))
    }

    private func bundle(_ name: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "webp"),
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}

private extension Int {
    var asDistanceNeeded: String { Double(self).asDistance }
}

struct AchievementBoard: View {
    @Environment(Yard.self) private var yard

    var body: some View {
        let values = yard.achievementValues()
        List {
            ForEach(Achievement.Group.allCases, id: \.self) { group in
                Section(group.label) {
                    ForEach(Catalog.achievements.filter { $0.group == group }) { item in
                        let current = values[item.id] ?? 0
                        HStack {
                            Image(systemName: item.symbol).foregroundStyle(item.paint).frame(width: 28)
                            VStack(alignment: .leading) {
                                Text(item.title).font(Typeface.title(16))
                                Text(item.description).font(Typeface.caption(12)).foregroundStyle(.secondary)
                                ProgressView(value: min(1, Double(current) / Double(max(item.threshold, 1)))).tint(item.paint)
                            }
                            if current >= item.threshold {
                                Image(systemName: "seal.fill").foregroundStyle(Meadow.corn)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Achievements")
    }
}
