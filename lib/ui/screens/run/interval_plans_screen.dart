import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../foundation/theme/palette.dart';
import '../../../foundation/theme/henyard_theme.dart';
import '../../../persistence/models/interval_plan.dart';
import '../../../domain/run_tracker.dart';
import '../../widgets/surfaces.dart';
import 'interval_builder_screen.dart';
import 'interval_session_screen.dart';

class IntervalPlansScreen extends StatelessWidget {
  const IntervalPlansScreen({super.key});

  bool _isPreset(String id) => id.startsWith('preset-');

  @override
  Widget build(BuildContext context) {
    final run = context.watch<RunTracker>();
    final plans = run.plans;

    return Scaffold(
      appBar: AppBar(title: const Text('Interval workouts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const IntervalBuilderScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New plan'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Insets.md,
          Insets.sm,
          Insets.md,
          100,
        ),
        children: <Widget>[
          Text(
            'Alternate hard efforts and easy recoveries. The hen speeds up and '
            'slows down with every segment.',
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: Insets.md),
          ...plans.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: Insets.sm),
                child: _PlanCard(plan: p, preset: _isPreset(p.id)),
              )),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.preset});

  final IntervalPlan plan;
  final bool preset;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return SoftCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => IntervalSessionScreen(plan: plan)),
      ),
      padding: const EdgeInsets.all(Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(plan.name, style: context.text.titleMedium),
              ),
              if (preset)
                const TagChip(label: 'Preset', dense: true)
              else
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => IntervalBuilderScreen(existing: plan),
                    ),
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${plan.durationLabel} · ${plan.repeats}× · ${plan.segments.length} segments',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: Insets.sm),
          _SegmentBar(plan: plan),
          const SizedBox(height: Insets.sm),
          Row(
            children: <Widget>[
              Icon(Icons.play_circle_fill_rounded, color: c.accent, size: 20),
              const SizedBox(width: 6),
              Text('Tap to start guided session', style: context.text.labelMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentBar extends StatelessWidget {
  const _SegmentBar({required this.plan});

  final IntervalPlan plan;

  @override
  Widget build(BuildContext context) {
    final segs = plan.segments;
    final total = segs.fold<int>(0, (s, e) => s + e.seconds);
    return ClipRRect(
      borderRadius: BorderRadius.circular(Corners.pill),
      child: SizedBox(
        height: 12,
        child: Row(
          children: segs.map((s) {
            final flex = total <= 0 ? 1 : ((s.seconds / total) * 1000).round().clamp(1, 1000);
            return Expanded(
              flex: flex,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                color: Color.lerp(Meadow.sky, Meadow.comb, s.intensity),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
