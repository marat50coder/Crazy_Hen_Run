import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/day_key.dart';

/// Contribution-graph style grid: one column per week, one row per weekday.
class HabitHeatmap extends StatelessWidget {
  const HabitHeatmap({
    super.key,
    required this.weeks,
    required this.intensityFor,
    required this.tone,
    this.cell = 14,
    this.gap = 4,
    this.onTapDay,
  });

  final int weeks;

  /// 0 = nothing logged, 1 = target met. Values in between shade the cell.
  final double Function(DateTime day) intensityFor;

  final Color tone;
  final double cell;
  final double gap;
  final ValueChanged<DateTime>? onTapDay;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final today = DayKey.today();
    final end = DayKey.startOfWeek(today).add(const Duration(days: 6));
    final start = end.subtract(Duration(days: weeks * 7 - 1));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List<Widget>.generate(7, (row) {
              return Container(
                height: cell,
                margin: EdgeInsets.only(bottom: gap, right: 6),
                alignment: Alignment.centerRight,
                child: row.isEven
                    ? Text(
                        DayKey.weekdayShort(row + 1),
                        style: TextStyle(
                          fontSize: 9,
                          color: c.textSecondary,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      )
                    : const SizedBox.shrink(),
              );
            }),
          ),
          ...List<Widget>.generate(weeks, (col) {
            return Column(
              children: List<Widget>.generate(7, (row) {
                final day = start.add(Duration(days: col * 7 + row));
                final future = day.isAfter(today);
                final intensity = future ? 0.0 : intensityFor(day);
                return GestureDetector(
                  onTap: future || onTapDay == null
                      ? null
                      : () => onTapDay!(day),
                  child: Container(
                    width: cell,
                    height: cell,
                    margin: EdgeInsets.only(right: gap, bottom: gap),
                    decoration: BoxDecoration(
                      color: intensity <= 0
                          ? (future
                              ? c.surfaceMuted.withValues(alpha: 0.4)
                              : c.surfaceMuted)
                          : tone.withValues(alpha: 0.25 + intensity * 0.75),
                      borderRadius: BorderRadius.circular(4),
                      border: DayKey.isSameDay(day, today)
                          ? Border.all(color: c.textPrimary, width: 1.2)
                          : null,
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
}

class HeatmapLegend extends StatelessWidget {
  const HeatmapLegend({super.key, required this.tone});

  final Color tone;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Text('Less', style: TextStyle(fontSize: 10, color: c.textSecondary)),
        const SizedBox(width: 6),
        ...List<Widget>.generate(5, (i) {
          final alpha = i == 0 ? 0.0 : 0.25 + (i / 4) * 0.75;
          return Container(
            width: 11,
            height: 11,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: alpha == 0 ? c.surfaceMuted : tone.withValues(alpha: alpha),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
        const SizedBox(width: 3),
        Text('More', style: TextStyle(fontSize: 10, color: c.textSecondary)),
      ],
    );
  }
}
