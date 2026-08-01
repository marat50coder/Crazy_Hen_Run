import 'dart:math' as math;

import '../../state/app_state.dart';

class CoachLine {
  const CoachLine(this.headline, this.body);

  final String headline;
  final String body;
}

/// Picks what the hen says on the home screen based on real progress, with a
/// deterministic daily rotation so the copy feels alive but never flickers.
class Coach {
  const Coach._();

  static CoachLine forToday(AppState state) {
    final today = DateTime.now();
    final summary = state.summaryFor(today);
    final streak = state.currentBestStreak;
    final seed = today.day + today.month * 31;

    if (state.habits.isEmpty) {
      return const CoachLine(
        'Empty track ahead',
        'Add your first habit and I will start running next to you.',
      );
    }

    if (summary.scheduled == 0) {
      return const CoachLine(
        'Rest day',
        'Nothing scheduled today. Even fast hens need a day off the track.',
      );
    }

    if (summary.isPerfect) {
      return CoachLine(
        _pick(_perfect, seed),
        'All ${summary.scheduled} habits closed. That is a clean lap.',
      );
    }

    if (summary.completed == 0) {
      return CoachLine(
        _pick(_cold, seed),
        streak > 1
            ? 'Your $streak day streak is watching. One habit keeps it alive.'
            : 'Start with the easiest one. Momentum does the rest.',
      );
    }

    final left = summary.scheduled - summary.completed;
    return CoachLine(
      _pick(_midway, seed),
      left == 1
          ? 'One habit left. Finish it before the day finishes you.'
          : '$left habits left on the track today.',
    );
  }

  static String tipOfDay(int seed) => _pick(_tips, seed);

  static String _pick(List<String> pool, int seed) =>
      pool[math.max(0, seed) % pool.length];

  static const List<String> _perfect = <String>[
    'Clean sweep!',
    'Full lap done',
    'Nothing left to chase',
    'Track conquered',
  ];

  static const List<String> _cold = <String>[
    'Track is empty',
    'Still at the start line',
    'Legs are cold',
    'Nothing moved yet',
  ];

  static const List<String> _midway = <String>[
    'Keep the pace',
    'Halfway is not the finish',
    'Good rhythm',
    'Still running',
  ];

  static const List<String> _tips = <String>[
    'Shrink the habit until it feels almost too easy, then never skip it.',
    'Stack a new habit right after something you already do daily.',
    'Missing once is an accident. Missing twice is the start of a new habit.',
    'Track the streak, not the mood. Motivation shows up after the work.',
    'Put the trigger where you will trip over it: shoes by the door.',
    'A two minute version still counts. Showing up is the whole game.',
    'Review your week on Sunday. Cut what you never do.',
    'Pair the boring habit with something you actually enjoy.',
    'Your future self only remembers the days you decided anyway.',
    'Design the environment so the good choice is the lazy choice.',
  ];
}
