/// Number and time formatting helpers used across the running screens.
///
/// These live in a separate file so unit tests can exercise them without
/// pulling in a Flutter build, and so the callers stay declarative and
/// readable ("`85.formatClock()`" rather than a two-line `padLeft` dance).
library;

/// Extension methods on `int` that describe a number of seconds.
///
/// The formatting choices match what the rest of the app has always used:
///
///  * ``m:ss`` when the run is shorter than an hour,
///  * ``h:mm:ss`` from an hour onwards.
extension SecondsFormatting on int {
  /// Formats this value as an elapsed clock: `mm:ss` or `h:mm:ss`.
  String formatClock() {
    final total = this < 0 ? 0 : this;
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$mm:$ss';
    return '$mm:$ss';
  }

  /// Formats this value as a running pace: `m'ss"`. Returns `--` for
  /// non-positive values so screens don't have to null-check separately.
  String formatPace({String suffix = ''}) {
    if (this <= 0) return '--';
    final m = this ~/ 60;
    final s = (this % 60).toString().padLeft(2, '0');
    return "$m'$s\"$suffix";
  }
}

/// Extension methods on `double` used to render metres.
extension MetresFormatting on double {
  /// Rounds to whole metres below a kilometre and switches to two-decimal
  /// kilometres above.
  String formatDistanceCompact() {
    if (this < 1000) return '${round()}';
    return (this / 1000).toStringAsFixed(2);
  }

  /// The unit label that goes with [formatDistanceCompact], in uppercase to
  /// suit the "hero" statistic labels used in the live-run screen.
  String get compactDistanceUnit => this < 1000 ? 'METRES' : 'KILOMETRES';
}
