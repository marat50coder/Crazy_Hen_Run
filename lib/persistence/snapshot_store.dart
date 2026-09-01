import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/habit.dart';
import 'models/habit_log.dart';
import 'models/interval_plan.dart';
import 'models/journal_entry.dart';
import 'models/profile.dart';
import 'models/run_session.dart';

/// Everything the app persists lives on the device only — no network, no
/// account, no sync. A single [SharedPreferences] instance backs JSON blobs.
class SnapshotStore {
  SnapshotStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _kHabits = 'hyard.habits.v2';
  static const String _kLogs = 'hyard.logs.v2';
  static const String _kJournal = 'hyard.journal.v2';
  static const String _kProfile = 'hyard.profile.v2';
  static const String _kSettings = 'hyard.settings.v2';
  static const String _kUnlocked = 'hyard.unlocked.v2';
  static const String _kOnboarded = 'hyard.onboarded.v2';
  static const String _kRuns = 'hyard.runs.v2';
  static const String _kStepDays = 'hyard.stepdays.v2';
  static const String _kStepBaseline = 'hyard.stepbaseline.v2';
  static const String _kPlans = 'hyard.plans.v2';
  static const String _kRunSettings = 'hyard.runsettings.v2';

  /// Pre-1.0.2 key names. Read as fallback so an existing install keeps data.
  static const String _legacyHabits = 'chr.habits.v1';
  static const String _legacyLogs = 'chr.logs.v1';
  static const String _legacyJournal = 'chr.journal.v1';
  static const String _legacyProfile = 'chr.profile.v1';
  static const String _legacySettings = 'chr.settings.v1';
  static const String _legacyUnlocked = 'chr.unlocked.v1';
  static const String _legacyOnboarded = 'chr.onboarded.v1';
  static const String _legacyRuns = 'chr.runs.v1';
  static const String _legacyStepDays = 'chr.stepdays.v1';
  static const String _legacyStepBaseline = 'chr.stepbaseline.v1';
  static const String _legacyPlans = 'chr.plans.v1';
  static const String _legacyRunSettings = 'chr.runsettings.v1';

  String? _readString(String current, String legacy) =>
      _prefs.getString(current) ?? _prefs.getString(legacy);

  List<String>? _readList(String current, String legacy) =>
      _prefs.getStringList(current) ?? _prefs.getStringList(legacy);

  static Future<SnapshotStore> open() async =>
      SnapshotStore(await SharedPreferences.getInstance());

  // ── habits ────────────────────────────────────────────────────────────────
  List<Habit> readHabits() {
    final raw = _readString(_kHabits, _legacyHabits);
    if (raw == null || raw.isEmpty) return <Habit>[];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => Habit.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> writeHabits(List<Habit> habits) => _prefs.setString(
        _kHabits,
        jsonEncode(habits.map((h) => h.toJson()).toList()),
      );

  // ── logs ──────────────────────────────────────────────────────────────────
  Map<String, HabitLog> readLogs() {
    final raw = _readString(_kLogs, _legacyLogs);
    if (raw == null || raw.isEmpty) return <String, HabitLog>{};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(
        key,
        HabitLog.fromJson(Map<String, dynamic>.from(value as Map)),
      ),
    );
  }

  Future<void> writeLogs(Map<String, HabitLog> logs) => _prefs.setString(
        _kLogs,
        jsonEncode(logs.map((key, value) => MapEntry(key, value.toJson()))),
      );

