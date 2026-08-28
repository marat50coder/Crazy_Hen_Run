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

  static const String _kHabits = 'chr.habits.v1';
  static const String _kLogs = 'chr.logs.v1';
  static const String _kJournal = 'chr.journal.v1';
  static const String _kProfile = 'chr.profile.v1';
  static const String _kSettings = 'chr.settings.v1';
  static const String _kUnlocked = 'chr.unlocked.v1';
  static const String _kOnboarded = 'chr.onboarded.v1';
  static const String _kRuns = 'chr.runs.v1';
  static const String _kStepDays = 'chr.stepdays.v1';
  static const String _kStepBaseline = 'chr.stepbaseline.v1';
  static const String _kPlans = 'chr.plans.v1';
  static const String _kRunSettings = 'chr.runsettings.v1';

  static Future<SnapshotStore> open() async =>
      SnapshotStore(await SharedPreferences.getInstance());

  // ── habits ────────────────────────────────────────────────────────────────
  List<Habit> readHabits() {
    final raw = _prefs.getString(_kHabits);
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
    final raw = _prefs.getString(_kLogs);
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
    final raw = _prefs.getString(_kJournal);
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
    final raw = _prefs.getString(_kProfile);
    if (raw == null || raw.isEmpty) return Profile.initial();
    return Profile.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }

  Future<void> writeProfile(Profile profile) =>
      _prefs.setString(_kProfile, jsonEncode(profile.toJson()));

  // ── settings ──────────────────────────────────────────────────────────────
  Map<String, dynamic> readSettings() {
    final raw = _prefs.getString(_kSettings);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> writeSettings(Map<String, dynamic> settings) =>
      _prefs.setString(_kSettings, jsonEncode(settings));

  // ── achievements ──────────────────────────────────────────────────────────
  Set<String> readUnlocked() =>
      (_prefs.getStringList(_kUnlocked) ?? const <String>[]).toSet();

  Future<void> writeUnlocked(Set<String> ids) =>
      _prefs.setStringList(_kUnlocked, ids.toList());

  // ── runs ──────────────────────────────────────────────────────────────────
  List<RunSession> readRuns() {
    final raw = _prefs.getString(_kRuns);
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
    final raw = _prefs.getString(_kStepDays);
    if (raw == null || raw.isEmpty) return <String, int>{};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  Future<void> writeStepDays(Map<String, int> days) =>
      _prefs.setString(_kStepDays, jsonEncode(days));

  /// Cumulative sensor reading captured at the start of [dayKey], used to turn
  /// the boot-relative pedometer counter into a per-day figure.
  Map<String, dynamic> readStepBaseline() {
    final raw = _prefs.getString(_kStepBaseline);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> writeStepBaseline(Map<String, dynamic> data) =>
      _prefs.setString(_kStepBaseline, jsonEncode(data));

  // ── interval plans ──────────────────────────────────────────────────────────
  List<IntervalPlan> readPlans() {
    final raw = _prefs.getString(_kPlans);
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
    final raw = _prefs.getString(_kRunSettings);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> writeRunSettings(Map<String, dynamic> settings) =>
      _prefs.setString(_kRunSettings, jsonEncode(settings));

  // ── onboarding ────────────────────────────────────────────────────────────
  bool get onboarded => _prefs.getBool(_kOnboarded) ?? false;

  Future<void> setOnboarded(bool value) => _prefs.setBool(_kOnboarded, value);

  Future<void> wipe() async {
    await Future.wait(<Future<void>>[
      _prefs.remove(_kHabits),
      _prefs.remove(_kLogs),
      _prefs.remove(_kJournal),
      _prefs.remove(_kProfile),
      _prefs.remove(_kUnlocked),
      _prefs.remove(_kRuns),
      _prefs.remove(_kStepDays),
      _prefs.remove(_kStepBaseline),
      _prefs.remove(_kPlans),
      _prefs.remove(_kRunSettings),
    ]);
  }
}
