import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/day_key.dart';
import '../../../data/models/habit.dart';
import '../../../state/app_state.dart';
import '../../widgets/heatmap.dart';
import '../../widgets/progress.dart';
import '../../widgets/surfaces.dart';
import 'habit_editor_screen.dart';

/// Detail view built around a big coloured header that collapses into the app
/// bar, so it reads differently from the card-stack screens.
class HabitDetailScreen extends StatelessWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final String habitId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final habit = app.habitById(habitId);
    if (habit == null) {
      return const Scaffold(body: Center(child: Text('Habit not found')));
    }

    final c = context.palette;
    final tone = HabitPalette.at(habit.colorIndex);
    final streak = app.streakFor(habit);
    final best = app.bestStreakFor(habit);
    final completions = app.completionCountFor(habit);
    final consistency = app.consistencyFor(habit);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            expandedHeight: 232,
            backgroundColor: c.canvas,
            actions: <Widget>[
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => HabitEditorScreen(existing: habit),
                  ),
                ),
                icon: const Icon(Icons.tune_rounded),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) async {
                  if (value == 'archive') {
                    await app.setArchived(habit.id, !habit.archived);
                  } else if (value == 'delete') {
                    final ok = await _confirmDelete(context, habit);
                    if (ok != true) return;
                    await app.deleteHabit(habit.id);
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'archive',
                    child: Text(habit.archived ? 'Restore' : 'Archive'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 14, right: 56),
              title: Text(
                habit.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleMedium,
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      tone.withValues(alpha: 0.30),
                      tone.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xl,
                      AppSpacing.md,
                      48,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              TagChip(
                                label: habit.category.label,
                                icon: habit.category.icon,
                                color: tone,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                habit.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.displaySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${habit.targetLabel} · ${habit.isDaily ? 'every day' : '${habit.weekdays.length}× per week'}',
                                style: context.text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        ProgressRing(
                          value: consistency,
                          size: 76,
                          stroke: 8,
                          color: tone,
                          child: Text(
                            '${(consistency * 100).round()}%',
                            style: context.text.titleSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            sliver: SliverList.list(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _Metric(
                        label: 'Current streak',
                        value: '$streak',
                        unit: streak == 1 ? 'day' : 'days',
                        icon: Icons.local_fire_department_rounded,
                        tone: Brand.yolk,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _Metric(
                        label: 'Best streak',
                        value: '$best',
                        unit: best == 1 ? 'day' : 'days',
                        icon: Icons.emoji_events_rounded,
                        tone: Brand.corn,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _Metric(
                        label: 'Completed',
                        value: '$completions',
                        unit: 'times',
                        icon: Icons.check_circle_rounded,
                        tone: tone,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _Metric(
                        label: 'Distance',
                        value: _distance(completions, habit),
                        unit: 'earned',
                        icon: Icons.route_rounded,
                        tone: Brand.moss,
                      ),
                    ),
                  ],
                ),
                if (habit.note.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  SoftCard(
                    color: tone.withValues(alpha: 0.08),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(Icons.format_quote_rounded, color: tone),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(habit.note, style: context.text.bodyLarge),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(
                  title: 'Last 20 weeks',
                  subtitle: 'Every square is one day',
                ),
                SoftCard(
                  child: Column(
                    children: <Widget>[
                      HabitHeatmap(
                        weeks: 20,
                        tone: tone,
                        intensityFor: (day) {
                          if (!habit.isScheduledOn(day)) return 0;
                          final log = app.logFor(habit.id, day);
                          if (log == null) return 0;
                          return log.progress;
                        },
                        onTapDay: (day) => _toggleDay(context, app, habit, day),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      HeatmapLegend(tone: tone),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(
                  title: 'Last 14 days',
                  subtitle: 'How close you got to the target',
                ),
                SoftCard(
                  padding: const EdgeInsets.fromLTRB(10, 20, 16, 10),
                  child: SizedBox(
                    height: 170,
                    child: _MiniBarChart(habit: habit, app: app, tone: tone),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(title: 'Scheduled on'),
                SoftCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List<Widget>.generate(7, (i) {
                      final weekday = i + 1;
                      final on = habit.weekdays.contains(weekday);
                      return Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: on ? tone.withValues(alpha: 0.16) : c.surfaceMuted,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          DayKey.weekdayLetter(weekday),
                          style: context.text.labelMedium?.copyWith(
                            color: on ? tone : c.textSecondary,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _distance(int completions, Habit habit) {
    final metres = completions * 250 * habit.difficulty.multiplier;
    if (metres < 1000) return '$metres m';
    return '${(metres / 1000).toStringAsFixed(1)} km';
  }

  Future<void> _toggleDay(
    BuildContext context,
    AppState app,
    Habit habit,
    DateTime day,
  ) async {
    if (!habit.isScheduledOn(day)) return;
    await app.toggleComplete(habit, day);
  }

  Future<bool?> _confirmDelete(BuildContext context, Habit habit) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text(
          'This removes "${habit.title}" and every log attached to it. It cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.palette.danger,
              minimumSize: const Size(110, 46),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.tone,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: tone),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.headlineSmall,
          ),
          Text('$label · $unit', style: context.text.labelSmall),
        ],
      ),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({
    required this.habit,
    required this.app,
    required this.tone,
  });

  final Habit habit;
  final AppState app;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final days = DayKey.lastDays(14);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 1.05,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 0.5,
          getDrawingHorizontalLine: (_) => FlLine(
            color: c.outline,
            strokeWidth: 1,
            dashArray: <int>[4, 6],
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= days.length) return const SizedBox.shrink();
                if (i % 2 != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${days[i].day}',
                    style: TextStyle(fontSize: 10, color: c.textSecondary),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List<BarChartGroupData>.generate(days.length, (i) {
          final day = days[i];
          final scheduled = habit.isScheduledOn(day);
          final log = app.logFor(habit.id, day);
          final value = log?.progress ?? 0;
          return BarChartGroupData(
            x: i,
            barRods: <BarChartRodData>[
              BarChartRodData(
                toY: value == 0 ? 0.04 : value,
                width: 12,
                borderRadius: BorderRadius.circular(6),
                color: value == 0
                    ? (scheduled ? c.outline : c.outline.withValues(alpha: 0.4))
                    : tone.withValues(alpha: 0.35 + value * 0.65),
              ),
            ],
          );
        }),
      ),
    );
  }
}
