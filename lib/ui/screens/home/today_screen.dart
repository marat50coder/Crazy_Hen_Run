import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';

import '../../../foundation/constants/artwork.dart';
import '../../../foundation/theme/palette.dart';
import '../../../foundation/theme/henyard_theme.dart';
import '../../../foundation/utils/coach_lines.dart';
import '../../../foundation/utils/day_key.dart';
import '../../../persistence/models/habit.dart';
import '../../../domain/hen_state.dart';
import '../../widgets/avatar.dart';
import '../../widgets/habit_tile.dart';
import '../../widgets/hen.dart';
import '../../widgets/progress.dart';
import '../../widgets/surfaces.dart';
import '../../widgets/week_strip.dart';
import '../calendar/calendar_screen.dart';
import '../habit/habit_detail_screen.dart';
import '../habit/habit_editor_screen.dart';
import '../habit/habit_library_screen.dart';
import '../journal/journal_editor_screen.dart';
import '../settings/settings_screen.dart';
import '../sprint/sprint_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  DateTime _selected = DayKey.today();

  bool get _isToday => DayKey.isSameDay(_selected, DayKey.today());

  Future<void> _openEditor({Habit? habit}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HabitEditorScreen(existing: habit),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<HenState>();
    final c = context.palette;
    final entries = app.habitsForDay(_selected);
    final visible = app.hideCompleted
        ? entries.where((e) => !e.isComplete).toList()
        : entries;
    final summary = app.summaryFor(_selected);
    final week = DayKey.weekOf(_selected, firstWeekday: app.firstWeekday);
    final coach = Coach.forToday(app);

    return Scaffold(
      floatingActionButton: app.habits.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openEditor(),
              backgroundColor: c.accent,
              foregroundColor:
                  c.accent.computeLuminance() > 0.55 ? c.textPrimary : Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New habit'),
            ),
      body: RefreshIndicator(
        color: c.accent,
        onRefresh: () async => setState(() => _selected = DayKey.today()),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: <Widget>[
            SliverToBoxAdapter(child: _header(app)),
            if (app.showProductIntro)
              SliverToBoxAdapter(child: _productIntro(app)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.md,
                  Insets.md,
                  Insets.md,
                  0,
                ),
                child: _RunCard(
                  summary: summary,
                  coach: coach,
                  distance: app.distanceLabel,
                  henAsset: app.rank.asset,
                  isToday: _isToday,
                  selected: _selected,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.md,
                  Insets.md,
                  Insets.md,
                  0,
                ),
                child: WeekStrip(
                  days: week,
                  selected: _selected,
                  summaries: app.summariesFor(week),
                  onSelected: (day) => setState(() => _selected = day),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.md,
                  Insets.md,
                  Insets.md,
                  0,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _MiniAction(
                        icon: Icons.flag_rounded,
                        label: 'Weekly sprint',
                        value:
                            '${app.weeklyCompletions}/${app.weeklySprintTarget}',
                        progress: app.weeklySprintProgress,
                        tone: Meadow.corn,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SprintScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Insets.sm),
                    Expanded(
                      child: _MiniAction(
                        icon: Icons.edit_note_rounded,
                        label: 'Journal',
                        value: app.journalFor(_selected) == null
                            ? 'Not written'
                            : app.journalFor(_selected)!.mood.label,
                        progress: app.journalFor(_selected) == null ? 0 : 1,
                        tone: Meadow.lavender,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => JournalEditorScreen(day: _selected),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.md,
                  Insets.lg,
                  Insets.md,
                  Insets.sm,
                ),
                child: SectionHeader(
                  title: _isToday ? 'On the track today' : DayKey.pretty(_selected),
                  subtitle: entries.isEmpty
                      ? 'Nothing scheduled'
                      : '${summary.completed} of ${summary.scheduled} closed',
                  padding: EdgeInsets.zero,
                  trailing: entries.isEmpty
                      ? null
                      : IconButton(
                          tooltip: app.hideCompleted
                              ? 'Show completed'
                              : 'Hide completed',
                          onPressed: () =>
                              app.setHideCompleted(!app.hideCompleted),
                          icon: Icon(
                            app.hideCompleted
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20,
                          ),
                        ),
                ),
              ),
            ),
            if (app.habits.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: HenEmptyState(
                  title: 'The road is empty',
                  message:
                      'Add your first habit and this screen turns into your daily track.',
                  action: Column(
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: () => _openEditor(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create a habit'),
                      ),
                      const SizedBox(height: Insets.sm),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const HabitLibraryScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Browse ideas'),
                      ),
                    ],
                  ),
                ),
              )
            else if (visible.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Insets.md,
                    vertical: Insets.lg,
                  ),
                  child: SoftCard(
                    padding: const EdgeInsets.all(Insets.lg),
                    child: Row(
                      children: <Widget>[
                        const HenFigure(asset: Artwork.henHappy, size: 66),
                        const SizedBox(width: Insets.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                entries.isEmpty
                                    ? 'Rest day'
                                    : 'Everything closed',
                                style: context.text.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                entries.isEmpty
                                    ? 'No habits are scheduled for this day.'
                                    : 'Your hen is doing a victory lap.',
                                style: context.text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(Insets.md, 0, Insets.md, Insets.xxl),
                sliver: SliverList.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final entry = visible[i];
                    return AnimationConfiguration.staggeredList(
                      position: i,
                      duration: const Duration(milliseconds: 380),
                      child: SlideAnimation(
                        verticalOffset: 24,
                        child: FadeInAnimation(
                          child: Slidable(
                            key: ValueKey<String>(entry.habit.id),
                            endActionPane: ActionPane(
                              motion: const DrawerMotion(),
                              extentRatio: 0.5,
                              children: <Widget>[
                                SlidableAction(
                                  onPressed: (_) =>
                                      _openEditor(habit: entry.habit),
                                  backgroundColor: c.surfaceMuted,
                                  foregroundColor: c.textPrimary,
                                  borderRadius: BorderRadius.circular(Corners.lg),
                                  icon: Icons.tune_rounded,
                                  label: 'Edit',
                                ),
                                SlidableAction(
                                  onPressed: (_) => app.setArchived(
                                    entry.habit.id,
                                    true,
                                  ),
                                  backgroundColor:
                                      c.danger.withValues(alpha: 0.14),
                                  foregroundColor: c.danger,
                                  borderRadius: BorderRadius.circular(Corners.lg),
                                  icon: Icons.inventory_2_rounded,
                                  label: 'Archive',
                                ),
                              ],
                            ),
                            child: HabitTile(
                              entry: entry,
                              streak: app.streakFor(entry.habit),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => HabitDetailScreen(
                                    habitId: entry.habit.id,
                                  ),
                                ),
                              ),
                              onToggle: () =>
                                  app.toggleComplete(entry.habit, _selected),
                              onIncrement: () =>
                                  app.increment(entry.habit, _selected),
                              onDecrement: () => app.setValue(
                                entry.habit,
                                _selected,
                                entry.value - 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _productIntro(HenState app) {
    final c = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Insets.md, Insets.md, Insets.md, 0),
      child: SoftCard(
        color: c.accentSoft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'A habit tracker that runs with you',
                    style: context.text.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Dismiss',
                  onPressed: app.dismissProductIntro,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ),
            Text(
              'Close a habit on this list to earn metres. The Run tab logs a walk '
              'or run from the motion sensor — no GPS. Coop is the hen levelling up.',
              style: context.text.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(HenState app) {
    final c = context.palette;
    final hour = DateTime.now().hour;
    final greeting = hour < 5
        ? 'Still up'
        : hour < 12
            ? 'Good morning'
            : hour < 18
                ? 'Good afternoon'
                : 'Good evening';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Insets.md,
          Insets.sm,
          Insets.md,
          0,
        ),
        child: Row(
          children: <Widget>[
            ProfileAvatar(profile: app.profile, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(greeting, style: context.text.bodySmall),
                  Text(
                    app.profile.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleLarge,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CalendarScreen()),
              ),
              icon: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: c.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.outline),
                ),
                child: Icon(Icons.calendar_month_rounded, size: 20, color: c.textPrimary),
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
}

class _RunCard extends StatelessWidget {
  const _RunCard({
    required this.summary,
    required this.coach,
    required this.distance,
    required this.henAsset,
    required this.isToday,
    required this.selected,
  });

  final DaySummary summary;
  final CoachLine coach;
  final String distance;
  final String henAsset;
  final bool isToday;
  final DateTime selected;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          c.surface,
          Color.alphaBlend(c.accent.withValues(alpha: 0.07), c.surface),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      isToday ? DayKey.pretty(DateTime.now()) : DayKey.pretty(selected),
                      style: context.text.labelSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(coach.headline, style: context.text.headlineSmall),
                    const SizedBox(height: 4),
                    Text(coach.body, style: context.text.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ProgressRing(
                value: summary.ratio,
                size: 74,
                stroke: 8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '${summary.completed}',
                      style: context.text.titleLarge,
                    ),
                    Text(
                      'of ${summary.scheduled}',
                      style: context.text.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          RunTrackHero(
            progress: summary.ratio,
            henAsset: henAsset,
            caption: 'Total $distance',
          ),
        ],
      ),
    ).animate().fadeIn(duration: 320.ms).moveY(begin: 10, end: 0);
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.label,
    required this.value,
    required this.progress,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final double progress;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: tone),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.titleMedium,
          ),
          const SizedBox(height: 8),
          TrackBar(value: progress, height: 5, color: tone),
        ],
      ),
    );
  }
}
