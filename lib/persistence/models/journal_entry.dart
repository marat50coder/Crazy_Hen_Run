import 'package:flutter/material.dart';

enum Mood {
  rough('Rough', '😵', Color(0xFFE4443A)),
  low('Low', '😕', Color(0xFFF6A21E)),
  okay('Okay', '🙂', Color(0xFFFFC72C)),
  good('Good', '😄', Color(0xFF8FD13F)),
  flying('Flying', '🚀', Color(0xFF2F7D4F));

  const Mood(this.label, this.emoji, this.color);

  final String label;
  final String emoji;
  final Color color;

  int get score => index + 1;

  static Mood fromName(String? name) => Mood.values.firstWhere(
        (m) => m.name == name,
        orElse: () => Mood.okay,
      );
}

@immutable
class JournalEntry {
  const JournalEntry({
    required this.dayKey,
    required this.mood,
    required this.note,
    required this.energy,
  });

  final String dayKey;
  final Mood mood;
  final String note;

  /// 1–5 self reported energy level.
  final int energy;

  JournalEntry copyWith({Mood? mood, String? note, int? energy}) => JournalEntry(
        dayKey: dayKey,
        mood: mood ?? this.mood,
        note: note ?? this.note,
        energy: energy ?? this.energy,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'dayKey': dayKey,
        'mood': mood.name,
        'note': note,
        'energy': energy,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        dayKey: json['dayKey'] as String,
        mood: Mood.fromName(json['mood'] as String?),
        note: json['note'] as String? ?? '',
        energy: (json['energy'] as num?)?.toInt() ?? 3,
      );
}
