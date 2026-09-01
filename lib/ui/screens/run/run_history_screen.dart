import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';

import '../../../foundation/constants/artwork.dart';
import '../../../foundation/theme/palette.dart';
import '../../../foundation/theme/henyard_theme.dart';
import '../../../foundation/utils/day_key.dart';
import '../../../persistence/models/run_session.dart';
import '../../../domain/run_tracker.dart';
import '../../widgets/hen.dart';
import '../../widgets/run_widgets.dart';
import '../../widgets/surfaces.dart';
import 'run_detail_screen.dart';

class RunHistoryScreen extends StatelessWidget {
  const RunHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final run = context.watch<RunTracker>();
    final runs = run.runs;

    return Scaffold(
      appBar: AppBar(title: const Text('Run history')),
      body: runs.isEmpty
          ? HenEmptyState(
              title: 'No runs yet',
              message: 'Every run you finish lands here with its own effort trace.',
              asset: Artwork.henCurious,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                Insets.md,
                Insets.sm,
                Insets.md,
                Insets.xxl,
              ),
              children: <Widget>[
                SoftCard(
                  padding: const EdgeInsets.all(Insets.md),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: MetricTile(
                          value: run.distanceLabelOf(run.lifetimeRunMeters),
                          label: 'Total distance',
                          icon: Icons.route_rounded,
                          color: Meadow.moss,
                        ),
                      ),
                      Expanded(
                        child: MetricTile(
                          value: '${run.totalRuns}',
                          label: 'Runs',
                          icon: Icons.directions_run_rounded,
                          color: Meadow.sky,
                        ),
                      ),
                      Expanded(
                        child: MetricTile(
                          value: '${(run.totalRunSeconds / 3600).toStringAsFixed(1)}h',
                          label: 'Time',
                          icon: Icons.timer_rounded,
                          color: Meadow.corn,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Insets.md),
                AnimationLimiter(
                  child: Column(
                    children: List<Widget>.generate(runs.length, (i) {
                      return AnimationConfiguration.staggeredList(
                        position: i,
                        duration: const Duration(milliseconds: 340),
                        child: SlideAnimation(
                          verticalOffset: 24,
                          child: FadeInAnimation(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: Insets.sm),
                              child: _HistoryCard(run: runs[i]),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.run});

  final RunSession run;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => RunDetailScreen(runId: run.id)),
      ),
      padding: const EdgeInsets.all(Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: run.type.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(Corners.sm),
                ),
                child: Icon(run.type.icon, color: run.type.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(run.type.label, style: context.text.titleSmall),
                    Text(DayKey.medium(run.startedAt), style: context.text.labelSmall),
                  ],
                ),
              ),
              TagChip(label: run.distanceLabel, color: run.type.color, dense: true),
            ],
          ),
          const SizedBox(height: Insets.sm),
          RunTrace(samples: run.cadence, color: run.type.color, height: 64),
          const SizedBox(height: Insets.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _stat(context, run.durationLabel, 'time'),
              _stat(context, run.paceLabel.replaceAll(' /km', ''), 'pace'),
              _stat(context, '${run.steps}', 'steps'),
              _stat(context, '${run.calories}', 'kcal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) => Column(
        children: <Widget>[
          Text(value, style: context.text.titleSmall),
          Text(label, style: context.text.labelSmall),
        ],
      );
}
