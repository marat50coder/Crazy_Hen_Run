import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/day_key.dart';
import '../../../data/models/run_session.dart';
import '../../../state/run_state.dart';
import '../../widgets/hen.dart';
import '../../widgets/run_widgets.dart';
import '../../widgets/surfaces.dart';
import 'run_detail_screen.dart';

class RunHistoryScreen extends StatelessWidget {
  const RunHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final run = context.watch<RunState>();
    final runs = run.runs;

    return Scaffold(
      appBar: AppBar(title: const Text('Run history')),
      body: runs.isEmpty
          ? HenEmptyState(
              title: 'No runs yet',
              message: 'Every run you finish lands here with its own effort trace.',
              asset: 'assets/questions_chicken.webp',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              children: <Widget>[
                SoftCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: MetricTile(
                          value: run.distanceLabelOf(run.lifetimeRunMeters),
                          label: 'Total distance',
                          icon: Icons.route_rounded,
                          color: Brand.moss,
                        ),
                      ),
                      Expanded(
                        child: MetricTile(
                          value: '${run.totalRuns}',
                          label: 'Runs',
                          icon: Icons.directions_run_rounded,
                          color: Brand.sky,
                        ),
                      ),
                      Expanded(
                        child: MetricTile(
                          value: '${(run.totalRunSeconds / 3600).toStringAsFixed(1)}h',
                          label: 'Time',
                          icon: Icons.timer_rounded,
                          color: Brand.corn,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
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
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
      padding: const EdgeInsets.all(AppSpacing.md),
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
                  borderRadius: BorderRadius.circular(AppRadii.sm),
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
          const SizedBox(height: AppSpacing.sm),
          RunTrace(samples: run.cadence, color: run.type.color, height: 64),
          const SizedBox(height: AppSpacing.sm),
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
