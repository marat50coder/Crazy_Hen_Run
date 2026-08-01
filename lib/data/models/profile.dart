import 'package:flutter/foundation.dart';

@immutable
class Profile {
  const Profile({
    required this.name,
    required this.avatarPath,
    required this.tagline,
    required this.joinedAt,
    required this.dailyGoal,
  });

  final String name;
  final String avatarPath;
  final String tagline;
  final DateTime joinedAt;

  /// How many habits the runner wants to close every day.
  final int dailyGoal;

  static Profile initial() => Profile(
        name: 'Runner',
        avatarPath: '',
        tagline: 'Chasing a better routine',
        joinedAt: DateTime.now(),
        dailyGoal: 3,
      );

  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'CH';
    if (parts.length == 1) {
      final single = parts.first;
      return (single.length >= 2 ? single.substring(0, 2) : single).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Profile copyWith({
    String? name,
    String? avatarPath,
    String? tagline,
    int? dailyGoal,
  }) =>
      Profile(
        name: name ?? this.name,
        avatarPath: avatarPath ?? this.avatarPath,
        tagline: tagline ?? this.tagline,
        joinedAt: joinedAt,
        dailyGoal: dailyGoal ?? this.dailyGoal,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'avatarPath': avatarPath,
        'tagline': tagline,
        'joinedAt': joinedAt.toIso8601String(),
        'dailyGoal': dailyGoal,
      };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        name: json['name'] as String? ?? 'Runner',
        avatarPath: json['avatarPath'] as String? ?? '',
        tagline: json['tagline'] as String? ?? 'Chasing a better routine',
        joinedAt:
            DateTime.tryParse(json['joinedAt'] as String? ?? '') ?? DateTime.now(),
        dailyGoal: (json['dailyGoal'] as num?)?.toInt() ?? 3,
      );
}
