import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../foundation/services/step_feed.dart';
import '../foundation/utils/day_key.dart';
import '../persistence/snapshot_store.dart';
import '../persistence/models/hen_rank.dart';
import '../persistence/models/interval_plan.dart';
import '../persistence/models/run_goal.dart';
import '../persistence/models/run_session.dart';
import '../persistence/models/run_type.dart';
import '../persistence/models/running_challenge.dart';

/// Owns everything about running: the live step sensor, run sessions, interval
/// plans and every derived running metric. Habits stay in [HenState]; this is
/// the engine that makes the app a real running companion.
class RunTracker extends ChangeNotifier {
  RunTracker(this._store, this._pedometer) {
    _load();
  }

  final SnapshotStore _store;
  final StepFeed _pedometer;

  // ── settings ──────────────────────────────────────────────────────────────
  int _stepGoal = 8000;
  int _strideCm = 72;
  int _weightKg = 70;
  bool _haptics = true;
  int _weeklyRunTarget = 3;

  int get stepGoal => _stepGoal;
  int get strideCm => _strideCm;
  int get weightKg => _weightKg;
  int get weeklyRunTarget => _weeklyRunTarget;
  double get _strideM => _strideCm / 100;

  // ── sensor ──────────────────────────────────────────────────────────────
  bool _sensorGranted = false;
  bool _sensorAvailable = false;
  String _pedStatus = 'stopped';

  bool get sensorGranted => _sensorGranted;
  bool get sensorAvailable => _sensorAvailable;
  bool get isWalking => _pedStatus == 'walking';

  // ── data ──────────────────────────────────────────────────────────────────
  List<RunSession> _runs = <RunSession>[];
  Map<String, int> _stepDays = <String, int>{};
  List<IntervalPlan> _plans = <IntervalPlan>[];

  List<RunSession> get runs => List<RunSession>.unmodifiable(_runs);
  List<IntervalPlan> get plans =>
      <IntervalPlan>[..._plans, ...IntervalPlan.presets()];

  /// Newest finished session of this flavour, or null if none yet.
  RunSession? lastOf(RunType type) {
    for (final session in _runs) {
      if (session.type == type) return session;
    }
    return null;
  }

  /// Longest finished session of this flavour by distance.
  RunSession? bestOf(RunType type) {
    RunSession? best;
    for (final session in _runs) {
      if (session.type != type) continue;
      if (best == null || session.distanceMeters > best.distanceMeters) {
        best = session;
      }
    }
    return best;
  }

  bool isPersonalBest(RunSession session) {
    final best = bestOf(session.type);
    return best != null && best.id == session.id;
  }

  // ── step baseline (turns boot-relative counter into per-day) ────────────────
  int? _baselineSteps;
  String _baselineDay = '';
  int _lastCumulative = 0;
  DateTime _lastPersist = DateTime.fromMillisecondsSinceEpoch(0);

  // ── active run ──────────────────────────────────────────────────────────────
  bool _running = false;
  bool _paused = false;
  RunType _activeType = RunType.free;
  DateTime? _runStart;
  int _runStartCumulative = 0;
  int _elapsedSec = 0;
  int _runSteps = 0;
  int _lastSampleSteps = 0;
  final List<double> _cadence = <double>[];
  Timer? _ticker;

  RunGoal _activeGoal = RunGoal.open;
  bool _goalCelebrated = false;

  bool get isRunning => _running;
  bool get isPaused => _paused;
  RunType get activeType => _activeType;
  int get elapsedSec => _elapsedSec;
  List<double> get liveCadence => List<double>.unmodifiable(_cadence);

  /// Goal chosen for the current or most recent run. Read on the live screen.
  RunGoal get activeGoal => _activeGoal;

  /// Fires exactly once per run, the moment the goal is first reached.
  bool consumeGoalReachedEvent() {
    if (_activeGoal.isOpen || _goalCelebrated) return false;
    if (!_activeGoal.isReached(
      distanceMeters: liveDistanceMeters,
      durationSec: _elapsedSec,
    )) {
      return false;
    }
    _goalCelebrated = true;
    return true;
  }

  bool _ready = false;
  bool get ready => _ready;

