import 'package:intl/intl.dart';

/// Canonical `yyyy-MM-dd` key used everywhere logs are stored or looked up.
class DayKey {
  const DayKey._();

  static final DateFormat _format = DateFormat('yyyy-MM-dd');

  static String of(DateTime date) => _format.format(date);

  static DateTime parse(String key) => _format.parseStrict(key);

  static DateTime normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime today() => normalize(DateTime.now());

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime startOfWeek(DateTime date, {int firstWeekday = DateTime.monday}) {
    final normalized = normalize(date);
    final diff = (normalized.weekday - firstWeekday + 7) % 7;
    return normalized.subtract(Duration(days: diff));
  }

  static List<DateTime> weekOf(DateTime date, {int firstWeekday = DateTime.monday}) {
    final start = startOfWeek(date, firstWeekday: firstWeekday);
    return List<DateTime>.generate(7, (i) => start.add(Duration(days: i)));
  }

  static List<DateTime> lastDays(int count, {DateTime? from}) {
    final end = normalize(from ?? DateTime.now());
    return List<DateTime>.generate(
      count,
      (i) => end.subtract(Duration(days: count - 1 - i)),
    );
  }

  static String weekdayShort(int weekday) {
    const names = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(weekday - 1) % 7];
  }

  static String weekdayLetter(int weekday) {
    const names = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return names[(weekday - 1) % 7];
  }

  static String pretty(DateTime date) => DateFormat('EEEE, d MMMM').format(date);

  static String medium(DateTime date) => DateFormat('d MMM yyyy').format(date);

  static String monthYear(DateTime date) => DateFormat('MMMM yyyy').format(date);
}
