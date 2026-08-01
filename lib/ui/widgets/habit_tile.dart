import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/habit.dart';
import '../../state/app_state.dart';
import 'progress.dart';

class HabitTile extends StatelessWidget {
  const HabitTile({
    super.key,
    required this.entry,
    required this.streak,
    required this.onTap,
    required this.onToggle,
    required this.onIncrement,
    required this.onDecrement,
  });

  final HabitToday entry;
  final int streak;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final habit = entry.habit;
    final tone = HabitPalette.at(habit.colorIndex);
    final done = entry.isComplete;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: done ? tone.withValues(alpha: 0.10) : c.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: done ? tone.withValues(alpha: 0.32) : c.outline,
        ),
        boxShadow: done
            ? null
            : <BoxShadow>[
                BoxShadow(
                  color: c.shadow,
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                  spreadRadius: -10,
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                _CategoryBadge(habit: habit, tone: tone, muted: done),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        habit.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleMedium?.copyWith(
                          decoration:
                              done ? TextDecoration.lineThrough : null,
                          decorationColor: c.textSecondary,
                          color: done ? c.textSecondary : c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: <Widget>[
                          Text(
                            habit.goalType == HabitGoalType.check
                                ? habit.category.label
                                : '${entry.value}/${entry.target} ${habit.goalType == HabitGoalType.duration ? 'min' : habit.unit}',
                            style: context.text.bodySmall,
                          ),
                          if (streak > 0) ...<Widget>[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 13,
                              color: Brand.yolk,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '$streak',
                              style: context.text.bodySmall?.copyWith(
                                color: Brand.yolk,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (habit.goalType != HabitGoalType.check) ...<Widget>[
                        const SizedBox(height: 8),
                        TrackBar(
                          value: entry.progress,
                          height: 6,
                          color: tone,
                          trackColor: c.surfaceMuted,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (habit.goalType == HabitGoalType.check)
                  _CheckButton(done: done, tone: tone, onTap: onToggle)
                else
                  _Stepper(
                    entry: entry,
                    tone: tone,
                    onIncrement: onIncrement,
                    onDecrement: onDecrement,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({
    required this.habit,
    required this.tone,
    required this.muted,
  });

  final Habit habit;
  final Color tone;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: muted ? 0.16 : 0.14),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Icon(habit.category.icon, size: 22, color: tone),
    );
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({
    required this.done,
    required this.tone,
    required this.onTap,
  });

  final bool done;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: done ? tone : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: done ? tone : c.outlineStrong,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.check_rounded,
          size: 22,
          color: done ? Colors.white : c.outlineStrong,
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.entry,
    required this.tone,
    required this.onIncrement,
    required this.onDecrement,
  });

  final HabitToday entry;
  final Color tone;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: c.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _StepButton(
            icon: Icons.add_rounded,
            color: tone,
            onTap: onIncrement,
          ),
          Text(
            '${entry.value}',
            style: context.text.labelMedium?.copyWith(color: c.textPrimary),
          ),
          _StepButton(
            icon: Icons.remove_rounded,
            color: c.textSecondary,
            onTap: onDecrement,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 34,
        height: 26,
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }
}
