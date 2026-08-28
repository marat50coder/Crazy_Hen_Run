import '../../foundation/constants/artwork.dart';

enum HenRank {
  chick(
    'Chick',
    'Fresh out of the shell. Every long run starts with one tiny step.',
    0,
    Artwork.henChick,
  ),
  hen(
    'Hen',
    'Standing tall and showing up. The routine is starting to stick.',
    5000,
    Artwork.henStanding,
  ),
  runner(
    'Runner',
    'Headband on, pace found. Habits are no longer a fight.',
    25000,
    Artwork.henRunner,
  ),
  sprinter(
    'Sprinter',
    'Full tracksuit, flames included. You are outrunning your excuses.',
    75000,
    Artwork.henSprinter,
  ),
  legend(
    'Legend',
    'Cape, medal, glory. The coop tells stories about you.',
    200000,
    Artwork.henLegend,
  );

  const HenRank(this.title, this.blurb, this.requiredMetres, this.asset);

  final String title;
  final String blurb;
  final int requiredMetres;
  final String asset;

  static HenRank forDistance(int metres) {
    HenRank current = HenRank.chick;
    for (final rank in HenRank.values) {
      if (metres >= rank.requiredMetres) current = rank;
    }
    return current;
  }

  HenRank? get next {
    final i = index + 1;
    return i < HenRank.values.length ? HenRank.values[i] : null;
  }

  /// 0…1 progress towards [next]; returns 1 for the final rank.
  double progressFrom(int metres) {
    final upcoming = next;
    if (upcoming == null) return 1;
    final span = upcoming.requiredMetres - requiredMetres;
    if (span <= 0) return 1;
    return ((metres - requiredMetres) / span).clamp(0.0, 1.0);
  }
}
