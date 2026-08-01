import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_config.dart';
import '../core/theme/app_palette.dart';
import '../core/utils/day_key.dart';
import '../data/local_store.dart';
import '../data/models/achievement.dart';
import '../data/models/habit.dart';
import '../data/models/habit_log.dart';
import '../data/models/hen_rank.dart';
import '../data/models/journal_entry.dart';
import '../data/models/profile.dart';

/// A habit paired with the log for the day currently being rendered.
@immutable
class HabitToday {
  const HabitToday({required this.habit, required this.log});

  final Habit habit;
  final HabitLog? log;

  int get value => log?.value ?? 0;

  int get target => habit.effectiveTarget;

  bool get isComplete => value >= target;

  double get progress => target <= 0 ? 0 : (value / target).clamp(0.0, 1.0);
}

@immutable
class DaySummary {
  const DaySummary({
    required this.day,
    required this.scheduled,
    required this.completed,
  });

  final DateTime day;
  final int scheduled;
  final int completed;

  bool get isPerfect => scheduled > 0 && completed >= scheduled;

  double get ratio => scheduled <= 0 ? 0 : (completed / scheduled).clamp(0.0, 1.0);
}

class AppState extends ChangeNotifier {
  AppState(this._store) {
    _load();
  }

  final LocalStore _store;

  List<Habit> _habits = <Habit>[];
  Map<String, HabitLog> _logs = <String, HabitLog>{};
  Map<String, JournalEntry> _journal = <String, JournalEntry>{};
  Profile _profile = Profile.initial();
  Set<String> _unlocked = <String>{};

  ThemeMode _themeMode = ThemeMode.system;
  int _accentIndex = 1;
  bool _haptics = true;
  bool _celebrate = true;
  bool _mondayFirst = true;
  bool _hideCompleted = false;
  int _weeklySprintTarget = 21;
  bool _onboarded = false;

  bool _ready = false;

  // ── getters ───────────────────────────────────────────────────────────────
  bool get ready => _ready;
  bool get onboarded => _onboarded;
  Profile get profile => _profile;
  ThemeMode get themeMode => _themeMode;
  int get accentIndex => _accentIndex;
  Color get accentColor => HabitPalette.at(_accentIndex);
  bool get haptics => _haptics;
  bool get celebrate => _celebrate;
  bool get mondayFirst => _mondayFirst;
  bool get hideCompleted => _hideCompleted;
  int get weeklySprintTarget => _weeklySprintTarget;
  int get firstWeekday => _mondayFirst ? DateTime.monday : DateTime.sunday;

  List<Habit> get habits =>
      _habits.where((h) => !h.archived).toList(growable: false);

  List<Habit> get archivedHabits =>
      _habits.where((h) => h.archived).toList(growable: false);

  List<Habit> get allHabits => List<Habit>.unmodifiable(_habits);

  Map<String, JournalEntry> get journal => Map<String, JournalEntry>.unmodifiable(_journal);

  // ── bootstrap ─────────────────────────────────────────────────────────────
  void _load() {
    _habits = _store.readHabits();
    _logs = _store.readLogs();
    _journal = _store.readJournal();
    _profile = _store.readProfile();
    _unlocked = _store.readUnlocked();
    _onboarded = _store.onboarded;

    final settings = _store.readSettings();
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == settings['themeMode'],
      orElse: () => ThemeMode.system,
    );
    _accentIndex = (settings['accentIndex'] as num?)?.toInt() ?? 1;
    _haptics = settings['haptics'] as bool? ?? true;
    _celebrate = settings['celebrate'] as bool? ?? true;
    _mondayFirst = settings['mondayFirst'] as bool? ?? true;
    _hideCompleted = settings['hideCompleted'] as bool? ?? false;
    _weeklySprintTarget = (settings['sprintTarget'] as num?)?.toInt() ?? 21;

