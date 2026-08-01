import 'package:flutter/foundation.dart';

@immutable
class HabitLog {
  const HabitLog({
    required this.habitId,
    required this.dayKey,
    required this.value,
    required this.target,
    this.note = '',
  });

  final String habitId;
  final String dayKey;
  final int value;
  final int target;
  final String note;

  bool get isComplete => value >= target && target > 0;

  double get progress => target <= 0 ? 0 : (value / target).clamp(0.0, 1.0);

  String get compositeKey => '$habitId@$dayKey';

  HabitLog copyWith({int? value, int? target, String? note}) => HabitLog(
        habitId: habitId,
        dayKey: dayKey,
        value: value ?? this.value,
        target: target ?? this.target,
        note: note ?? this.note,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'habitId': habitId,
        'dayKey': dayKey,
        'value': value,
        'target': target,
        'note': note,
      };

  factory HabitLog.fromJson(Map<String, dynamic> json) => HabitLog(
        habitId: json['habitId'] as String,
        dayKey: json['dayKey'] as String,
        value: (json['value'] as num?)?.toInt() ?? 0,
        target: (json['target'] as num?)?.toInt() ?? 1,
        note: json['note'] as String? ?? '',
      );
}
