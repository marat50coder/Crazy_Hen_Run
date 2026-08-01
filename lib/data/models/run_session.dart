import 'run_type.dart';

/// A single completed run. Distance is derived from real step-sensor data
/// (steps × stride), never GPS, so nothing here needs location access.
///
/// [cadence] is a small list of normalised intensity samples (0..1) captured
/// over the run. It is what the trace painter draws — a stylised profile of
/// the effort, not a geographic route.
class RunSession {
  const RunSession({
    required this.id,
    required this.type,
    required this.startedAt,
    required this.durationSec,
    required this.steps,
    required this.distanceMeters,
    required this.calories,
    required this.cadence,
    this.feeling = 3,
    this.note = '',
  });

  final String id;
  final RunType type;
  final DateTime startedAt;
  final int durationSec;
  final int steps;
  final double distanceMeters;
  final int calories;
  final List<double> cadence;

  /// 1..5 how the run felt (used by the mood chip and stats).
  final int feeling;
  final String note;

  /// Average pace in seconds per kilometre. 0 when distance is negligible.
  int get paceSecPerKm {
    if (distanceMeters < 20 || durationSec <= 0) return 0;
    return (durationSec / (distanceMeters / 1000)).round();
  }

  /// Average speed in km/h.
  double get speedKmh {
    if (durationSec <= 0) return 0;
    return (distanceMeters / 1000) / (durationSec / 3600);
  }

  double get avgCadenceSpm {
    if (durationSec <= 0) return 0;
    return steps / (durationSec / 60);
  }

  String get distanceLabel {
    if (distanceMeters < 1000) return '${distanceMeters.round()} m';
    return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
  }

  String get durationLabel {
    final h = durationSec ~/ 3600;
    final m = (durationSec % 3600) ~/ 60;
    final s = durationSec % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get paceLabel {
    final p = paceSecPerKm;
    if (p <= 0) return '--';
    final m = p ~/ 60;
    final s = p % 60;
    return "$m'${s.toString().padLeft(2, '0')}\" /km";
  }

  RunSession copyWith({
    int? feeling,
    String? note,
  }) {
    return RunSession(
      id: id,
      type: type,
      startedAt: startedAt,
      durationSec: durationSec,
      steps: steps,
      distanceMeters: distanceMeters,
      calories: calories,
      cadence: cadence,
      feeling: feeling ?? this.feeling,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type.name,
        'startedAt': startedAt.toIso8601String(),
        'durationSec': durationSec,
        'steps': steps,
        'distanceMeters': distanceMeters,
        'calories': calories,
        'cadence': cadence,
        'feeling': feeling,
        'note': note,
      };

  factory RunSession.fromJson(Map<String, dynamic> json) => RunSession(
        id: json['id'] as String,
        type: RunType.byName(json['type'] as String? ?? 'free'),
        startedAt: DateTime.parse(json['startedAt'] as String),
        durationSec: (json['durationSec'] as num).toInt(),
        steps: (json['steps'] as num).toInt(),
        distanceMeters: (json['distanceMeters'] as num).toDouble(),
        calories: (json['calories'] as num).toInt(),
        cadence: (json['cadence'] as List<dynamic>? ?? const <dynamic>[])
            .map((e) => (e as num).toDouble())
            .toList(),
        feeling: (json['feeling'] as num?)?.toInt() ?? 3,
        note: json['note'] as String? ?? '',
      );
}
