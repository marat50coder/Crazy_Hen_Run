import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../foundation/constants/artwork.dart';
import '../../../foundation/theme/palette.dart';
import '../../../foundation/theme/henyard_theme.dart';
import '../../../foundation/utils/day_key.dart';
import '../../../domain/hen_state.dart';
import '../../widgets/hen.dart';
import '../../widgets/progress.dart';
import '../../widgets/surfaces.dart';

/// One goal, one gauge. The weekly sprint screen is intentionally the most
/// minimal in the app: a single number to beat.
class SprintScreen extends StatelessWidget {
  const SprintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<HenState>();
    final c = context.palette;

    final week = DayKey.weekOf(DateTime.now(), firstWeekday: app.firstWeekday);
    final summaries = app.summariesFor(week);
    final done = app.weeklyCompletions;
    final target = app.weeklySprintTarget;
    final remaining = (target - done).clamp(0, target);
    final daysLeft = week
        .where((d) => !d.isBefore(DayKey.today()))
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly sprint')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Insets.lg,
          0,
          Insets.lg,
          Insets.xxl,
        ),
        children: <Widget>[
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                ProgressRing(
                  value: app.weeklySprintProgress,
                  size: 236,
                  stroke: 18,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AnimatedNumber(
                        value: done,
                        style: context.text.displayLarge,
                      ),
                      Text('of $target habits', style: context.text.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),
          Center(
            child: Text(
              remaining == 0
                  ? 'Sprint complete'
                  : '$remaining to go · $daysLeft ${daysLeft == 1 ? 'day' : 'days'} left',
              style: context.text.titleMedium,
            ),
          ),
          const SizedBox(height: Insets.xl),
          SoftCard(
            color: remaining == 0 ? c.accentSoft : null,
            child: Row(
              children: <Widget>[
                HenFigure(
                  asset: remaining == 0
                      ? Artwork.henHappy
                      : Artwork.henSprinter,
                  size: 72,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    remaining == 0
                        ? 'Target hit with $daysLeft ${daysLeft == 1 ? 'day' : 'days'} to spare. Anything else this week is a bonus.'
                        : 'Closing about ${(remaining / (daysLeft == 0 ? 1 : daysLeft)).ceil()} habits per day gets you there.',
                    style: context.text.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),
          SectionHeader(title: 'This week'),
          SoftCard(
            child: Row(
              children: List<Widget>.generate(week.length, (i) {
                final day = week[i];
                final s = summaries[i];
                final future = day.isAfter(DayKey.today());
                return Expanded(
                  child: Column(
                    children: <Widget>[
                      Text(
                        DayKey.weekdayLetter(day.weekday),
                        style: context.text.labelSmall,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 62,
                        width: 12,
                        decoration: BoxDecoration(
                          color: c.surfaceMuted,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: future ? 0.0 : s.ratio.clamp(0.02, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: s.isPerfect ? c.positive : c.accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        future ? '–' : '${s.completed}',
                        style: context.text.labelSmall?.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: Insets.lg),
          SectionHeader(
            title: 'Sprint target',
            subtitle: 'How many habits you want to close every week',
          ),
          SoftCard(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Slider(
                        value: target.toDouble().clamp(3, 70),
                        min: 3,
                        max: 70,
                        divisions: 67,
                        label: '$target',
                        onChanged: (v) =>
                            app.setWeeklySprintTarget(v.round()),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '$target',
                        textAlign: TextAlign.right,
                        style: context.text.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'A realistic target is roughly your number of daily habits times seven.',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
