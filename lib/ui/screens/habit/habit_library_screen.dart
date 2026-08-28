import 'package:flutter/material.dart';

import '../../../foundation/theme/palette.dart';
import '../../../foundation/theme/henyard_theme.dart';
import '../../../persistence/models/habit.dart';
import '../../widgets/surfaces.dart';
import 'habit_editor_screen.dart';

class _Template {
  const _Template({
    required this.title,
    required this.category,
    required this.goalType,
    required this.difficulty,
    required this.target,
    required this.unit,
    required this.colorIndex,
    required this.weekdays,
    required this.blurb,
  });

  final String title;
  final HabitCategory category;
  final HabitGoalType goalType;
  final HabitDifficulty difficulty;
  final int target;
  final String unit;
  final int colorIndex;
  final Set<int> weekdays;
  final String blurb;

  Habit toHabit() => Habit(
        id: 't${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        category: category,
        goalType: goalType,
        difficulty: difficulty,
        colorIndex: colorIndex,
        targetValue: target,
        unit: unit,
        weekdays: weekdays,
        createdAt: DateTime.now(),
        note: blurb,
      );
}

/// Idea catalogue. Laid out as a filter row plus a two column mosaic so it
/// deliberately does not look like the list-based screens.
class HabitLibraryScreen extends StatefulWidget {
  const HabitLibraryScreen({super.key});

  @override
  State<HabitLibraryScreen> createState() => _HabitLibraryScreenState();
}

class _HabitLibraryScreenState extends State<HabitLibraryScreen> {
  static const Set<int> _daily = <int>{1, 2, 3, 4, 5, 6, 7};
  static const Set<int> _weekdaysOnly = <int>{1, 2, 3, 4, 5};

  static const List<_Template> _templates = <_Template>[
    _Template(
      title: 'Morning run',
      category: HabitCategory.movement,
      goalType: HabitGoalType.duration,
      difficulty: HabitDifficulty.hard,
      target: 20,
      unit: 'min',
      colorIndex: 1,
      weekdays: <int>{1, 3, 5},
      blurb: 'Out the door before the excuses wake up.',
    ),
    _Template(
      title: '10 000 steps',
      category: HabitCategory.movement,
      goalType: HabitGoalType.check,
      difficulty: HabitDifficulty.normal,
      target: 1,
      unit: 'times',
      colorIndex: 0,
      weekdays: _daily,
      blurb: 'Walk the long way on purpose.',
    ),
    _Template(
      title: 'Stretch',
      category: HabitCategory.movement,
      goalType: HabitGoalType.duration,
      difficulty: HabitDifficulty.easy,
      target: 10,
      unit: 'min',
      colorIndex: 8,
      weekdays: _daily,
      blurb: 'Ten minutes so your back forgives you.',
    ),
    _Template(
      title: 'Drink water',
      category: HabitCategory.health,
      goalType: HabitGoalType.quantity,
      difficulty: HabitDifficulty.easy,
      target: 8,
      unit: 'glasses',
      colorIndex: 7,
      weekdays: _daily,
      blurb: 'Eight glasses, no negotiation.',
    ),
    _Template(
      title: 'Sleep before midnight',
      category: HabitCategory.rest,
      goalType: HabitGoalType.check,
      difficulty: HabitDifficulty.normal,
      target: 1,
      unit: 'times',
      colorIndex: 6,
      weekdays: _daily,
      blurb: 'Tomorrow starts the night before.',
    ),
    _Template(
      title: 'Read 10 pages',
      category: HabitCategory.mind,
      goalType: HabitGoalType.quantity,
      difficulty: HabitDifficulty.normal,
      target: 10,
      unit: 'pages',
      colorIndex: 6,
      weekdays: _daily,
      blurb: 'Small pages, big library.',
    ),
    _Template(
      title: 'Meditate',
      category: HabitCategory.mind,
      goalType: HabitGoalType.duration,
      difficulty: HabitDifficulty.normal,
      target: 10,
      unit: 'min',
      colorIndex: 9,
      weekdays: _daily,
      blurb: 'Sit still long enough to hear yourself.',
    ),
    _Template(
      title: 'No screens after 22:00',
      category: HabitCategory.rest,
      goalType: HabitGoalType.check,
      difficulty: HabitDifficulty.hard,
      target: 1,
      unit: 'times',
      colorIndex: 4,
      weekdays: _daily,
      blurb: 'The feed will survive without you.',
    ),
    _Template(
      title: 'Cook at home',
      category: HabitCategory.nutrition,
      goalType: HabitGoalType.check,
      difficulty: HabitDifficulty.normal,
      target: 1,
      unit: 'times',
      colorIndex: 3,
      weekdays: _weekdaysOnly,
      blurb: 'Cheaper, better, and you know what is in it.',
    ),
    _Template(
      title: 'Eat vegetables',
      category: HabitCategory.nutrition,
      goalType: HabitGoalType.quantity,
      difficulty: HabitDifficulty.easy,
      target: 3,
      unit: 'portions',
      colorIndex: 1,
      weekdays: _daily,
      blurb: 'Green things, three times.',
    ),
    _Template(
      title: 'Deep work block',
      category: HabitCategory.focus,
      goalType: HabitGoalType.duration,
      difficulty: HabitDifficulty.hard,
      target: 60,
      unit: 'min',
      colorIndex: 2,
      weekdays: _weekdaysOnly,
      blurb: 'One hour, no notifications, no excuses.',
    ),
    _Template(
      title: 'Inbox to zero',
      category: HabitCategory.focus,
      goalType: HabitGoalType.check,
      difficulty: HabitDifficulty.easy,
      target: 1,
      unit: 'times',
      colorIndex: 7,
      weekdays: _weekdaysOnly,
      blurb: 'Close the loops before they close you.',
    ),
    _Template(
      title: 'Call someone you love',
      category: HabitCategory.social,
      goalType: HabitGoalType.check,
      difficulty: HabitDifficulty.easy,
      target: 1,
      unit: 'times',
      colorIndex: 5,
      weekdays: <int>{7},
      blurb: 'Five minutes that make somebody\'s week.',
    ),
    _Template(
      title: 'No impulse buys',
      category: HabitCategory.money,
      goalType: HabitGoalType.check,
      difficulty: HabitDifficulty.normal,
      target: 1,
      unit: 'times',
      colorIndex: 9,
      weekdays: _daily,
      blurb: 'Sleep on it for a day. Usually you stop wanting it.',
    ),
    _Template(
      title: 'Track spending',
      category: HabitCategory.money,
      goalType: HabitGoalType.check,
      difficulty: HabitDifficulty.easy,
      target: 1,
      unit: 'times',
      colorIndex: 2,
      weekdays: _daily,
      blurb: 'Two minutes now beats a nasty surprise later.',
    ),
    _Template(
      title: 'Journal',
      category: HabitCategory.mind,
      goalType: HabitGoalType.check,
      difficulty: HabitDifficulty.easy,
      target: 1,
      unit: 'times',
      colorIndex: 5,
      weekdays: _daily,
      blurb: 'Three lines is still journalling.',
    ),
  ];

  HabitCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final visible = _filter == null
        ? _templates
        : _templates.where((t) => t.category == _filter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Habit ideas')),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Insets.md),
              children: <Widget>[
                _FilterChip(
                  label: 'All',
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                ...HabitCategory.values.map(
                  (cat) => _FilterChip(
                    label: cat.label,
                    icon: cat.icon,
                    selected: _filter == cat,
                    onTap: () => setState(() => _filter = cat),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                Insets.md,
                Insets.md,
                Insets.md,
                Insets.xxl,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: visible.length,
              itemBuilder: (context, i) {
                final t = visible[i];
                final tone = HabitSwatches.at(t.colorIndex);
                return SoftCard(
                  padding: const EdgeInsets.all(14),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => HabitEditorScreen(template: t.toHabit()),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: tone.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(Corners.sm),
                        ),
                        child: Icon(t.category.icon, size: 20, color: tone),
                      ),
                      const Spacer(),
                      Text(
                        t.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.blurb,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          TagChip(
                            label: t.goalType == HabitGoalType.duration
                                ? '${t.target} min'
                                : t.goalType == HabitGoalType.quantity
                                    ? '${t.target} ${t.unit}'
                                    : 'Daily check',
                            color: tone,
                            dense: true,
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: c.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? c.accent : c.surface,
            borderRadius: BorderRadius.circular(Corners.pill),
            border: Border.all(color: selected ? c.accent : c.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(
                  icon,
                  size: 15,
                  color: selected
                      ? (c.accent.computeLuminance() > 0.55
                          ? c.textPrimary
                          : Colors.white)
                      : c.textSecondary,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: context.text.labelMedium?.copyWith(
                  color: selected
                      ? (c.accent.computeLuminance() > 0.55
                          ? c.textPrimary
                          : Colors.white)
                      : c.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
