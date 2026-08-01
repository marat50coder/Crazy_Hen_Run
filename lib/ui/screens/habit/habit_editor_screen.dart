import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/day_key.dart';
import '../../../data/models/habit.dart';
import '../../../state/app_state.dart';
import '../../widgets/surfaces.dart';

/// Four step wizard. Each step owns one decision, so the form never turns into
/// a wall of inputs.
class HabitEditorScreen extends StatefulWidget {
  const HabitEditorScreen({super.key, this.existing, this.template});

  final Habit? existing;
  final Habit? template;

  @override
  State<HabitEditorScreen> createState() => _HabitEditorScreenState();
}

class _HabitEditorScreenState extends State<HabitEditorScreen> {
  static const List<String> _steps = <String>['Basics', 'Goal', 'Rhythm', 'Style'];

  final PageController _pages = PageController();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _note = TextEditingController();
  final TextEditingController _unit = TextEditingController();

  int _step = 0;
  late HabitCategory _category;
  late HabitGoalType _goalType;
  late HabitDifficulty _difficulty;
  late int _colorIndex;
  late int _target;
  late Set<int> _weekdays;
  int? _minuteOfDay;

  @override
  void initState() {
    super.initState();
    final source = widget.existing ?? widget.template;
    _title.text = source?.title ?? '';
    _note.text = source?.note ?? '';
    _unit.text = source?.unit ?? 'times';
    _category = source?.category ?? HabitCategory.movement;
    _goalType = source?.goalType ?? HabitGoalType.check;
    _difficulty = source?.difficulty ?? HabitDifficulty.normal;
    _colorIndex = source?.colorIndex ?? 0;
    _target = source?.targetValue ?? 1;
    final sourceDays = source?.weekdays ?? const <int>{};
    _weekdays = sourceDays.isEmpty
        ? <int>{1, 2, 3, 4, 5, 6, 7}
        : <int>{...sourceDays};
    _minuteOfDay = source?.preferredMinuteOfDay;
  }

  @override
  void dispose() {
    _pages.dispose();
    _title.dispose();
    _note.dispose();
    _unit.dispose();
    super.dispose();
  }

  bool get _canAdvance {
    switch (_step) {
      case 0:
        return _title.text.trim().isNotEmpty;
      case 2:
        return _weekdays.isNotEmpty;
      default:
        return true;
    }
  }

