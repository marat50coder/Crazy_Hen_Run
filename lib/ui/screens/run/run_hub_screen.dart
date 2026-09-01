import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../foundation/constants/artwork.dart';
import '../../../foundation/theme/palette.dart';
import '../../../foundation/theme/henyard_theme.dart';
import '../../../foundation/utils/day_key.dart';
import '../../../persistence/models/run_goal.dart';
import '../../../persistence/models/run_session.dart';
import '../../../persistence/models/run_type.dart';
import '../../../domain/run_tracker.dart';
import '../../widgets/avatar.dart';
import '../../widgets/hen.dart';
import '../../widgets/progress.dart';
import '../../widgets/run_widgets.dart';
import '../../widgets/surfaces.dart';
import '../../../domain/hen_state.dart';
import '../settings/settings_screen.dart';
import 'challenges_screen.dart';
import 'interval_plans_screen.dart';
import '../../widgets/go_button.dart';
import 'run_detail_screen.dart';
import 'run_go_gate.dart';
import 'run_history_screen.dart';
import 'run_types_screen.dart';
import 'steps_screen.dart';

class RunHubScreen extends StatefulWidget {
  const RunHubScreen({super.key});

  @override
  State<RunHubScreen> createState() => _RunHubScreenState();
}

class _RunHubScreenState extends State<RunHubScreen> {
  RunType _type = RunType.free;
  RunGoal _goal = RunGoal.open;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final run = context.read<RunTracker>();
      if (!run.sensorGranted) run.requestSensor();
    });
  }

  void _startRun() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RunGoGate(type: _type, goal: _goal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final run = context.watch<RunTracker>();
    final c = context.palette;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Insets.md,
          0,
          Insets.md,
          Insets.xxl,
        ),
        children: <Widget>[
          _header(run),
          const SizedBox(height: Insets.md),
          _startCard(run),
          const SizedBox(height: Insets.md),
          _typePicker(),
          const SizedBox(height: Insets.md),
          _stepsCard(run),
          const SizedBox(height: Insets.md),
          _quickGrid(),
          const SizedBox(height: Insets.md),
          _weeklyPlanCard(run),
          const SizedBox(height: Insets.md),
          _weekCard(run),
          const SizedBox(height: Insets.md),
          SectionHeader(
            title: 'Recent runs',
            subtitle: run.runs.isEmpty ? 'No runs yet' : '${run.totalRuns} total',
            trailing: run.runs.isEmpty
                ? null
                : TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const RunHistoryScreen()),
                    ),
                    child: const Text('See all'),
                  ),
          ),
          if (run.runs.isEmpty)
            _emptyRuns(c)
          else
            ...run.runs.take(3).map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: Insets.sm),
                  child: _RunRow(run: r),
                )),
        ],
      ),
    );
  }

  Widget _header(RunTracker run) {
    final app = context.watch<HenState>();
    final c = context.palette;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: Insets.sm),
        child: Row(
          children: <Widget>[
            ProfileAvatar(profile: app.profile, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Ready to run', style: context.text.bodySmall),
                  Text(run.rank.title, style: context.text.titleLarge),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              ),
              icon: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: c.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.outline),
                ),
                child: Icon(Icons.tune_rounded, size: 20, color: c.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _startCard(RunTracker run) {
    final c = context.palette;
    final last = run.lastOf(_type);
    final best = run.bestOf(_type);
    return SoftCard(
      padding: const EdgeInsets.all(Insets.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Meadow.go.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(_type.icon, color: Meadow.go, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(_type.label, style: context.text.titleMedium),
                    Text(_type.tag, style: context.text.labelSmall),
                  ],
                ),
              ),
              HenFigure(asset: _type.henAsset, size: 56),
            ],
          ),
          const SizedBox(height: 8),
          Text(_type.blurb, style: context.text.bodyMedium),
          if (last != null) ...<Widget>[
            const SizedBox(height: Insets.sm),
            Text(
              'Last: ${last.distanceLabel} · ${last.durationLabel}'
              '${best != null ? '  ·  Best ${best.distanceLabel}' : ''}',
              style: context.text.bodySmall?.copyWith(color: c.textSecondary),
            ),
          ],
          const SizedBox(height: Insets.md),
          _goalStrip(),
          const SizedBox(height: Insets.md),
          GoButton(
            label: _goal.isOpen
                ? 'Start ${_type.label}'
                : 'Start · ${_goal.chipLabel}',
            onPressed: _startRun,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 320.ms).moveY(begin: 12, end: 0);
  }

  Widget _goalStrip() {
    final c = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Goal for this run', style: context.text.labelSmall),
        const SizedBox(height: 6),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: RunGoal.presets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final g = RunGoal.presets[i];
              final selected = g.kind == _goal.kind && g.value == _goal.value;
              return _GoalChip(
                label: g.chipLabel,
                selected: selected,
                accent: Meadow.go,
                background: c.surface,
                border: c.outline,
                onTap: () => setState(() => _goal = g),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _typePicker() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: RunType.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final t = RunType.values[i];
          return RunTypeChip(
            type: t,
            selected: t == _type,
            onTap: () => setState(() => _type = t),
          );
        },
      ),
    );
  }

  Widget _stepsCard(RunTracker run) {
    final c = context.palette;
    return SoftCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const StepsScreen()),
      ),
      padding: const EdgeInsets.all(Insets.md),
      child: Row(
        children: <Widget>[
          ProgressRing(
            value: run.stepGoalProgress,
            size: 92,
            stroke: 9,
            color: Meadow.lime,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AnimatedNumber(
                  value: run.todaySteps,
                  style: context.text.titleLarge,
                ),
                Text('steps', style: context.text.labelSmall),
              ],
            ),
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text("Today's move", style: context.text.labelSmall),
                const SizedBox(height: 4),
                Text(
                  run.distanceLabelOf(run.todayDistanceMeters),
                  style: context.text.headlineSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'Goal ${run.stepGoal} · ${run.todayCalories} kcal',
                  style: context.text.bodySmall,
                ),
                if (!run.sensorAvailable) ...<Widget>[
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Icon(Icons.sensors_off_rounded, size: 14, color: c.textSecondary),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          run.sensorGranted
                              ? 'Waiting for step sensor…'
                              : 'Tap to enable step counting',
                          style: context.text.labelSmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickGrid() {
    return Row(
      children: <Widget>[
        Expanded(
          child: _QuickTile(
            icon: Icons.speed_rounded,
            label: 'Intervals',
            color: RunType.interval.color,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const IntervalPlansScreen()),
            ),
          ),
        ),
        const SizedBox(width: Insets.sm),
        Expanded(
          child: _QuickTile(
            icon: Icons.emoji_events_rounded,
            label: 'Challenges',
            color: Meadow.corn,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ChallengesScreen()),
            ),
          ),
        ),
        const SizedBox(width: Insets.sm),
        Expanded(
          child: _QuickTile(
            icon: Icons.directions_run_rounded,
            label: 'Run types',
            color: Meadow.sky,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const RunTypesScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _weeklyPlanCard(RunTracker run) {
    final c = context.palette;
    final today = DayKey.today();
    final firstWeekday = context.read<HenState>().mondayFirst
        ? DateTime.monday
        : DateTime.sunday;
    final week = DayKey.weekOf(today, firstWeekday: firstWeekday);
    final target = run.weeklyRunTarget;
    final done = run.weekRuns;
    final progress = run.weeklyRunProgress;
    final complete = done >= target;
    return SoftCard(
      padding: const EdgeInsets.all(Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Weekly plan', style: context.text.labelSmall),
                    Text(
                      complete
                          ? 'Weekly goal cleared'
                          : '$done of $target runs this week',
                      style: context.text.titleMedium,
                    ),
                  ],
                ),
              ),
              _TargetChip(
                value: target,
                onChanged: (v) => run.setWeeklyRunTarget(v),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(Corners.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: c.outline.withValues(alpha: 0.4),
              valueColor: AlwaysStoppedAnimation<Color>(
                complete ? Meadow.go : c.accent,
              ),
            ),
          ),
          const SizedBox(height: Insets.md),
          Row(
            children: <Widget>[
              for (final d in week)
                Expanded(
                  child: _WeekPlanCell(
                    day: d,
                    isToday: DayKey.isSameDay(d, today),
                    hasRun: run.ranOnDay(d),
                    accent: Meadow.go,
                    dim: c.textSecondary,
                    surface: c.surface,
                    border: c.outline,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weekCard(RunTracker run) {
    return SoftCard(
      padding: const EdgeInsets.all(Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('This week', style: context.text.labelSmall),
          const SizedBox(height: Insets.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: MetricTile(
                  value: run.distanceLabelOf(run.weekDistanceMeters),
                  label: 'Distance',
                  icon: Icons.route_rounded,
                  color: Meadow.moss,
                ),
              ),
              Expanded(
                child: MetricTile(
                  value: '${run.weekRuns}',
                  label: 'Runs',
                  icon: Icons.directions_run_rounded,
                  color: Meadow.sky,
                ),
              ),
              Expanded(
                child: MetricTile(
                  value: '${run.dayStreak}',
                  label: 'Day streak',
                  icon: Icons.local_fire_department_rounded,
                  color: Meadow.comb,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          HenRunStrip(
            progress: run.rankProgress,
            henAsset: run.rank.asset,
            color: context.palette.accent,
            caption: run.rank.next == null
                ? 'Top rank'
                : 'Next: ${run.rank.next!.title}',
          ),
        ],
      ),
    );
  }

  Widget _emptyRuns(Palette c) {
    return SoftCard(
      padding: const EdgeInsets.all(Insets.lg),
      child: Row(
        children: <Widget>[
          const HenFigure(asset: Artwork.henCurious, size: 64),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('No runs logged yet', style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Pick a run type above and tap start. Your hen is itching to move.',
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

class _WeekPlanCell extends StatelessWidget {
  const _WeekPlanCell({
    required this.day,
    required this.isToday,
    required this.hasRun,
    required this.accent,
    required this.dim,
    required this.surface,
    required this.border,
  });

  final DateTime day;
  final bool isToday;
  final bool hasRun;
  final Color accent;
  final Color dim;
  final Color surface;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final letter = DayKey.weekdayLetter(day.weekday);
    return Column(
      children: <Widget>[
        Text(
          letter,
          style: context.text.labelSmall?.copyWith(
            color: isToday ? accent : dim,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasRun ? accent : surface,
            border: Border.all(
              color: hasRun
                  ? accent
                  : (isToday ? accent.withValues(alpha: 0.6) : border),
              width: isToday ? 1.4 : 1,
            ),
          ),
          child: Icon(
            hasRun ? Icons.check_rounded : Icons.directions_run_rounded,
            size: 16,
            color: hasRun ? Colors.white : dim,
          ),
        ),
      ],
    );
  }
}

class _TargetChip extends StatelessWidget {
  const _TargetChip({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Runs per week',
      onSelected: onChanged,
      itemBuilder: (context) => <PopupMenuEntry<int>>[
        for (final n in const <int>[2, 3, 4, 5])
          PopupMenuItem<int>(
            value: n,
            child: Text('$n runs / week'),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Meadow.go.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(Corners.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.flag_rounded, size: 14, color: Meadow.go),
            const SizedBox(width: 6),
            Text(
              '×$value',
              style: context.text.labelMedium?.copyWith(
                color: Meadow.go,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.background,
    required this.border,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final Color background;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(Corners.pill),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? accent : background,
          borderRadius: BorderRadius.circular(Corners.pill),
          border: Border.all(
            color: selected ? accent : border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: context.text.labelMedium?.copyWith(
            color: selected ? Colors.white : context.palette.textPrimary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: Insets.md, horizontal: 10),
      child: Column(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _RunRow extends StatelessWidget {
  const _RunRow({required this.run});

  final RunSession run;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return SoftCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => RunDetailScreen(runId: run.id)),
      ),
      padding: const EdgeInsets.all(Insets.sm),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: run.type.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(Corners.sm),
            ),
            child: Icon(run.type.icon, color: run.type.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(run.type.label, style: context.text.titleSmall),
                Text(
                  '${run.distanceLabel} · ${run.durationLabel} · ${run.paceLabel}',
                  style: context.text.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: c.textSecondary),
        ],
      ),
    );
  }
}
