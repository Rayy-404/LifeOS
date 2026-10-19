import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  return LocalNotificationService();
});

/// Android Local Notification Scheduler & Reconciler (`03-technical-spec.md` Section 3.2).
class LocalNotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const String channelId = 'lifeos_reminders_channel';
  static const String channelName = 'LifeOS Reminders';
  static const String channelDescription =
      'Notifications for scheduled task deadlines and calendar events';

  /// Deterministic positive 31-bit integer ID from Reminder UUID (`01-prd.md` Section 10.5).
  static int notificationIdFromUuid(String reminderUuid) {
    return reminderUuid.hashCode & 0x7FFFFFFF;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation == null) return false;

    final granted = await androidImplementation.requestNotificationsPermission();
    await androidImplementation.requestExactAlarmsPermission();
    return granted ?? false;
  }

  Future<void> scheduleReminder({
    required String reminderUuid,
    required String title,
    required String body,
    required DateTime remindAt,
  }) async {
    await initialize();
    final id = notificationIdFromUuid(reminderUuid);
    final scheduledDate = tz.TZDateTime.from(remindAt, tz.local);

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
    );

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelReminder(String reminderUuid) async {
    final id = notificationIdFromUuid(reminderUuid);
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingReminders() {
    return _plugin.pendingNotificationRequests();
  }
}
