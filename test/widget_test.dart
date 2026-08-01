import 'package:crazy_hen_run/core/utils/day_key.dart';
import 'package:crazy_hen_run/data/models/habit.dart';
import 'package:crazy_hen_run/data/models/hen_rank.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rank thresholds map distance to the right hen', () {
    expect(HenRank.forDistance(0), HenRank.chick);
    expect(HenRank.forDistance(4999), HenRank.chick);
    expect(HenRank.forDistance(5000), HenRank.hen);
    expect(HenRank.forDistance(300000), HenRank.legend);
  });

  test('habit schedule respects selected weekdays', () {
    final habit = Habit(
      id: 'a',
      title: 'Run',
      category: HabitCategory.movement,
      goalType: HabitGoalType.check,
      difficulty: HabitDifficulty.normal,
      colorIndex: 0,
      targetValue: 1,
      unit: 'times',
      weekdays: const <int>{1, 3, 5},
      createdAt: DateTime(2026, 1, 1),
    );

    expect(habit.isScheduledOn(DateTime(2026, 1, 5)), isTrue); // Monday
    expect(habit.isScheduledOn(DateTime(2026, 1, 6)), isFalse); // Tuesday
  });

  test('day keys round trip', () {
    final day = DateTime(2026, 7, 31);
    expect(DayKey.parse(DayKey.of(day)), day);
  });
}