  // ── bootstrap ─────────────────────────────────────────────────────────────
  void _load() {
    _runs = _store.readRuns();
    _stepDays = _store.readStepDays();
    _plans = _store.readPlans();

    final rs = _store.readRunSettings();
    _stepGoal = (rs['stepGoal'] as num?)?.toInt() ?? 8000;
    _strideCm = (rs['strideCm'] as num?)?.toInt() ?? 72;
    _weightKg = (rs['weightKg'] as num?)?.toInt() ?? 70;
    _haptics = rs['haptics'] as bool? ?? true;
    _weeklyRunTarget = (rs['weeklyRunTarget'] as num?)?.toInt() ?? 3;

    final base = _store.readStepBaseline();
    _baselineDay = base['day'] as String? ?? '';
    _baselineSteps = (base['baseline'] as num?)?.toInt();

    _ready = true;
    notifyListeners();
    _startPedometer();
  }

  Future<void> _persistSettings() => _store.writeRunSettings(<String, dynamic>{
        'stepGoal': _stepGoal,
        'strideCm': _strideCm,
        'weightKg': _weightKg,
        'haptics': _haptics,
        'weeklyRunTarget': _weeklyRunTarget,
      });

  void _tap() {
    if (_haptics) HapticFeedback.selectionClick();
  }

  // ── permission + sensor ─────────────────────────────────────────────────────
  Future<void> requestSensor() async {
    _sensorGranted = await _pedometer.ensurePermission();
    notifyListeners();
    if (_sensorGranted) _startPedometer();
  }

  Future<void> refreshPermission() async {
    _sensorGranted = await _pedometer.hasPermission();
    notifyListeners();
  }

  Future<void> _startPedometer() async {
    _sensorGranted = await _pedometer.hasPermission();
    await _pedometer.start(
      onSteps: _onCumulativeSteps,
      onStatus: (s) {
        _pedStatus = s;
        notifyListeners();
      },
      onError: (_) {
        _sensorAvailable = false;
        notifyListeners();
      },
    );
    notifyListeners();
  }

  void _onCumulativeSteps(int cumulative) {
    _sensorAvailable = true;
    _lastCumulative = cumulative;
    final today = DayKey.of(DateTime.now());

    if (_baselineDay != today || _baselineSteps == null) {
      _baselineDay = today;
      _baselineSteps = cumulative;
      _store.writeStepBaseline(<String, dynamic>{'day': today, 'baseline': cumulative});
    } else if (cumulative < _baselineSteps!) {
      // Device rebooted; the counter reset below our baseline.
      _baselineSteps = cumulative;
      _store.writeStepBaseline(<String, dynamic>{'day': today, 'baseline': cumulative});
    }

    final todaySteps = math.max(0, cumulative - _baselineSteps!);
    _stepDays[today] = todaySteps;

    if (_running && !_paused) {
      _runSteps = math.max(0, cumulative - _runStartCumulative);
    }

    // Throttle disk writes: at most once every few seconds.
    final now = DateTime.now();
    if (now.difference(_lastPersist).inSeconds >= 4) {
      _lastPersist = now;
      _store.writeStepDays(_stepDays);
    }
    notifyListeners();
  }

