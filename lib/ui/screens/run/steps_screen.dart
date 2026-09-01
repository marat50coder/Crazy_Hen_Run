import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../foundation/constants/artwork.dart';
import '../../../foundation/theme/palette.dart';
import '../../../foundation/theme/henyard_theme.dart';
import '../../../foundation/utils/day_key.dart';
import '../../../domain/run_tracker.dart';
import '../../widgets/hen.dart';
import '../../widgets/progress.dart';
import '../../widgets/surfaces.dart';

class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  int _range = 7;

  @override
  Widget build(BuildContext context) {
    final run = context.watch<RunTracker>();
    final series = run.stepSeries(_range);
    final maxSteps = series.fold<int>(1, (m, e) => math.max(m, e.steps));
    final total = series.fold<int>(0, (s, e) => s + e.steps);
    final avg = series.isEmpty ? 0 : total ~/ series.length;
    final best = series.fold<int>(0, (m, e) => math.max(m, e.steps));

    return Scaffold(
      appBar: AppBar(title: const Text('Steps')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Insets.md,
          0,
          Insets.md,
          Insets.xxl,
        ),
        children: <Widget>[
          SoftCard(
            padding: const EdgeInsets.all(Insets.lg),
            child: Row(
              children: <Widget>[
                ProgressRing(
                  value: run.stepGoalProgress,
                  size: 118,
                  stroke: 11,
                  color: Meadow.lime,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AnimatedNumber(value: run.todaySteps, style: context.text.headlineSmall),
                      Text('of ${run.stepGoal}', style: context.text.labelSmall),
                    ],
                  ),
                ),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const HenFigure(asset: Artwork.henHappy, size: 52),
                      const SizedBox(height: 6),
                      Text(
                        run.distanceLabelOf(run.todayDistanceMeters),
                        style: context.text.headlineSmall,
                      ),
                      Text('${run.todayCalories} kcal today', style: context.text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.md),
          Row(
            children: <Widget>[
              const Text(''),
              Expanded(
                child: SectionHeader(
                  title: 'Activity',
                  subtitle: 'Last $_range days',
                  padding: EdgeInsets.zero,
                ),
              ),
              _rangeToggle(),
            ],
          ),
          const SizedBox(height: Insets.sm),
          SoftCard(
            padding: const EdgeInsets.fromLTRB(Insets.md, Insets.lg, Insets.md, Insets.md),
            child: _BarChart(
              series: series,
              maxSteps: maxSteps,
              goal: run.stepGoal,
              showLabels: _range <= 14,
            ),
          ),
          const SizedBox(height: Insets.md),
          Row(
            children: <Widget>[
              Expanded(child: _summaryCard(context, '$avg', 'Daily average', Meadow.moss)),
              const SizedBox(width: Insets.sm),
              Expanded(child: _summaryCard(context, '$best', 'Best day', Meadow.corn)),
              const SizedBox(width: Insets.sm),
              Expanded(child: _summaryCard(context, '$total', 'Total', Meadow.sky)),
            ],
          ),
          const SizedBox(height: Insets.md),
          _goalCard(run),
          const SizedBox(height: Insets.md),
          _strideCard(run),
        ],
      ),
    );
  }

  Widget _rangeToggle() {
    final c = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(Corners.pill),
      ),
      child: Row(
        children: <int>[7, 14, 30].map((r) {
          final selected = _range == r;
          return GestureDetector(
            onTap: () => setState(() => _range = r),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? c.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(Corners.pill),
              ),
              child: Text(
                '$r',
                style: context.text.labelSmall?.copyWith(
                  color: selected ? Colors.white : c.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _summaryCard(BuildContext context, String value, String label, Color color) {
    return SoftCard(
      padding: const EdgeInsets.all(Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(value, style: context.text.titleLarge?.copyWith(color: color)),
          Text(label, style: context.text.labelSmall),
        ],
      ),
    );
  }

  Widget _goalCard(RunTracker run) {
    return SoftCard(
      padding: const EdgeInsets.all(Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.flag_rounded, size: 18),
              const SizedBox(width: 8),
              Text('Daily step goal', style: context.text.titleSmall),
              const Spacer(),
              Text('${run.stepGoal}', style: context.text.titleMedium),
            ],
          ),
          Slider(
            value: run.stepGoal.toDouble(),
            min: 2000,
            max: 25000,
            divisions: 46,
            label: '${run.stepGoal}',
            onChanged: (v) => run.setStepGoal((v ~/ 500) * 500),
          ),
        ],
      ),
    );
  }

  Widget _strideCard(RunTracker run) {
    return SoftCard(
      padding: const EdgeInsets.all(Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.straighten_rounded, size: 18),
              const SizedBox(width: 8),
              Text('Stride length', style: context.text.titleSmall),
              const Spacer(),
              Text('${run.strideCm} cm', style: context.text.titleMedium),
            ],
          ),
          Slider(
            value: run.strideCm.toDouble(),
            min: 40,
            max: 120,
            divisions: 80,
            label: '${run.strideCm} cm',
            onChanged: (v) => run.setStrideCm(v.round()),
          ),
          Text(
            'Used to turn your steps into distance. Taller runners take longer strides.',
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.series,
    required this.maxSteps,
    required this.goal,
    required this.showLabels,
  });

  final List<({DateTime day, int steps})> series;
  final int maxSteps;
  final int goal;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final scaleMax = math.max(maxSteps, goal).toDouble();
    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: series.map((e) {
          final ratio = scaleMax <= 0 ? 0.0 : e.steps / scaleMax;
          final hit = e.steps >= goal;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) => Align(
                        alignment: Alignment.bottomCenter,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: ratio.clamp(0.0, 1.0)),
                          duration: const Duration(milliseconds: 550),
                          curve: Curves.easeOutCubic,
                          builder: (context, a, _) => Container(
                            height: math.max(3, box.maxHeight * a),
                            decoration: BoxDecoration(
                              color: hit ? Meadow.lime : c.accent.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (showLabels) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      DayKey.weekdayLetter(e.day.weekday),
                      style: context.text.labelSmall,
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
