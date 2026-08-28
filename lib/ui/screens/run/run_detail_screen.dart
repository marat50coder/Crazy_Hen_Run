import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../foundation/theme/palette.dart';
import '../../../foundation/theme/henyard_theme.dart';
import '../../../foundation/utils/day_key.dart';
import '../../../persistence/models/run_session.dart';
import '../../../domain/run_tracker.dart';
import '../../widgets/hen.dart';
import '../../widgets/run_widgets.dart';
import '../../widgets/surfaces.dart';

class RunDetailScreen extends StatelessWidget {
  const RunDetailScreen({super.key, required this.runId});

  final String runId;

  RunSession? _find(RunTracker run) {
    for (final r in run.runs) {
      if (r.id == runId) return r;
    }
    return null;
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete run?'),
        content: const Text('This run will be removed from your history.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<RunTracker>().deleteRun(runId);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = context.watch<RunTracker>();
    final run = _find(rs);
    final c = context.palette;

    if (run == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Run not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(run.type.label),
        actions: <Widget>[
          IconButton(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                run.type.color,
                Color.alphaBlend(Colors.black.withValues(alpha: 0.2), run.type.color),
              ],
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        run.distanceLabel,
                        style: context.text.displayMedium?.copyWith(color: Colors.white),
                      ),
                      Text(
                        DayKey.pretty(run.startedAt),
                        style: context.text.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                HenFigure(asset: run.type.henAsset, size: 74),
              ],
            ),
          ),
          const SizedBox(height: Insets.md),
          Row(
            children: <Widget>[
              Expanded(child: _statCard(context, run.durationLabel, 'Duration', Icons.timer_rounded, Meadow.sky)),
              const SizedBox(width: Insets.sm),
              Expanded(child: _statCard(context, run.paceLabel.replaceAll(' /km', ''), 'Pace /km', Icons.speed_rounded, run.type.color)),
            ],
          ),
          const SizedBox(height: Insets.sm),
          Row(
            children: <Widget>[
              Expanded(child: _statCard(context, '${run.calories}', 'Calories', Icons.local_fire_department_rounded, Meadow.comb)),
              const SizedBox(width: Insets.sm),
              Expanded(child: _statCard(context, '${run.steps}', 'Steps', Icons.directions_walk_rounded, Meadow.moss)),
            ],
          ),
          const SizedBox(height: Insets.md),
          const SectionHeader(title: 'Effort trace', subtitle: 'How intensity moved through the run'),
          RunTrace(samples: run.cadence, color: run.type.color, height: 140),
          const SizedBox(height: Insets.md),
          SoftCard(
            padding: const EdgeInsets.all(Insets.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _mini(context, run.avgCadenceSpm.round().toString(), 'avg spm'),
                _mini(context, run.speedKmh.toStringAsFixed(1), 'km/h'),
                _mini(context, _feelingLabel(run.feeling), 'felt'),
              ],
            ),
          ),
          if (run.note.isNotEmpty) ...<Widget>[
            const SizedBox(height: Insets.md),
            SoftCard(
              padding: const EdgeInsets.all(Insets.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Notes', style: context.text.labelSmall),
                  const SizedBox(height: 6),
                  Text(run.note, style: context.text.bodyMedium?.copyWith(color: c.textPrimary)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String value, String label, IconData icon, Color color) {
    return SoftCard(
      padding: const EdgeInsets.all(Insets.md),
      child: MetricTile(value: value, label: label, icon: icon, color: color, big: true),
    );
  }

  Widget _mini(BuildContext context, String value, String label) => Column(
        children: <Widget>[
          Text(value, style: context.text.titleLarge),
          Text(label, style: context.text.labelSmall),
        ],
      );

  static String _feelingLabel(int f) {
    const labels = <String>['Rough', 'Meh', 'Okay', 'Good', 'Great'];
    return labels[(f - 1).clamp(0, 4)];
  }
}
