import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const init = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(init);

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

   if (Platform.isAndroid && android != null) {
      try {
        await android.requestNotificationsPermission();
      } catch (_) {}

      try {
        await android.requestExactAlarmsPermission();
      } catch (_) {}
    }
  }

  Future<void> scheduleExact({
    required int id,
    required String title,
    required String body,
    required DateTime fireTimeUtc,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'cue_mind_channel',
        'Cue Mind Reminders',
        channelDescription: 'Reminder notifications',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final tzTime = tz.TZDateTime.from(fireTimeUtc, tz.getLocation('UTC'));

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'reminder:$id',
      );
    } catch (_) {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'reminder:$id',
      );
    }
  }

  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelAll() => _plugin.cancelAll();
}
