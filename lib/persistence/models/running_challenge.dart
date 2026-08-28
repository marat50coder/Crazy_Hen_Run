import 'package:flutter/material.dart';

enum ChallengeMetric { weeklyDistance, weeklyRuns, totalDistance, longestRun, dayStreak, totalSteps }

/// A goal the runner chases. Progress is computed from live metrics rather than
/// stored, so a challenge can never drift out of sync with reality.
class RunningChallenge {
  const RunningChallenge({
    required this.id,
    required this.title,
    required this.blurb,
    required this.metric,
    required this.target,
    required this.icon,
    required this.colorValue,
    required this.unit,
  });

  final String id;
  final String title;
  final String blurb;
  final ChallengeMetric metric;
  final double target;
  final IconData icon;
  final int colorValue;
  final String unit;

  Color get color => Color(colorValue);

  double progressFrom(double current) =>
      target <= 0 ? 0 : (current / target).clamp(0.0, 1.0);

  bool isDoneFrom(double current) => current >= target;

  static const List<RunningChallenge> catalog = <RunningChallenge>[
    RunningChallenge(
      id: 'c_week_5k',
      title: 'Weekly 5K',
      blurb: 'Cover 5 kilometres before the week resets.',
      metric: ChallengeMetric.weeklyDistance,
      target: 5000,
      icon: Icons.flag_rounded,
      colorValue: 0xFF2E9E5B,
      unit: 'm',
    ),
    RunningChallenge(
      id: 'c_week_15k',
      title: 'Weekly 15K',
      blurb: 'A serious week on the roads — 15 km total.',
      metric: ChallengeMetric.weeklyDistance,
      target: 15000,
      icon: Icons.emoji_events_rounded,
      colorValue: 0xFFF2A93B,
      unit: 'm',
    ),
    RunningChallenge(
      id: 'c_week_3runs',
      title: 'Three a week',
      blurb: 'Lace up three separate times this week.',
      metric: ChallengeMetric.weeklyRuns,
      target: 3,
      icon: Icons.replay_rounded,
      colorValue: 0xFF3E7BC2,
      unit: 'runs',
    ),
    RunningChallenge(
      id: 'c_long_3k',
      title: 'Go the distance',
      blurb: 'Finish a single run of 3 km or more.',
      metric: ChallengeMetric.longestRun,
      target: 3000,
      icon: Icons.route_rounded,
      colorValue: 0xFF8A6FE0,
      unit: 'm',
    ),
    RunningChallenge(
      id: 'c_steps_10k',
      title: '10k steps',
      blurb: 'Hit ten thousand steps in one day.',
      metric: ChallengeMetric.totalSteps,
      target: 10000,
      icon: Icons.directions_walk_rounded,
      colorValue: 0xFFE0483D,
      unit: 'steps',
    ),
    RunningChallenge(
      id: 'c_streak_5',
      title: 'Five day fire',
      blurb: 'Move every day for five days straight.',
      metric: ChallengeMetric.dayStreak,
      target: 5,
      icon: Icons.local_fire_department_rounded,
      colorValue: 0xFFF2683C,
      unit: 'days',
    ),
    RunningChallenge(
      id: 'c_total_42k',
      title: 'Marathon miles',
      blurb: 'Accumulate a full marathon across all your runs.',
      metric: ChallengeMetric.totalDistance,
      target: 42195,
      icon: Icons.military_tech_rounded,
      colorValue: 0xFF2E9E5B,
      unit: 'm',
    ),
  ];
}
