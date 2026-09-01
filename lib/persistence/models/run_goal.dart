/// Optional target the runner sets before hitting Start.
///
/// A [RunGoal] is always about *one* dimension — distance in metres or
/// duration in seconds. The live-run screen paints a ring around the timer
/// that fills as either value climbs.
///
/// The special sentinel [RunGoal.open] means "no target"; the ring is hidden
/// and the run behaves exactly like it always did.
enum RunGoalKind { open, distance, duration }

class RunGoal {
  const RunGoal._(this.kind, this.value);

  final RunGoalKind kind;

  /// Metres when [kind] is [RunGoalKind.distance]; seconds when it is
  /// [RunGoalKind.duration]; zero otherwise.
  final int value;

  static const RunGoal open = RunGoal._(RunGoalKind.open, 0);

  const RunGoal.distance(int metres) : this._(RunGoalKind.distance, metres);
  const RunGoal.duration(int seconds) : this._(RunGoalKind.duration, seconds);

  bool get isOpen => kind == RunGoalKind.open;
  bool get isDistance => kind == RunGoalKind.distance;
  bool get isDuration => kind == RunGoalKind.duration;

  /// Six default chips shown on the hub: three by distance, two by time and
  /// one "just move" option.
  static const List<RunGoal> presets = <RunGoal>[
    RunGoal.open,
    RunGoal.distance(1000),
    RunGoal.distance(3000),
    RunGoal.distance(5000),
    RunGoal.duration(15 * 60),
    RunGoal.duration(30 * 60),
  ];

  String get chipLabel {
    switch (kind) {
      case RunGoalKind.open:
        return 'Just move';
      case RunGoalKind.distance:
        if (value % 1000 == 0) return '${value ~/ 1000} km';
        return '${value / 1000} km';
      case RunGoalKind.duration:
        return '${value ~/ 60} min';
    }
  }

  String get liveLabel {
    switch (kind) {
      case RunGoalKind.open:
        return 'Open pace';
      case RunGoalKind.distance:
        return 'Goal $chipLabel';
      case RunGoalKind.duration:
        return 'Goal $chipLabel';
    }
  }

  /// Fraction 0..1 for the progress ring.
  double progress({required double distanceMeters, required int durationSec}) {
    switch (kind) {
      case RunGoalKind.open:
        return 0;
      case RunGoalKind.distance:
        if (value <= 0) return 0;
        return (distanceMeters / value).clamp(0.0, 1.0);
      case RunGoalKind.duration:
        if (value <= 0) return 0;
        return (durationSec / value).clamp(0.0, 1.0);
    }
  }

  bool isReached({required double distanceMeters, required int durationSec}) {
    switch (kind) {
      case RunGoalKind.open:
        return false;
      case RunGoalKind.distance:
        return distanceMeters >= value;
      case RunGoalKind.duration:
        return durationSec >= value;
    }
  }
}