  // ── active run control ──────────────────────────────────────────────────────
  Future<void> startRun(RunType type, {RunGoal goal = RunGoal.open}) async {
    if (_running) return;
    if (!_sensorGranted) await requestSensor();
    _activeType = type;
    _activeGoal = goal;
    _goalCelebrated = false;
    _runStart = DateTime.now();
    _runStartCumulative = _lastCumulative;
    _elapsedSec = 0;
    _runSteps = 0;
    _lastSampleSteps = 0;
    _cadence.clear();
    _running = true;
    _paused = false;
    _tap();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), _tick);
    notifyListeners();
  }

  void pauseRun() {
    if (!_running) return;
    _paused = true;
    _tap();
    notifyListeners();
  }

  void resumeRun() {
    if (!_running) return;
    _paused = false;
    _tap();
    notifyListeners();
  }

  void _tick(Timer _) {
    if (_paused) return;
    _elapsedSec++;
    if (_elapsedSec % 2 == 0) _sampleCadence();
    notifyListeners();
  }

  void _sampleCadence() {
    double intensity;
    if (_sensorAvailable && _runSteps > 0) {
      final delta = _runSteps - _lastSampleSteps;
      _lastSampleSteps = _runSteps;
      final spm = delta * 30.0; // steps in a 2s window → per minute
      intensity = (spm / 190).clamp(0.04, 1.0);
    } else {
      // No sensor (emulator / disabled): draw a lively type-shaped profile so
      // the trace is never a dead flat line.
      final base = _typeBaseIntensity(_activeType);
      final wobble = 0.14 * math.sin(_elapsedSec / 5.0) +
          0.06 * math.sin(_elapsedSec / 1.7);
      intensity = (base + wobble).clamp(0.06, 1.0);
    }
    _cadence.add(intensity);
  }

  double _typeBaseIntensity(RunType type) {
    switch (type) {
      case RunType.recovery:
        return 0.32;
      case RunType.long:
        return 0.5;
      case RunType.free:
        return 0.58;
      case RunType.tempo:
        return 0.74;
      case RunType.interval:
        return 0.7;
      case RunType.sprint:
        return 0.9;
    }
  }

  /// Steps counted for the active run — real sensor data, or a time-based
  /// estimate when no step sensor is present so the run still records.
  int get liveSteps {
    if (_sensorAvailable) return _runSteps;
    return (_elapsedSec / 60 * 158).round();
  }

  double get liveDistanceMeters => liveSteps * _strideM;

  int get liveCalories =>
      (_activeType.met * _weightKg * (_elapsedSec / 3600)).round();

  int get livePaceSecPerKm {
    final dist = liveDistanceMeters;
    if (dist < 20 || _elapsedSec <= 0) return 0;
    return (_elapsedSec / (dist / 1000)).round();
  }

  Future<RunSession?> finishRun({int feeling = 3, String note = ''}) async {
    if (!_running || _runStart == null) return null;
    _ticker?.cancel();
    if (_cadence.isEmpty) _sampleCadence();
    final session = RunSession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: _activeType,
      startedAt: _runStart!,
      durationSec: _elapsedSec,
      steps: liveSteps,
      distanceMeters: liveDistanceMeters,
      calories: liveCalories,
      cadence: List<double>.of(_cadence),
      feeling: feeling,
      note: note,
    );
    _runs.insert(0, session);
    await _store.writeRuns(_runs);
    await _store.writeStepDays(_stepDays);
    _running = false;
    _paused = false;
    _elapsedSec = 0;
    _runSteps = 0;
    _cadence.clear();
    if (_haptics) HapticFeedback.mediumImpact();
    notifyListeners();
    return session;
  }

  void discardRun() {
    _ticker?.cancel();
    _running = false;
    _paused = false;
    _elapsedSec = 0;
    _runSteps = 0;
    _cadence.clear();
    notifyListeners();
  }

  Future<void> updateRun(RunSession run) async {
    final i = _runs.indexWhere((r) => r.id == run.id);
    if (i < 0) return;
    _runs[i] = run;
    notifyListeners();
    await _store.writeRuns(_runs);
  }

  Future<void> deleteRun(String id) async {
    _runs.removeWhere((r) => r.id == id);
    notifyListeners();
    await _store.writeRuns(_runs);
  }

  // ── interval plans ──────────────────────────────────────────────────────────
  Future<void> savePlan(IntervalPlan plan) async {
    final i = _plans.indexWhere((p) => p.id == plan.id);
    if (i >= 0) {
      _plans[i] = plan;
    } else {
      _plans.add(plan);
    }
    notifyListeners();
    await _store.writePlans(_plans);
  }

  Future<void> deletePlan(String id) async {
    _plans.removeWhere((p) => p.id == id);
    notifyListeners();
    await _store.writePlans(_plans);
  }

  /// Clears all running data held in memory after the store has been wiped.
  void resetRunningData() {
    _ticker?.cancel();
    _runs = <RunSession>[];
    _stepDays = <String, int>{};
    _plans = <IntervalPlan>[];
    _running = false;
    _paused = false;
    _elapsedSec = 0;
    _runSteps = 0;
    _cadence.clear();
    _baselineSteps = null;
    _baselineDay = '';
    notifyListeners();
  }

  // ── settings mutations ──────────────────────────────────────────────────────
  Future<void> setStepGoal(int value) async {
    _stepGoal = value.clamp(1000, 40000);
    notifyListeners();
    await _persistSettings();
  }

  Future<void> setStrideCm(int value) async {
    _strideCm = value.clamp(40, 120);
    notifyListeners();
    await _persistSettings();
  }

  Future<void> setWeightKg(int value) async {
    _weightKg = value.clamp(30, 200);
    notifyListeners();
    await _persistSettings();
  }

  Future<void> setHaptics(bool value) async {
    _haptics = value;
    notifyListeners();
    await _persistSettings();
  }

  Future<void> setWeeklyRunTarget(int value) async {
    _weeklyRunTarget = value.clamp(1, 14);
    notifyListeners();
    await _persistSettings();
  }

  // ── step metrics ──────────────────────────────────────────────────────────
  int stepsForDay(DateTime day) => _stepDays[DayKey.of(day)] ?? 0;

  int get todaySteps => stepsForDay(DateTime.now());

  double get todayDistanceMeters => todaySteps * _strideM;

  double get stepGoalProgress =>
      _stepGoal <= 0 ? 0 : (todaySteps / _stepGoal).clamp(0.0, 1.0);

  int get todayCalories => (todaySteps * 0.04).round();

  /// Steps for the last [days] calendar days, oldest first.
  List<({DateTime day, int steps})> stepSeries(int days) {
    final today = DayKey.today();
    return List<({DateTime day, int steps})>.generate(days, (i) {
      final d = today.subtract(Duration(days: days - 1 - i));
      return (day: d, steps: _stepDays[DayKey.of(d)] ?? 0);
    });
  }

  // ── run metrics ──────────────────────────────────────────────────────────
  double get lifetimeRunMeters =>
      _runs.fold<double>(0, (sum, r) => sum + r.distanceMeters);

  double get lifetimeStepMeters =>
      _stepDays.values.fold<int>(0, (sum, s) => sum + s) * _strideM;

  double get lifetimeMeters => lifetimeRunMeters + lifetimeStepMeters;

  int get totalRuns => _runs.length;

  int get totalSteps => _stepDays.values.fold<int>(0, (sum, s) => sum + s);

  double get longestRunMeters =>
      _runs.isEmpty ? 0 : _runs.map((r) => r.distanceMeters).reduce(math.max);

  int get totalRunSeconds =>
      _runs.fold<int>(0, (sum, r) => sum + r.durationSec);

  HenRank get rank => HenRank.forDistance(lifetimeMeters.round());
  double get rankProgress => rank.progressFrom(lifetimeMeters.round());

  String distanceLabelOf(double metres) {
    if (metres < 1000) return '${metres.round()} m';
    return '${(metres / 1000).toStringAsFixed(metres < 10000 ? 2 : 1)} km';
  }

  /// True if any session was started on [day] (calendar day, ignoring time).
  bool ranOnDay(DateTime day) {
    final key = DayKey.of(day);
    return _runs.any((r) => DayKey.of(r.startedAt) == key);
  }

  /// Runs on [day].
  int runsOnDay(DateTime day) {
    final key = DayKey.of(day);
    return _runs.where((r) => DayKey.of(r.startedAt) == key).length;
  }

  /// Fraction of the weekly run target that has been completed. Never > 1.
  double get weeklyRunProgress {
    if (_weeklyRunTarget <= 0) return 0;
    return (weekRuns / _weeklyRunTarget).clamp(0.0, 1.0);
  }

  List<RunSession> runsInWeek([DateTime? ref]) {
    final week = DayKey.weekOf(ref ?? DateTime.now(), firstWeekday: DateTime.monday);
    final start = week.first;
    final end = week.last.add(const Duration(days: 1));
    return _runs
        .where((r) => !r.startedAt.isBefore(start) && r.startedAt.isBefore(end))
        .toList();
  }

  double get weekDistanceMeters =>
      runsInWeek().fold<double>(0, (sum, r) => sum + r.distanceMeters);

  int get weekRuns => runsInWeek().length;

  /// Consecutive days up to today with meaningful movement (a run or 1k+ steps).
  int get dayStreak {
    var streak = 0;
    for (var i = 0; i < 400; i++) {
      final day = DayKey.today().subtract(Duration(days: i));
      final key = DayKey.of(day);
      final steps = _stepDays[key] ?? 0;
      final ran = _runs.any((r) => DayKey.of(r.startedAt) == key);
      final active = ran || steps >= 1000;
      if (active) {
        streak++;
      } else if (i == 0) {
        continue; // today may still be young
      } else {
        break;
      }
    }
    return streak;
  }

  double challengeValue(ChallengeMetric metric) {
    switch (metric) {
      case ChallengeMetric.weeklyDistance:
        return weekDistanceMeters;
      case ChallengeMetric.weeklyRuns:
        return weekRuns.toDouble();
      case ChallengeMetric.totalDistance:
        return lifetimeRunMeters;
      case ChallengeMetric.longestRun:
        return longestRunMeters;
      case ChallengeMetric.dayStreak:
        return dayStreak.toDouble();
      case ChallengeMetric.totalSteps:
        return todaySteps.toDouble();
    }
  }

  Future<void> resetEverything() async {
    _ticker?.cancel();
    _runs = <RunSession>[];
    _stepDays = <String, int>{};
    _plans = <IntervalPlan>[];
    _baselineSteps = _lastCumulative;
    _baselineDay = DayKey.of(DateTime.now());
    _running = false;
    _paused = false;
    _elapsedSec = 0;
    _runSteps = 0;
    _cadence.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pedometer.stop();
    super.dispose();
  }
}