    _ready = true;
    notifyListeners();
  }

  Future<void> _persistSettings() => _store.writeSettings(<String, dynamic>{
        'themeMode': _themeMode.name,
        'accentIndex': _accentIndex,
        'haptics': _haptics,
        'celebrate': _celebrate,
        'mondayFirst': _mondayFirst,
        'hideCompleted': _hideCompleted,
        'sprintTarget': _weeklySprintTarget,
      });

  void _tap() {
    if (_haptics) HapticFeedback.selectionClick();
  }

  // ── settings mutations ────────────────────────────────────────────────────
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _persistSettings();
  }

  Future<void> setAccentIndex(int index) async {
    _accentIndex = index;
    _tap();
    notifyListeners();
    await _persistSettings();
  }

  Future<void> setHaptics(bool value) async {
    _haptics = value;
    notifyListeners();
    await _persistSettings();
  }

  Future<void> setCelebrate(bool value) async {
    _celebrate = value;
    notifyListeners();
    await _persistSettings();
  }

  Future<void> setMondayFirst(bool value) async {
    _mondayFirst = value;
    notifyListeners();
    await _persistSettings();
  }

  Future<void> setHideCompleted(bool value) async {
    _hideCompleted = value;
    notifyListeners();
    await _persistSettings();
  }

  Future<void> setWeeklySprintTarget(int value) async {
    _weeklySprintTarget = value.clamp(3, 200);
    notifyListeners();
    await _persistSettings();
  }

  Future<void> completeOnboarding() async {
    _onboarded = true;
    notifyListeners();
    await _store.setOnboarded(true);
  }

  // ── profile ───────────────────────────────────────────────────────────────
  Future<void> updateProfile(Profile next) async {
    _profile = next;
    notifyListeners();
    await _store.writeProfile(next);
  }

  Future<void> clearAvatar() async {
    final path = _profile.avatarPath;
    if (path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } on FileSystemException {
          // A stale avatar file is harmless; keep the profile update going.
        }
      }
    }
    await updateProfile(_profile.copyWith(avatarPath: ''));
  }

  // ── habits ────────────────────────────────────────────────────────────────
  Habit? habitById(String id) {
    for (final h in _habits) {
      if (h.id == id) return h;
    }
    return null;
  }

  Future<void> upsertHabit(Habit habit) async {
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index >= 0) {
      _habits[index] = habit;
    } else {
      _habits.add(habit);
    }
    _tap();
    notifyListeners();
    await _store.writeHabits(_habits);
    await _refreshUnlocked();
  }

  Future<void> setArchived(String habitId, bool archived) async {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index < 0) return;
    _habits[index] = _habits[index].copyWith(archived: archived);
    notifyListeners();
    await _store.writeHabits(_habits);
  }

  Future<void> deleteHabit(String habitId) async {
    _habits.removeWhere((h) => h.id == habitId);
    _logs.removeWhere((key, value) => value.habitId == habitId);
    notifyListeners();
    await _store.writeHabits(_habits);
    await _store.writeLogs(_logs);
  }

  Future<void> reorderHabits(int oldIndex, int newIndex) async {
    final active = habits;
    if (oldIndex < 0 || oldIndex >= active.length) return;
    final moved = active[oldIndex];
    final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
    _habits.remove(moved);
    final insertAt = target.clamp(0, _habits.length);
    _habits.insert(insertAt, moved);
    notifyListeners();
    await _store.writeHabits(_habits);
  }

  // ── logs ──────────────────────────────────────────────────────────────────
  HabitLog? logFor(String habitId, DateTime day) =>
      _logs['$habitId@${DayKey.of(day)}'];

  List<HabitToday> habitsForDay(DateTime day) {
    final normalized = DayKey.normalize(day);
    final result = <HabitToday>[];
    for (final habit in habits) {
      if (!habit.isScheduledOn(normalized)) continue;
      if (normalized.isBefore(DayKey.normalize(habit.createdAt))) continue;
      result.add(HabitToday(habit: habit, log: logFor(habit.id, normalized)));
    }
    return result;
  }

  Future<void> setValue(Habit habit, DateTime day, int value) async {
    final normalized = DayKey.normalize(day);
    final key = '${habit.id}@${DayKey.of(normalized)}';
    final target = habit.effectiveTarget;
    final clamped = value < 0 ? 0 : math.min(value, math.max(target, value));
    final existing = _logs[key];

    if (clamped <= 0) {
      _logs.remove(key);
    } else {
      _logs[key] = (existing ??
              HabitLog(
                habitId: habit.id,
                dayKey: DayKey.of(normalized),
                value: 0,
                target: target,
              ))
          .copyWith(value: clamped, target: target);
    }

    _tap();
    notifyListeners();
    await _store.writeLogs(_logs);
    await _refreshUnlocked();
  }

  Future<void> toggleComplete(Habit habit, DateTime day) async {
    final current = logFor(habit.id, day);
    final done = current != null && current.value >= habit.effectiveTarget;
    await setValue(habit, day, done ? 0 : habit.effectiveTarget);
  }

  Future<void> increment(Habit habit, DateTime day, {int by = 1}) async {
    final current = logFor(habit.id, day)?.value ?? 0;
    await setValue(habit, day, current + by);
  }

  Future<void> setLogNote(Habit habit, DateTime day, String note) async {
    final key = '${habit.id}@${DayKey.of(day)}';
    final existing = _logs[key];
    if (existing == null) return;
    _logs[key] = existing.copyWith(note: note);
    notifyListeners();
    await _store.writeLogs(_logs);
  }

  // ── journal ───────────────────────────────────────────────────────────────
  JournalEntry? journalFor(DateTime day) => _journal[DayKey.of(day)];

  Future<void> saveJournal(JournalEntry entry) async {
    _journal[entry.dayKey] = entry;
    notifyListeners();
    await _store.writeJournal(_journal);
    await _refreshUnlocked();
  }

  Future<void> deleteJournal(String dayKey) async {
    _journal.remove(dayKey);
    notifyListeners();
    await _store.writeJournal(_journal);
  }

  // ── derived metrics ───────────────────────────────────────────────────────
  int streakFor(Habit habit, {DateTime? asOf}) {
    final today = DayKey.normalize(asOf ?? DateTime.now());
    final birth = DayKey.normalize(habit.createdAt);
    var streak = 0;
    for (var i = 0; i < 730; i++) {
      final day = today.subtract(Duration(days: i));
      if (day.isBefore(birth)) break;
      if (!habit.isScheduledOn(day)) continue;
      final log = logFor(habit.id, day);
      if (log != null && log.isComplete) {
        streak++;
        continue;
      }
      // An unfinished today should not wipe out a streak that is still alive.
      if (i == 0) continue;
      break;
    }
    return streak;
  }

  int bestStreakFor(Habit habit) {
    final today = DayKey.today();
    final birth = DayKey.normalize(habit.createdAt);
    var best = 0;
    var running = 0;
    for (var day = birth;
        !day.isAfter(today);
        day = day.add(const Duration(days: 1))) {
      if (!habit.isScheduledOn(day)) continue;
      final log = logFor(habit.id, day);
      if (log != null && log.isComplete) {
        running++;
        best = math.max(best, running);
      } else {
        running = 0;
      }
    }
    return best;
  }

  int completionCountFor(Habit habit) {
    var count = 0;
    for (final log in _logs.values) {
      if (log.habitId == habit.id && log.isComplete) count++;
    }
    return count;
  }

  int scheduledCountFor(Habit habit) {
    final today = DayKey.today();
    final birth = DayKey.normalize(habit.createdAt);
    var count = 0;
    for (var day = birth;
        !day.isAfter(today);
        day = day.add(const Duration(days: 1))) {
      if (habit.isScheduledOn(day)) count++;
    }
    return count;
  }

  double consistencyFor(Habit habit) {
    final scheduled = scheduledCountFor(habit);
    if (scheduled == 0) return 0;
    return completionCountFor(habit) / scheduled;
  }

  int get totalCompletions =>
      _logs.values.where((log) => log.isComplete).length;

  int get totalMetres {
    var metres = 0;
    final byId = <String, Habit>{for (final h in _habits) h.id: h};
    for (final log in _logs.values) {
      if (!log.isComplete) continue;
      final habit = byId[log.habitId];
      final multiplier = habit?.difficulty.multiplier ?? 1;
      metres += AppConfig.metresPerCompletion * multiplier;
    }
    return metres;
  }

  String get distanceLabel {
    final metres = totalMetres;
    if (metres < 1000) return '$metres m';
    return '${(metres / 1000).toStringAsFixed(metres < 10000 ? 2 : 1)} km';
  }

  HenRank get rank => HenRank.forDistance(totalMetres);

  double get rankProgress => rank.progressFrom(totalMetres);

  int get level => 1 + (totalCompletions ~/ 12);

  double get levelProgress => (totalCompletions % 12) / 12;

  int get longestStreak {
    var best = 0;
    for (final habit in _habits) {
      best = math.max(best, bestStreakFor(habit));
    }
    return best;
  }

  int get currentBestStreak {
    var best = 0;
    for (final habit in habits) {
      best = math.max(best, streakFor(habit));
    }
    return best;
  }

  DaySummary summaryFor(DateTime day) {
    final items = habitsForDay(day);
    return DaySummary(
      day: DayKey.normalize(day),
      scheduled: items.length,
      completed: items.where((i) => i.isComplete).length,
    );
  }

  List<DaySummary> summariesFor(List<DateTime> days) =>
      days.map(summaryFor).toList(growable: false);

  int get perfectDays {
    final today = DayKey.today();
    DateTime earliest = today;
    for (final habit in _habits) {
      final birth = DayKey.normalize(habit.createdAt);
      if (birth.isBefore(earliest)) earliest = birth;
    }
    var count = 0;
    for (var day = earliest;
        !day.isAfter(today);
        day = day.add(const Duration(days: 1))) {
      if (summaryFor(day).isPerfect) count++;
    }
    return count;
  }

  int get weeklyCompletions {
    final week = DayKey.weekOf(DateTime.now(), firstWeekday: firstWeekday);
    var total = 0;
    for (final day in week) {
      if (day.isAfter(DayKey.today())) continue;
      total += summaryFor(day).completed;
    }
    return total;
  }

  double get weeklySprintProgress => _weeklySprintTarget <= 0
      ? 0
      : (weeklyCompletions / _weeklySprintTarget).clamp(0.0, 1.0);

  Set<HabitCategory> get usedCategories =>
      habits.map((h) => h.category).toSet();

  Map<HabitCategory, int> get completionsByCategory {
    final byId = <String, Habit>{for (final h in _habits) h.id: h};
    final result = <HabitCategory, int>{};
    for (final log in _logs.values) {
      if (!log.isComplete) continue;
      final habit = byId[log.habitId];
      if (habit == null) continue;
      result.update(habit.category, (v) => v + 1, ifAbsent: () => 1);
    }
    return result;
  }

  /// Completions per ISO weekday (1–7) across all recorded history.
  Map<int, int> get completionsByWeekday {
    final result = <int, int>{for (var i = 1; i <= 7; i++) i: 0};
    for (final log in _logs.values) {
      if (!log.isComplete) continue;
      final day = DayKey.parse(log.dayKey);
      result.update(day.weekday, (v) => v + 1);
    }
    return result;
  }

  // ── achievements ──────────────────────────────────────────────────────────
  /// The handful of aggregates every badge is derived from. Computing them
  /// once keeps the whole catalogue a single pass over the logs.
  List<AchievementProgress> get achievements {
    final completions = totalCompletions;
    final streak = longestStreak;
    final metres = totalMetres;
    final perfect = perfectDays;
    final categories = usedCategories.length;
    final entries = _journal.length;
    final active = habits.length;

    int valueFor(String id) {
      switch (id) {
        case 'first_step':
        case 'ten_checks':
        case 'fifty_checks':
        case 'two_hundred_checks':
          return completions;
        case 'streak_3':
        case 'streak_7':
        case 'streak_30':
        case 'streak_100':
          return streak;
        case 'distance_5k':
        case 'distance_25k':
        case 'distance_100k':
          return metres;
        case 'perfect_day':
        case 'perfect_week':
          return perfect;
        case 'variety_3':
        case 'variety_6':
          return categories;
        case 'journal_7':
        case 'journal_30':
          return entries;
        case 'habits_5':
          return active;
      }
      return 0;
    }

    return AchievementCatalog.all
        .map(
          (a) => AchievementProgress(achievement: a, current: valueFor(a.id)),
        )
        .toList(growable: false);
  }

  int get unlockedCount => achievements.where((a) => a.unlocked).length;

  /// Achievements crossed since the last check, so the UI can celebrate them.
  List<Achievement> pendingCelebrations = <Achievement>[];

  Future<void> _refreshUnlocked() async {
    final nowUnlocked =
        achievements.where((a) => a.unlocked).map((a) => a.achievement.id).toSet();
    final fresh = nowUnlocked.difference(_unlocked);
    if (fresh.isEmpty) return;
    pendingCelebrations = AchievementCatalog.all
        .where((a) => fresh.contains(a.id))
        .toList(growable: false);
    _unlocked = nowUnlocked;
    notifyListeners();
    await _store.writeUnlocked(_unlocked);
  }

  void consumeCelebrations() {
    if (pendingCelebrations.isEmpty) return;
    pendingCelebrations = <Achievement>[];
  }

  // ── data management ───────────────────────────────────────────────────────
  Future<void> resetEverything() async {
    await _store.wipe();
    _habits = <Habit>[];
    _logs = <String, HabitLog>{};
    _journal = <String, JournalEntry>{};
    _profile = Profile.initial();
    _unlocked = <String>{};
    notifyListeners();
  }

  Future<void> seedStarterHabits() async {
    if (_habits.isNotEmpty) return;
    final now = DateTime.now();
    const everyDay = <int>{1, 2, 3, 4, 5, 6, 7};
    _habits = <Habit>[
      Habit(
        id: 'seed-move',
        title: 'Morning run',
        category: HabitCategory.movement,
        goalType: HabitGoalType.duration,
        difficulty: HabitDifficulty.hard,
        colorIndex: 1,
        targetValue: 20,
        unit: 'min',
        weekdays: const <int>{1, 3, 5},
        createdAt: now,
        note: 'Out the door before the excuses wake up.',
      ),
      Habit(
        id: 'seed-water',
        title: 'Drink water',
        category: HabitCategory.health,
        goalType: HabitGoalType.quantity,
        difficulty: HabitDifficulty.easy,
        colorIndex: 7,
        targetValue: 8,
        unit: 'glasses',
        weekdays: everyDay,
        createdAt: now,
      ),
      Habit(
        id: 'seed-read',
        title: 'Read 10 pages',
        category: HabitCategory.mind,
        goalType: HabitGoalType.check,
        difficulty: HabitDifficulty.normal,
        colorIndex: 6,
        targetValue: 1,
        unit: 'times',
        weekdays: everyDay,
        createdAt: now,
      ),
    ];
    notifyListeners();
    await _store.writeHabits(_habits);
  }

  Map<String, dynamic> exportSnapshot() => <String, dynamic>{
        'app': AppConfig.appName,
        'version': AppConfig.version,
        'exportedAt': DateTime.now().toIso8601String(),
        'profile': _profile.toJson(),
        'habits': _habits.map((h) => h.toJson()).toList(),
        'logs': _logs.map((k, v) => MapEntry(k, v.toJson())),
        'journal': _journal.map((k, v) => MapEntry(k, v.toJson())),
      };
}