  // ── journal ───────────────────────────────────────────────────────────────
  Map<String, JournalEntry> readJournal() {
    final raw = _readString(_kJournal, _legacyJournal);
    if (raw == null || raw.isEmpty) return <String, JournalEntry>{};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(
        key,
        JournalEntry.fromJson(Map<String, dynamic>.from(value as Map)),
      ),
    );
  }

  Future<void> writeJournal(Map<String, JournalEntry> entries) =>
      _prefs.setString(
        _kJournal,
        jsonEncode(entries.map((key, value) => MapEntry(key, value.toJson()))),
      );

  // ── profile ───────────────────────────────────────────────────────────────
  Profile readProfile() {
    final raw = _readString(_kProfile, _legacyProfile);
    if (raw == null || raw.isEmpty) return Profile.initial();
    return Profile.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }

  Future<void> writeProfile(Profile profile) =>
      _prefs.setString(_kProfile, jsonEncode(profile.toJson()));

  // ── settings ──────────────────────────────────────────────────────────────
  Map<String, dynamic> readSettings() {
    final raw = _readString(_kSettings, _legacySettings);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> writeSettings(Map<String, dynamic> settings) =>
      _prefs.setString(_kSettings, jsonEncode(settings));

  // ── achievements ──────────────────────────────────────────────────────────
  Set<String> readUnlocked() =>
      (_readList(_kUnlocked, _legacyUnlocked) ?? const <String>[]).toSet();

  Future<void> writeUnlocked(Set<String> ids) =>
      _prefs.setStringList(_kUnlocked, ids.toList());

  // ── runs ──────────────────────────────────────────────────────────────────
  List<RunSession> readRuns() {
    final raw = _readString(_kRuns, _legacyRuns);
    if (raw == null || raw.isEmpty) return <RunSession>[];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => RunSession.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> writeRuns(List<RunSession> runs) => _prefs.setString(
        _kRuns,
        jsonEncode(runs.map((r) => r.toJson()).toList()),
      );

  // ── step days (dayKey -> steps) ─────────────────────────────────────────────
  Map<String, int> readStepDays() {
    final raw = _readString(_kStepDays, _legacyStepDays);
    if (raw == null || raw.isEmpty) return <String, int>{};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  Future<void> writeStepDays(Map<String, int> days) =>
      _prefs.setString(_kStepDays, jsonEncode(days));

  /// Cumulative sensor reading captured at the start of [dayKey], used to turn
  /// the boot-relative pedometer counter into a per-day figure.
  Map<String, dynamic> readStepBaseline() {
    final raw = _readString(_kStepBaseline, _legacyStepBaseline);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> writeStepBaseline(Map<String, dynamic> data) =>
      _prefs.setString(_kStepBaseline, jsonEncode(data));

  // ── interval plans ──────────────────────────────────────────────────────────
  List<IntervalPlan> readPlans() {
    final raw = _readString(_kPlans, _legacyPlans);
    if (raw == null || raw.isEmpty) return <IntervalPlan>[];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => IntervalPlan.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> writePlans(List<IntervalPlan> plans) => _prefs.setString(
        _kPlans,
        jsonEncode(plans.map((p) => p.toJson()).toList()),
      );

  // ── running settings ──────────────────────────────────────────────────────
  Map<String, dynamic> readRunSettings() {
    final raw = _readString(_kRunSettings, _legacyRunSettings);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> writeRunSettings(Map<String, dynamic> settings) =>
      _prefs.setString(_kRunSettings, jsonEncode(settings));

  // ── onboarding ────────────────────────────────────────────────────────────
  bool get onboarded =>
      _prefs.getBool(_kOnboarded) ?? _prefs.getBool(_legacyOnboarded) ?? false;

  Future<void> setOnboarded(bool value) => _prefs.setBool(_kOnboarded, value);

  Future<void> wipe() async {
    await Future.wait(<Future<void>>[
      _prefs.remove(_kHabits),
      _prefs.remove(_kLogs),
      _prefs.remove(_kJournal),
      _prefs.remove(_kProfile),
      _prefs.remove(_kSettings),
      _prefs.remove(_kUnlocked),
      _prefs.remove(_kOnboarded),
      _prefs.remove(_kRuns),
      _prefs.remove(_kStepDays),
      _prefs.remove(_kStepBaseline),
      _prefs.remove(_kPlans),
      _prefs.remove(_kRunSettings),
      _prefs.remove(_legacyHabits),
      _prefs.remove(_legacyLogs),
      _prefs.remove(_legacyJournal),
      _prefs.remove(_legacyProfile),
      _prefs.remove(_legacySettings),
      _prefs.remove(_legacyUnlocked),
      _prefs.remove(_legacyOnboarded),
      _prefs.remove(_legacyRuns),
      _prefs.remove(_legacyStepDays),
      _prefs.remove(_legacyStepBaseline),
      _prefs.remove(_legacyPlans),
      _prefs.remove(_legacyRunSettings),
    ]);
  }
}