  void _go(int next) {
    if (next < 0 || next >= _steps.length) return;
    setState(() => _step = next);
    _pages.animateToPage(
      next,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    final existing = widget.existing;
    final habit = Habit(
      id: existing?.id ??
          'h${DateTime.now().microsecondsSinceEpoch}',
      title: _title.text.trim().isEmpty ? 'Untitled habit' : _title.text.trim(),
      category: _category,
      goalType: _goalType,
      difficulty: _difficulty,
      colorIndex: _colorIndex,
      targetValue: _goalType == HabitGoalType.check ? 1 : _target,
      unit: _goalType == HabitGoalType.duration
          ? 'min'
          : (_unit.text.trim().isEmpty ? 'times' : _unit.text.trim()),
      weekdays: _weekdays,
      createdAt: existing?.createdAt ?? DateTime.now(),
      note: _note.text.trim(),
      preferredMinuteOfDay: _minuteOfDay,
      archived: existing?.archived ?? false,
    );
    await app.upsertHabit(habit);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final isLast = _step == _steps.length - 1;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.existing == null ? 'New habit' : 'Edit habit'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Row(
              children: List<Widget>.generate(_steps.length, (i) {
                final active = i <= _step;
                return Expanded(
                  child: GestureDetector(
                    onTap: i < _step ? () => _go(i) : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 4,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: active ? c.accent : c.outline,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _steps[i],
                          style: context.text.labelSmall?.copyWith(
                            color: active ? c.accent : c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pages,
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                _basicsStep(),
                _goalStep(),
                _rhythmStep(),
                _styleStep(),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  if (_step > 0) ...<Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _go(_step - 1),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _canAdvance
                          ? (isLast ? _save : () => _go(_step + 1))
                          : null,
                      child: Text(isLast ? 'Save habit' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBody({required String title, required String hint, required List<Widget> children}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: context.text.headlineSmall),
          const SizedBox(height: 4),
          Text(hint, style: context.text.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }

  Widget _basicsStep() {
    return _stepBody(
      title: 'What are you chasing?',
      hint: 'Name it the way you would say it out loud.',
      children: <Widget>[
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'Morning run'),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Category', style: context.text.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: HabitCategory.values.map((cat) {
            final selected = cat == _category;
            return _ChoicePill(
              selected: selected,
              icon: cat.icon,
              label: cat.label,
              onTap: () => setState(() => _category = cat),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _note,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Why does this matter? (optional)',
          ),
        ),
      ],
    );
  }

  Widget _goalStep() {
    final c = context.palette;
    return _stepBody(
      title: 'How do you measure it?',
      hint: 'A tap, a counter, or minutes on the clock.',
      children: <Widget>[
        ...HabitGoalType.values.map((type) {
          final selected = type == _goalType;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SoftCard(
              onTap: () => setState(() {
                _goalType = type;
                if (type == HabitGoalType.duration && _target < 5) _target = 15;
                if (type == HabitGoalType.quantity && _target < 2) _target = 8;
              }),
              color: selected ? c.accentSoft : null,
              child: Row(
                children: <Widget>[
                  Icon(
                    switch (type) {
                      HabitGoalType.check => Icons.check_circle_outline_rounded,
                      HabitGoalType.quantity => Icons.add_circle_outline_rounded,
                      HabitGoalType.duration => Icons.timer_outlined,
                    },
                    color: selected ? c.accent : c.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(type.label, style: context.text.titleSmall),
                        Text(
                          switch (type) {
                            HabitGoalType.check =>
                              'One tap marks the day as done.',
                            HabitGoalType.quantity =>
                              'Count up to a target, like 8 glasses.',
                            HabitGoalType.duration =>
                              'Log minutes until you hit the goal.',
                          },
                          style: context.text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (selected) Icon(Icons.check_rounded, color: c.accent),
                ],
              ),
            ),
          );
        }),
        if (_goalType != HabitGoalType.check) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          SoftCard(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Daily target', style: context.text.titleSmall),
                      Text(
                        _goalType == HabitGoalType.duration
                            ? '$_target minutes'
                            : '$_target ${_unit.text}',
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
                _RoundIcon(
                  icon: Icons.remove_rounded,
                  onTap: () => setState(
                    () => _target = (_target - (_goalType == HabitGoalType.duration ? 5 : 1)).clamp(1, 999),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$_target', style: context.text.titleLarge),
                const SizedBox(width: 8),
                _RoundIcon(
                  icon: Icons.add_rounded,
                  onTap: () => setState(
                    () => _target = (_target + (_goalType == HabitGoalType.duration ? 5 : 1)).clamp(1, 999),
                  ),
                ),
              ],
            ),
          ),
          if (_goalType == HabitGoalType.quantity) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _unit,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Unit',
                hintText: 'glasses, pages, km…',
              ),
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.lg),
        Text('Effort', style: context.text.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Harder habits pay more distance when you close them.',
          style: context.text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: HabitDifficulty.values.map((d) {
            final selected = d == _difficulty;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _difficulty = d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? c.accent : c.surface,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                        color: selected ? c.accent : c.outline,
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        Text(
                          d.label,
                          style: context.text.titleSmall?.copyWith(
                            color: selected
                                ? (c.accent.computeLuminance() > 0.55
                                    ? c.textPrimary
                                    : Colors.white)
                                : c.textPrimary,
                          ),
                        ),
                        Text(
                          '×${d.multiplier}',
                          style: context.text.labelSmall?.copyWith(
                            color: selected
                                ? (c.accent.computeLuminance() > 0.55
                                    ? c.textPrimary
                                    : Colors.white70)
                                : c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _rhythmStep() {
    final c = context.palette;
    final time = _minuteOfDay == null
        ? null
        : TimeOfDay(hour: _minuteOfDay! ~/ 60, minute: _minuteOfDay! % 60);

    return _stepBody(
      title: 'When does it happen?',
      hint: 'Pick the days you actually intend to show up.',
      children: <Widget>[
        Wrap(
          spacing: 8,
          children: <Widget>[
            _PresetChip(
              label: 'Every day',
              onTap: () => setState(() => _weekdays = <int>{1, 2, 3, 4, 5, 6, 7}),
            ),
            _PresetChip(
              label: 'Weekdays',
              onTap: () => setState(() => _weekdays = <int>{1, 2, 3, 4, 5}),
            ),
            _PresetChip(
              label: 'Weekend',
              onTap: () => setState(() => _weekdays = <int>{6, 7}),
            ),
            _PresetChip(
              label: '3× week',
              onTap: () => setState(() => _weekdays = <int>{1, 3, 5}),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: List<Widget>.generate(7, (i) {
            final weekday = i + 1;
            final selected = _weekdays.contains(weekday);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _weekdays.remove(weekday);
                    } else {
                      _weekdays.add(weekday);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? c.accent : c.surface,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                        color: selected ? c.accent : c.outline,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        DayKey.weekdayLetter(weekday),
                        style: context.text.titleSmall?.copyWith(
                          color: selected
                              ? (c.accent.computeLuminance() > 0.55
                                  ? c.textPrimary
                                  : Colors.white)
                              : c.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        SoftCard(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time ?? const TimeOfDay(hour: 8, minute: 0),
            );
            if (picked == null) return;
            setState(() => _minuteOfDay = picked.hour * 60 + picked.minute);
          },
          child: Row(
            children: <Widget>[
              Icon(Icons.schedule_rounded, color: c.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Planned time', style: context.text.titleSmall),
                    Text(
                      time == null
                          ? 'Anytime during the day'
                          : time.format(context),
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              if (_minuteOfDay != null)
                IconButton(
                  onPressed: () => setState(() => _minuteOfDay = null),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _styleStep() {
    final c = context.palette;
    return _stepBody(
      title: 'Give it a colour',
      hint: 'Colour codes the tile, the calendar and the charts.',
      children: <Widget>[
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List<Widget>.generate(HabitPalette.swatches.length, (i) {
            final selected = i == _colorIndex;
            final tone = HabitPalette.at(i);
            return GestureDetector(
              onTap: () => setState(() => _colorIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: tone,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? c.textPrimary : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded, color: Colors.white)
                    : null,
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        SoftCard(
          color: HabitPalette.at(_colorIndex).withValues(alpha: 0.12),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: HabitPalette.at(_colorIndex).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(
                  _category.icon,
                  color: HabitPalette.at(_colorIndex),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _title.text.trim().isEmpty
                          ? 'Your new habit'
                          : _title.text.trim(),
                      style: context.text.titleMedium,
                    ),
                    Text(
                      '${_weekdays.length == 7 ? 'Every day' : '${_weekdays.length}× per week'} · ${_difficulty.label}',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.accent : c.surface,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: selected ? c.accent : c.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 16,
              color: selected
                  ? (c.accent.computeLuminance() > 0.55
                      ? c.textPrimary
                      : Colors.white)
                  : c.textSecondary,
            ),
            const SizedBox(width: 6),
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
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return ActionChip(
      onPressed: onTap,
      label: Text(label),
      labelStyle: context.text.labelMedium,
      backgroundColor: c.surfaceMuted,
      side: BorderSide(color: c.outline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          shape: BoxShape.circle,
          border: Border.all(color: c.outline),
        ),
        child: Icon(icon, size: 18, color: c.textPrimary),
      ),
    );
  }
}
