import 'package:flutter/material.dart';

enum AchievementGroup {
  distance('Distance'),
  streak('Streaks'),
  consistency('Consistency'),
  variety('Variety'),
  care('Self care');

  const AchievementGroup(this.label);

  final String label;
}

@immutable
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.group,
    required this.icon,
    required this.threshold,
    required this.color,
  });

  final String id;
  final String title;
  final String description;
  final AchievementGroup group;
  final IconData icon;
  final int threshold;
  final Color color;
}

@immutable
class AchievementProgress {
  const AchievementProgress({
    required this.achievement,
    required this.current,
  });

  final Achievement achievement;
  final int current;

  bool get unlocked => current >= achievement.threshold;

  double get ratio => achievement.threshold <= 0
      ? 1
      : (current / achievement.threshold).clamp(0.0, 1.0);
}

class AchievementCatalog {
  const AchievementCatalog._();

  static const List<Achievement> all = <Achievement>[
    Achievement(
      id: 'first_step',
      title: 'First Step',
      description: 'Complete your very first habit.',
      group: AchievementGroup.consistency,
      icon: Icons.flag_rounded,
      threshold: 1,
      color: Color(0xFF8FD13F),
    ),
    Achievement(
      id: 'ten_checks',
      title: 'Warm Up',
      description: 'Complete 10 habits in total.',
      group: AchievementGroup.consistency,
      icon: Icons.local_fire_department_rounded,
      threshold: 10,
      color: Color(0xFFFFC72C),
    ),
    Achievement(
      id: 'fifty_checks',
      title: 'Cruise Control',
      description: 'Complete 50 habits in total.',
      group: AchievementGroup.consistency,
      icon: Icons.speed_rounded,
      threshold: 50,
      color: Color(0xFFF6A21E),
    ),
    Achievement(
      id: 'two_hundred_checks',
      title: 'Unstoppable',
      description: 'Complete 200 habits in total.',
      group: AchievementGroup.consistency,
      icon: Icons.rocket_launch_rounded,
      threshold: 200,
      color: Color(0xFFE4443A),
    ),
    Achievement(
      id: 'streak_3',
      title: 'Three in a Row',
      description: 'Hold a 3 day streak on any habit.',
      group: AchievementGroup.streak,
      icon: Icons.filter_3_rounded,
      threshold: 3,
      color: Color(0xFF6FB3E0),
    ),
    Achievement(
      id: 'streak_7',
      title: 'Full Lap',
      description: 'Hold a 7 day streak on any habit.',
      group: AchievementGroup.streak,
      icon: Icons.calendar_view_week_rounded,
      threshold: 7,
      color: Color(0xFF2F7D4F),
    ),
    Achievement(
      id: 'streak_30',
      title: 'Marathon Mind',
      description: 'Hold a 30 day streak on any habit.',
      group: AchievementGroup.streak,
      icon: Icons.emoji_events_rounded,
      threshold: 30,
      color: Color(0xFF9B8CE0),
    ),
    Achievement(
      id: 'streak_100',
      title: 'Iron Feather',
      description: 'Hold a 100 day streak on any habit.',
      group: AchievementGroup.streak,
      icon: Icons.shield_rounded,
      threshold: 100,
      color: Color(0xFF7A5C3E),
    ),
    Achievement(
      id: 'distance_5k',
      title: '5 km Runner',
      description: 'Cover 5 km of habit distance.',
      group: AchievementGroup.distance,
      icon: Icons.directions_walk_rounded,
      threshold: 5000,
      color: Color(0xFF8FD13F),
    ),
    Achievement(
      id: 'distance_25k',
      title: '25 km Runner',
      description: 'Cover 25 km of habit distance.',
      group: AchievementGroup.distance,
      icon: Icons.directions_run_rounded,
      threshold: 25000,
      color: Color(0xFF2F7D4F),
    ),
    Achievement(
      id: 'distance_100k',
      title: '100 km Legend',
      description: 'Cover 100 km of habit distance.',
      group: AchievementGroup.distance,
      icon: Icons.terrain_rounded,
      threshold: 100000,
      color: Color(0xFFFF8A5B),
    ),
    Achievement(
      id: 'perfect_day',
      title: 'Perfect Day',
      description: 'Close every scheduled habit in a single day.',
      group: AchievementGroup.consistency,
      icon: Icons.check_circle_rounded,
      threshold: 1,
      color: Color(0xFF3F9D5B),
    ),
    Achievement(
      id: 'perfect_week',
      title: 'Perfect Week',
      description: 'Reach 7 perfect days.',
      group: AchievementGroup.consistency,
      icon: Icons.workspace_premium_rounded,
      threshold: 7,
      color: Color(0xFFFFC72C),
    ),
    Achievement(
      id: 'variety_3',
      title: 'Well Rounded',
      description: 'Track habits from 3 different categories.',
      group: AchievementGroup.variety,
      icon: Icons.category_rounded,
      threshold: 3,
      color: Color(0xFF17BEBB),
    ),
    Achievement(
      id: 'variety_6',
      title: 'Full Coop',
      description: 'Track habits from 6 different categories.',
      group: AchievementGroup.variety,
      icon: Icons.grid_view_rounded,
      threshold: 6,
      color: Color(0xFF9B8CE0),
    ),
    Achievement(
      id: 'journal_7',
      title: 'Inner Voice',
      description: 'Write 7 journal entries.',
      group: AchievementGroup.care,
      icon: Icons.edit_note_rounded,
      threshold: 7,
      color: Color(0xFFF7A8B8),
    ),
    Achievement(
      id: 'journal_30',
      title: 'Open Book',
      description: 'Write 30 journal entries.',
      group: AchievementGroup.care,
      icon: Icons.auto_stories_rounded,
      threshold: 30,
      color: Color(0xFFE4443A),
    ),
    Achievement(
      id: 'habits_5',
      title: 'Flock Builder',
      description: 'Keep 5 active habits at once.',
      group: AchievementGroup.variety,
      icon: Icons.dashboard_customize_rounded,
      threshold: 5,
      color: Color(0xFF6FB3E0),
    ),
  ];
}
