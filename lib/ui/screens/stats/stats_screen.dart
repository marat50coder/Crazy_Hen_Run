import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../foundation/theme/palette.dart';
import '../../../foundation/theme/henyard_theme.dart';
import '../../../foundation/utils/day_key.dart';
import '../../../persistence/models/habit.dart';
import '../../../domain/hen_state.dart';
import '../../widgets/hen.dart';
import '../../widgets/progress.dart';
import '../../widgets/surfaces.dart';
import 'weekly_report_screen.dart';

/// Analytics dashboard. A range switcher drives one big chart, followed by a
/// mosaic of smaller visualisations.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  static const List<({String label, int days})> _ranges =
      <({String label, int days})>[
    (label: '7D', days: 7),
    (label: '14D', days: 14),
    (label: '30D', days: 30),
    (label: '90D', days: 90),
  ];

  int _rangeIndex = 2;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<HenState>();
    final c = context.palette;
    final days = DayKey.lastDays(_ranges[_rangeIndex].days);
    final summaries = app.summariesFor(days);

    if (app.habits.isEmpty && app.totalCompletions == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Statistics')),
        body: const HenEmptyState(
          title: 'Nothing to measure yet',
          message:
              'Close a few habits and this screen fills up with charts about your own behaviour.',
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            Insets.md,
            Insets.sm,
            Insets.md,
            140,
          ),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Your numbers', style: context.text.labelSmall),
                      Text('Statistics', style: context.text.headlineMedium),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Weekly report',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const WeeklyReportScreen(),
                    ),
                  ),
                  icon: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: c.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.outline),
                    ),
                    child: Icon(
                      Icons.summarize_rounded,
                      size: 19,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.md),
            _HeadlineStrip(app: app),
            const SizedBox(height: Insets.md),
            SoftCard(
              padding: const EdgeInsets.fromLTRB(14, 16, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Completion trend',
                          style: context.text.titleSmall,
                        ),
                      ),
                      _RangeSwitch(
                        labels: _ranges.map((r) => r.label).toList(),
                        index: _rangeIndex,
                        onChanged: (i) => setState(() => _rangeIndex = i),
                      ),
                    ],
                  ),
                  const SizedBox(height: Insets.md),
                  SizedBox(
                    height: 190,
                    child: _TrendChart(summaries: summaries),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Insets.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: SoftCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('By category', style: context.text.titleSmall),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 128,
                          child: _CategoryDonut(app: app),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: Insets.sm),
                Expanded(
                  child: SoftCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Strongest days', style: context.text.titleSmall),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 128,
                          child: _WeekdayChart(app: app),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.md),
            SectionHeader(
              title: 'Habit leaderboard',
              subtitle: 'Ranked by consistency since you created them',
            ),
            ..._leaderboard(app, context),
          ],
        ),
      ),
    );
  }

  List<Widget> _leaderboard(HenState app, BuildContext context) {
    final habits = <Habit>[...app.habits];
    if (habits.isEmpty) {
      return <Widget>[
        SoftCard(
          child: Text(
            'No active habits right now.',
            style: context.text.bodyMedium,
          ),
        ),
      ];
    }

    habits.sort(
      (a, b) => app.consistencyFor(b).compareTo(app.consistencyFor(a)),
    );

    return habits.map((habit) {
      final tone = HabitSwatches.at(habit.colorIndex);
      final ratio = app.consistencyFor(habit);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(Corners.sm),
                ),
                child: Icon(habit.category.icon, size: 18, color: tone),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      habit.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    TrackBar(value: ratio, height: 6, color: tone),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(ratio * 100).round()}%',
                style: context.text.titleSmall?.copyWith(color: tone),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _HeadlineStrip extends StatelessWidget {
  const _HeadlineStrip({required this.app});

  final HenState app;

  @override
  Widget build(BuildContext context) {
    final items = <({String label, String value, IconData icon, Color tone})>[
      (
        label: 'Distance',
        value: app.distanceLabel,
        icon: Icons.route_rounded,
        tone: Meadow.moss
      ),
      (
        label: 'Completed',
        value: '${app.totalCompletions}',
        icon: Icons.check_circle_rounded,
        tone: Meadow.lime
      ),
      (
        label: 'Best streak',
        value: '${app.longestStreak}d',
        icon: Icons.local_fire_department_rounded,
        tone: Meadow.yolk
      ),
      (
        label: 'Perfect days',
        value: '${app.perfectDays}',
        icon: Icons.verified_rounded,
        tone: Meadow.sky
      ),
    ];

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final item = items[i];
          return Container(
            width: 132,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: item.tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Corners.lg),
              border: Border.all(color: item.tone.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Icon(item.icon, size: 18, color: item.tone),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.headlineSmall,
                ),
                Text(item.label, style: context.text.labelSmall),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RangeSwitch extends StatelessWidget {
  const _RangeSwitch({
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(Corners.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(labels.length, (i) {
          final selected = i == index;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? c.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(Corners.pill),
                border: selected ? Border.all(color: c.outline) : null,
              ),
              child: Text(
                labels[i],
                style: context.text.labelSmall?.copyWith(
                  color: selected ? c.textPrimary : c.textSecondary,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.summaries});

  final List<DaySummary> summaries;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final maxY = math.max(
      1.0,
      summaries.fold<double>(
        0,
        (prev, s) => math.max(prev, s.completed.toDouble()),
      ),
    );

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY + 1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: math.max(1, (maxY / 3).roundToDouble()),
          getDrawingHorizontalLine: (_) => FlLine(
            color: c.outline,
            strokeWidth: 1,
            dashArray: <int>[4, 6],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: math.max(1, (maxY / 3).roundToDouble()),
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: TextStyle(fontSize: 10, color: c.textSecondary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: math.max(1, (summaries.length / 5).floorToDouble()),
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= summaries.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${summaries[i].day.day}',
                    style: TextStyle(fontSize: 10, color: c.textSecondary),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => c.surfaceInverse,
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    '${s.y.toInt()} closed',
                    TextStyle(
                      color: c.textInverse,
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            isCurved: true,
            curveSmoothness: 0.28,
            preventCurveOverShooting: true,
            barWidth: 3,
            color: c.accent,
            dotData: FlDotData(
              show: summaries.length <= 14,
              getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                radius: 3.5,
                color: c.surface,
                strokeWidth: 2.4,
                strokeColor: c.accent,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  c.accent.withValues(alpha: 0.28),
                  c.accent.withValues(alpha: 0.02),
                ],
              ),
            ),
            spots: List<FlSpot>.generate(
              summaries.length,
              (i) => FlSpot(i.toDouble(), summaries[i].completed.toDouble()),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryDonut extends StatelessWidget {
  const _CategoryDonut({required this.app});

  final HenState app;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final data = app.completionsByCategory;
    if (data.isEmpty) {
      return Center(
        child: Text('No data yet', style: context.text.bodySmall),
      );
    }

    final total = data.values.fold<int>(0, (a, b) => a + b);
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Row(
      children: <Widget>[
        SizedBox(
          width: 92,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 26,
              sections: List<PieChartSectionData>.generate(entries.length, (i) {
                final entry = entries[i];
                final tone = HabitSwatches.at(entry.key.index);
                return PieChartSectionData(
                  value: entry.value.toDouble(),
                  color: tone,
                  radius: 16,
                  showTitle: false,
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: entries.take(4).map((entry) {
              final tone = HabitSwatches.at(entry.key.index);
              final pct = ((entry.value / total) * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: tone,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        entry.key.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: c.textSecondary,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _WeekdayChart extends StatelessWidget {
  const _WeekdayChart({required this.app});

  final HenState app;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final data = app.completionsByWeekday;
    final maxValue = data.values.fold<int>(0, math.max);

    if (maxValue == 0) {
      return Center(
        child: Text('No data yet', style: context.text.bodySmall),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue.toDouble() * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (value, _) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  DayKey.weekdayLetter(value.toInt() + 1),
                  style: TextStyle(fontSize: 10, color: c.textSecondary),
                ),
              ),
            ),
          ),
        ),
        barGroups: List<BarChartGroupData>.generate(7, (i) {
          final value = (data[i + 1] ?? 0).toDouble();
          final ratio = maxValue == 0 ? 0.0 : value / maxValue;
          return BarChartGroupData(
            x: i,
            barRods: <BarChartRodData>[
              BarChartRodData(
                toY: value == 0 ? maxValue * 0.04 : value,
                width: 10,
                borderRadius: BorderRadius.circular(5),
                color: value == 0
                    ? c.outline
                    : c.accent.withValues(alpha: 0.35 + ratio * 0.65),
              ),
            ],
          );
        }),
      ),
    );
  }
}
