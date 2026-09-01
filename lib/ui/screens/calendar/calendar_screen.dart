import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../foundation/constants/artwork.dart';
import '../../../foundation/theme/palette.dart';
import '../../../foundation/theme/henyard_theme.dart';
import '../../../foundation/utils/day_key.dart';
import '../../../persistence/models/habit.dart';
import '../../../domain/hen_state.dart';
import '../../../domain/run_tracker.dart';
import '../../widgets/hen.dart';
import '../../widgets/surfaces.dart';
import '../habit/habit_detail_screen.dart';
import '../journal/journal_editor_screen.dart';
import '../journal/journal_screen.dart';

/// Month-first view. The calendar owns the top half and the selected day is
/// explained underneath, which is the inverse of the Today screen layout.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DayKey.today();
  DateTime _selected = DayKey.today();
  CalendarFormat _format = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<HenState>();
    final run = context.watch<RunTracker>();
    final c = context.palette;
    final entries = app.habitsForDay(_selected);
    final summary = app.summaryFor(_selected);
    final journal = app.journalFor(_selected);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.md,
                  Insets.sm,
                  Insets.md,
                  0,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Your month', style: context.text.labelSmall),
                          Text(
                            DayKey.monthYear(_focused),
                            style: context.text.headlineMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Journal',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const JournalScreen(),
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
                          Icons.auto_stories_rounded,
                          size: 19,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(Insets.md),
                child: SoftCard(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
                  child: TableCalendar<void>(
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2100),
                    focusedDay: _focused,
                    currentDay: DayKey.today(),
                    calendarFormat: _format,
                    startingDayOfWeek: app.mondayFirst
                        ? StartingDayOfWeek.monday
                        : StartingDayOfWeek.sunday,
                    availableCalendarFormats: const <CalendarFormat, String>{
                      CalendarFormat.month: 'Month',
                      CalendarFormat.twoWeeks: '2 weeks',
                      CalendarFormat.week: 'Week',
                    },
                    onFormatChanged: (f) => setState(() => _format = f),
                    selectedDayPredicate: (day) =>
                        DayKey.isSameDay(day, _selected),
                    onDaySelected: (selected, focused) => setState(() {
                      _selected = DayKey.normalize(selected);
                      _focused = focused;
                    }),
                    onPageChanged: (focused) => setState(() => _focused = focused),
                    headerStyle: HeaderStyle(
                      titleCentered: true,
                      formatButtonShowsNext: false,
                      titleTextStyle: context.text.titleMedium!,
                      formatButtonTextStyle: context.text.labelSmall!.copyWith(
                        color: c.accent,
                      ),
                      formatButtonDecoration: BoxDecoration(
                        color: c.accentSoft,
                        borderRadius: BorderRadius.circular(Corners.pill),
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left_rounded,
                        color: c.textSecondary,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right_rounded,
                        color: c.textSecondary,
                      ),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: context.text.labelSmall!,
                      weekendStyle: context.text.labelSmall!,
                    ),
                    calendarStyle: const CalendarStyle(outsideDaysVisible: false),
                    calendarBuilders: CalendarBuilders<void>(
                      defaultBuilder: (context, day, _) =>
                          _DayCell(day: day, app: app, run: run),
                      todayBuilder: (context, day, _) =>
                          _DayCell(day: day, app: app, run: run, isToday: true),
                      selectedBuilder: (context, day, _) =>
                          _DayCell(day: day, app: app, run: run, isSelected: true),
                      disabledBuilder: (context, day, _) =>
                          _DayCell(day: day, app: app, run: run, dim: true),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.md),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            DayKey.pretty(_selected),
                            style: context.text.titleMedium,
                          ),
                          Text(
                            summary.scheduled == 0
                                ? 'Nothing was scheduled'
                                : '${summary.completed}/${summary.scheduled} habits closed',
                            style: context.text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (summary.isPerfect)
                      TagChip(
                        label: 'Perfect day',
                        icon: Icons.verified_rounded,
                        color: c.positive,
                      ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: Insets.sm)),
            if (entries.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(Insets.md),
                  child: SoftCard(
                    padding: const EdgeInsets.all(Insets.lg),
                    child: Row(
                      children: <Widget>[
                        const HenFigure(
                          asset: Artwork.henStanding,
                          size: 56,
                          idle: false,
                        ),
                        const SizedBox(width: Insets.md),
                        Expanded(
                          child: Text(
                            'No habits were scheduled on this day.',
                            style: context.text.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.md),
                sliver: SliverList.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final entry = entries[i];
                    final tone = HabitSwatches.at(entry.habit.colorIndex);
                    return SoftCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              HabitDetailScreen(habitId: entry.habit.id),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 6,
                            height: 34,
                            decoration: BoxDecoration(
                              color: tone,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  entry.habit.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.text.titleSmall,
                                ),
                                Text(
                                  entry.habit.goalType == HabitGoalType.check
                                      ? entry.habit.category.label
                                      : '${entry.value}/${entry.target}',
                                  style: context.text.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Checkbox(
                            value: entry.isComplete,
                            activeColor: tone,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7),
                            ),
                            onChanged: (_) =>
                                app.toggleComplete(entry.habit, _selected),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.md,
                  Insets.md,
                  Insets.md,
                  140,
                ),
                child: SoftCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => JournalEditorScreen(day: _selected),
                    ),
                  ),
                  color: Meadow.lavender.withValues(alpha: 0.10),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        journal == null
                            ? Icons.edit_note_rounded
                            : Icons.auto_stories_rounded,
                        color: Meadow.lavender,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              journal == null
                                  ? 'Add a note for this day'
                                  : '${journal.mood.emoji}  ${journal.mood.label}',
                              style: context.text.titleSmall,
                            ),
                            Text(
                              journal == null
                                  ? 'How did it actually feel?'
                                  : (journal.note.isEmpty
                                      ? 'No text, just the mood.'
                                      : journal.note),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: c.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.app,
    required this.run,
    this.isToday = false,
    this.isSelected = false,
    this.dim = false,
  });

  final DateTime day;
  final HenState app;
  final RunTracker run;
  final bool isToday;
  final bool isSelected;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final summary = app.summaryFor(day);
    final ratio = summary.ratio;
    final ranToday = run.ranOnDay(day);

    final Color background;
    final Color foreground;
    if (isSelected) {
      background = c.accent;
      foreground =
          c.accent.computeLuminance() > 0.55 ? c.textPrimary : Colors.white;
    } else if (summary.isPerfect) {
      background = c.accent.withValues(alpha: 0.22);
      foreground = c.textPrimary;
    } else if (ratio > 0) {
      background = c.accent.withValues(alpha: 0.10);
      foreground = c.textPrimary;
    } else {
      background = Colors.transparent;
      foreground = dim ? c.textSecondary.withValues(alpha: 0.4) : c.textPrimary;
    }

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Corners.sm),
        border: isToday && !isSelected
            ? Border.all(color: c.accent, width: 1.4)
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Text(
            '${day.day}',
            style: context.text.titleSmall?.copyWith(color: foreground),
          ),
          if (ranToday)
            Positioned(
              top: 3,
              right: 3,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Meadow.go,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? c.accent : c.surface,
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.directions_run_rounded,
                  size: 8,
                  color: Colors.white,
                ),
              ),
            ),
          if (summary.scheduled > 0)
            Positioned(
              bottom: 5,
              child: Container(
                width: 16,
                height: 3,
                decoration: BoxDecoration(
                  color: (isSelected ? foreground : c.accent)
                      .withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: ratio == 0 ? 0.001 : ratio,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? foreground : c.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
