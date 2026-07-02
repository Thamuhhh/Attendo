import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder_profile.dart';
import 'offline_db.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const String _prefKey = 'notifications_enabled';
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings: initSettings);

    tz.initializeTimeZones();

    await _requestPermission();

    _initialized = true;
  }

  Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getBool(_prefKey);
    if (val == null) {
      await prefs.setBool(_prefKey, true);
      return true;
    }
    return val;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
    if (enabled) {
      await _requestPermission();
      await scheduleAllReminders();
    } else {
      await cancelAll();
    }
  }

  Future<void> _requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  Future<void> scheduleAllReminders() async {
    await cancelAll();
    final profiles = await OfflineDb.getReminders();
    for (final p in profiles) {
      if (p.enabled) await scheduleReminder(p);
    }
  }

  Future<void> scheduleReminder(ReminderProfile p) async {
    final now = DateTime.now();
    final body = await _smartBody(p);

    void scheduleOne(int id, DateTime date, int dayOfWeek) {
      final scheduled = tz.TZDateTime.from(date, tz.local);
      _plugin.zonedSchedule(
        id: id,
        title: p.label,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'attendance_reminder',
            'Attendance Reminder',
            channelDescription: 'Reminders to mark attendance',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: dayOfWeek == -1
            ? DateTimeComponents.time
            : DateTimeComponents.dayOfWeekAndTime,
      );
    }

    if (p.everyDay) {
      var date = DateTime(now.year, now.month, now.day, p.hour, p.minute);
      if (date.isBefore(now)) date = date.add(const Duration(days: 1));
      scheduleOne(p.id! * 10, date, -1);
    } else {
      for (int i = 0; i < 7; i++) {
        final flag = ReminderProfile.allDays[i];
        if (!p.hasDay(flag)) continue;
        var date = _nextDayOfWeek(now, i, p.hour, p.minute);
        scheduleOne(p.id! * 10 + i, date, i + 1);
      }
    }
  }

  DateTime _nextDayOfWeek(DateTime from, int targetDayIndex, int hour, int minute) {
    final target = (targetDayIndex + 1) % 7;
    final current = from.weekday % 7;
    int diff = target - current;
    if (diff < 0 || (diff == 0 && _timePassed(from, hour, minute))) diff += 7;
    return DateTime(from.year, from.month, from.day + diff, hour, minute);
  }

  bool _timePassed(DateTime now, int hour, int minute) =>
      now.hour > hour || (now.hour == hour && now.minute >= minute);

  Future<String> _smartBody(ReminderProfile p) async {
    if (!p.smartEnabled) return "Don't forget to mark today's attendance!";

    try {
      final today = await ApiService.getTodayAttendance();
      if (today.records.isNotEmpty) {
        return "Today's attendance already marked ✓";
      }
    } catch (_) {}

    try {
      final students = await ApiService.getStudents();
      if (students.isNotEmpty && p.smartGapDays > 0) {
        final cutoff = DateTime.now().subtract(Duration(days: p.smartGapDays));
        final missing = <String>[];
        for (final s in students) {
          try {
            final history = await ApiService.getAttendanceHistory(s.id);
            final last = history.isNotEmpty ? DateTime.tryParse(history.first['date'] as String? ?? '') : null;
            if (last == null || last.isBefore(cutoff)) {
              if (missing.length < 3) missing.add(s.name);
            }
          } catch (_) {}
        }
        if (missing.isNotEmpty) {
          return 'No attendance for ${missing.join(", ")}${missing.length < students.length ? " and more" : ""}';
        }
        return '${students.length} students waiting for attendance';
      }
      return '${students.length} students waiting for attendance';
    } catch (_) {
      return "Don't forget to mark today's attendance!";
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> cancelReminder(int profileId) async {
    for (int i = 0; i < 7; i++) {
      await _plugin.cancel(id: profileId * 10 + i);
    }
  }
}
