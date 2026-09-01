import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../persistence/models/habit.dart';

/// On-device reminders for habits and the weekly run plan.
///
/// No remote push, no payload URLs, no attribution. The OS scheduler
/// fires these even if the process is dead; we only rewrite the
/// calendar when the user changes a habit or the reminder toggle.
class YardChime {
  YardChime._();

  static final YardChime instance = YardChime._();

  static const int _runNoticeId = 7101;
  static const String _channelId = 'yard.daily.chime';
  static const String _channelName = 'Henyard reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  Future<void> prepare() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final String name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@drawable/ic_yard_chime');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Habit and run reminders from Henyard Daily',
            importance: Importance.defaultImportance,
          ),
        );
    _ready = true;
  }

  Future<bool> askPermission() async {
    await prepare();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? true;
    }
    return true;
  }

  Future<void> sync({
    required bool enabled,
    required List<Habit> habits,
    required int runNudgeMinute,
  }) async {
    await prepare();
    await _plugin.cancelAll();
    if (!enabled) return;

    await _scheduleDaily(
      id: _runNoticeId,
      minuteOfDay: runNudgeMinute.clamp(0, 24 * 60 - 1),
      title: 'Time to lace up',
      body: 'A short run still counts toward this week\'s plan.',
    );

    for (final habit in habits) {
      if (habit.archived) continue;
      final minute = habit.preferredMinuteOfDay;
      if (minute == null) continue;
      for (final weekday in habit.weekdays) {
        await _scheduleWeekly(
          id: _habitNoticeId(habit.id, weekday),
          weekday: weekday,
          minuteOfDay: minute.clamp(0, 24 * 60 - 1),
          title: habit.title,
          body: 'Close the loop on ${habit.title} today.',
        );
      }
    }
  }

  int _habitNoticeId(String habitId, int weekday) {
    var hash = 0;
    for (final code in habitId.codeUnits) {
      hash = 0x1fffffff & (hash * 31 + code);
    }
    return 8200 + (hash % 900) * 8 + weekday;
  }

  Future<void> _scheduleDaily({
    required int id,
    required int minuteOfDay,
    required String title,
    required String body,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextDaily(minuteOfDay),
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleWeekly({
    required int id,
    required int weekday,
    required int minuteOfDay,
    required String title,
    required String body,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextWeekly(weekday, minuteOfDay),
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Habit and run reminders from Henyard Daily',
        icon: '@drawable/ic_yard_chime',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  tz.TZDateTime _nextDaily(int minuteOfDay) {
    final now = tz.TZDateTime.now(tz.local);
    var when = _at(now, minuteOfDay);
    if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }
    return when;
  }

  tz.TZDateTime _nextWeekly(int weekday, int minuteOfDay) {
    final now = tz.TZDateTime.now(tz.local);
    var when = _at(now, minuteOfDay);
    while (when.weekday != weekday || !when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }
    return when;
  }

  tz.TZDateTime _at(tz.TZDateTime day, int minuteOfDay) {
    return tz.TZDateTime(
      tz.local,
      day.year,
      day.month,
      day.day,
      minuteOfDay ~/ 60,
      minuteOfDay % 60,
    );
  }
}
