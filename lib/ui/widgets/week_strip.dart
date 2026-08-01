import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/day_key.dart';
import '../../state/app_state.dart';

/// Seven-day selector with a completion ring baked into each day.
class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.days,
    required this.selected,
    required this.summaries,
    required this.onSelected,
  });

  final List<DateTime> days;
  final DateTime selected;
  final List<DaySummary> summaries;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final today = DayKey.today();

    return Row(
      children: List<Widget>.generate(days.length, (i) {
        final day = days[i];
        final summary = summaries[i];
        final isSelected = DayKey.isSameDay(day, selected);
        final isToday = DayKey.isSameDay(day, today);
        final future = day.isAfter(today);

        return Expanded(
          child: GestureDetector(
            onTap: future ? null : () => onSelected(day),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? c.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isToday ? c.accent.withValues(alpha: 0.5) : c.outline),
                ),
              ),
              child: Column(
                children: <Widget>[
                  Text(
                    DayKey.weekdayLetter(day.weekday),
                    style: context.text.labelSmall?.copyWith(
                      color: isSelected
                          ? _onAccent(c.accent).withValues(alpha: 0.75)
                          : c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: context.text.titleSmall?.copyWith(
                      color: isSelected
                          ? _onAccent(c.accent)
                          : (future ? c.textSecondary : c.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _DayDot(
                    summary: summary,
                    selected: isSelected,
                    accent: c.accent,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  static Color _onAccent(Color accent) =>
      accent.computeLuminance() > 0.55 ? const Color(0xFF102117) : Colors.white;
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.summary,
    required this.selected,
    required this.accent,
  });

  final DaySummary summary;
  final bool selected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    if (summary.scheduled == 0) {
      return Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (selected ? Colors.white : c.outlineStrong)
              .withValues(alpha: 0.5),
        ),
      );
    }

    final complete = summary.isPerfect;
    final base = selected
        ? (accent.computeLuminance() > 0.55 ? const Color(0xFF102117) : Colors.white)
        : accent;

    return Container(
      width: 18,
      height: 5,
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: summary.ratio == 0 ? 0.001 : summary.ratio,
        child: Container(
          decoration: BoxDecoration(
            color: complete ? base : base.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
