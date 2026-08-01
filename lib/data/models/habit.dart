import 'package:flutter/material.dart';

enum HabitCategory {
  movement('Movement', Icons.directions_run_rounded),
  mind('Mind', Icons.self_improvement_rounded),
  health('Health', Icons.favorite_rounded),
  nutrition('Nutrition', Icons.restaurant_rounded),
  focus('Focus', Icons.bolt_rounded),
  rest('Rest', Icons.nightlight_round),
  social('Social', Icons.groups_rounded),
  money('Money', Icons.savings_rounded);

  const HabitCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  static HabitCategory fromName(String? name) => HabitCategory.values.firstWhere(
        (c) => c.name == name,
        orElse: () => HabitCategory.movement,
      );
}

enum HabitGoalType {
  /// A single tap marks the day as done.
  check('Simple check'),

  /// Counts up to a numeric target, e.g. 8 glasses of water.
  quantity('Counter'),

  /// Counts minutes towards a target duration.
  duration('Timer');

  const HabitGoalType(this.label);

  final String label;

  static HabitGoalType fromName(String? name) => HabitGoalType.values.firstWhere(
        (t) => t.name == name,
        orElse: () => HabitGoalType.check,
      );
}

enum HabitDifficulty {
  easy('Jog', 1),
  normal('Run', 2),
  hard('Sprint', 3);

  const HabitDifficulty(this.label, this.multiplier);

  final String label;
  final int multiplier;

  static HabitDifficulty fromName(String? name) => HabitDifficulty.values.firstWhere(
        (d) => d.name == name,
        orElse: () => HabitDifficulty.normal,
      );
}

@immutable
class Habit {
  const Habit({
    required this.id,
    required this.title,
    required this.category,
    required this.goalType,
    required this.difficulty,
    required this.colorIndex,
    required this.targetValue,
    required this.unit,
    required this.weekdays,
    required this.createdAt,
    this.note = '',
    this.preferredMinuteOfDay,
    this.archived = false,
  });

  final String id;
  final String title;
  final HabitCategory category;
  final HabitGoalType goalType;
  final HabitDifficulty difficulty;
  final int colorIndex;

  /// Target for [HabitGoalType.quantity] / [HabitGoalType.duration].
  final int targetValue;
  final String unit;

  /// ISO weekdays (1 = Monday … 7 = Sunday) the habit is scheduled on.
  final Set<int> weekdays;

  final DateTime createdAt;
  final String note;
  final int? preferredMinuteOfDay;
  final bool archived;

  bool get isDaily => weekdays.length == 7;

  bool isScheduledOn(DateTime day) => weekdays.contains(day.weekday);

  int get effectiveTarget => goalType == HabitGoalType.check ? 1 : targetValue;

  String get targetLabel {
    switch (goalType) {
      case HabitGoalType.check:
        return 'Once a day';
      case HabitGoalType.quantity:
        return '$targetValue $unit';
      case HabitGoalType.duration:
        return '$targetValue min';
    }
  }

  Habit copyWith({
    String? title,
    HabitCategory? category,
    HabitGoalType? goalType,
    HabitDifficulty? difficulty,
    int? colorIndex,
    int? targetValue,
    String? unit,
    Set<int>? weekdays,
    String? note,
    int? preferredMinuteOfDay,
    bool clearPreferredTime = false,
    bool? archived,
  }) {
    return Habit(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      goalType: goalType ?? this.goalType,
      difficulty: difficulty ?? this.difficulty,
      colorIndex: colorIndex ?? this.colorIndex,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      weekdays: weekdays ?? this.weekdays,
      createdAt: createdAt,
      note: note ?? this.note,
      preferredMinuteOfDay: clearPreferredTime
          ? null
          : (preferredMinuteOfDay ?? this.preferredMinuteOfDay),
      archived: archived ?? this.archived,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'category': category.name,
        'goalType': goalType.name,
        'difficulty': difficulty.name,
        'colorIndex': colorIndex,
        'targetValue': targetValue,
        'unit': unit,
        'weekdays': weekdays.toList()..sort(),
        'createdAt': createdAt.toIso8601String(),
        'note': note,
        'preferredMinuteOfDay': preferredMinuteOfDay,
        'archived': archived,
      };

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Habit',
      category: HabitCategory.fromName(json['category'] as String?),
      goalType: HabitGoalType.fromName(json['goalType'] as String?),
      difficulty: HabitDifficulty.fromName(json['difficulty'] as String?),
      colorIndex: (json['colorIndex'] as num?)?.toInt() ?? 0,
      targetValue: (json['targetValue'] as num?)?.toInt() ?? 1,
      unit: json['unit'] as String? ?? 'times',
      weekdays: ((json['weekdays'] as List<dynamic>?) ?? const <int>[1, 2, 3, 4, 5, 6, 7])
          .map((e) => (e as num).toInt())
          .toSet(),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      note: json['note'] as String? ?? '',
      preferredMinuteOfDay: (json['preferredMinuteOfDay'] as num?)?.toInt(),
      archived: json['archived'] as bool? ?? false,
    );
  }
}
