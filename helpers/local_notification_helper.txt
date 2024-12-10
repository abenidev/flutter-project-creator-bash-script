import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart';

class LocalNotificationHelper {
  LocalNotificationHelper._();

  static const AndroidNotificationDetails _simpleAndroidNotifDetails = AndroidNotificationDetails(
    'simple_notificaion',
    'Simple Notification',
    channelDescription: 'A channel to show simple notifications.',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
    //if you want to use your own custom sound add it to android res raw directory
    // sound: RawResourceAndroidNotificationSound('slow_spring_board'),
  );

  static const AndroidNotificationDetails _periodicAndroidNotifDetails = AndroidNotificationDetails(
    'periodic_notificaion',
    'Periodic Notification',
    channelDescription: 'A channel to show periodic notifications.',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
  );

  static const AndroidNotificationDetails _sheduledAndroidNotifDetals = AndroidNotificationDetails(
    'scheduled_notificaion',
    'Scheduled Notification',
    channelDescription: 'A channel to show scheduled notifications.',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
  );

  static Future<bool> initializeNotif() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();
    const LinuxInitializationSettings initializationSettingsLinux = LinuxInitializationSettings(defaultActionName: 'Open notification');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
    );
    bool? isSuccess = await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
    return isSuccess ?? false;
  }

  static void _onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    // ignore: unused_local_variable
    final String? payload = notificationResponse.payload;
    if (notificationResponse.payload != null) {
      //
    }

    // await Navigator.push(
    //   context,
    //   MaterialPageRoute<void>(builder: (context) => SecondScreen(payload)),
    // );
  }

  static Future<bool> requestPermission() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    bool? isSuccess = await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    return isSuccess ?? false;
  }

  static Future<bool> requestExactAlarmPermission() async {
    bool? isAccepted = await AndroidFlutterLocalNotificationsPlugin().requestExactAlarmsPermission();
    return isAccepted ?? false;
  }

  static Future<void> cancelAllNotif() async {
    await FlutterLocalNotificationsPlugin().cancelAll();
  }

  //cancel Notification by notification id
  static Future cancelNotificationByNotificationId(int notificationId) async {
    await FlutterLocalNotificationsPlugin().cancel(notificationId);
  }

  static Future<bool> showSimpleNotif({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    bool isSuccess = await requestPermission();
    if (!isSuccess) return false;

    NotificationDetails notificationDetails = const NotificationDetails(
      android: _simpleAndroidNotifDetails,
    );
    await FlutterLocalNotificationsPlugin().show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    return true;
  }

  static Future<bool> showPeriodicNotif({
    required int id,
    required String title,
    required String body,
    required Duration duration,
    String? payload,
  }) async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: _periodicAndroidNotifDetails,
    );
    bool isSuccess = await requestPermission();
    if (!isSuccess) return false;

    bool isAccepted = await requestExactAlarmPermission();
    if (!isAccepted) return false;

    await FlutterLocalNotificationsPlugin().periodicallyShowWithDuration(
      id,
      title,
      body,
      duration,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    return true;
  }

  static Future<bool> showScheduledNotif({
    required int id,
    required String title,
    required String body,
    required Duration? duration,
    TZDateTime? scheduledDate,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    tz.initializeTimeZones();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    bool isSuccess = await requestPermission();
    if (!isSuccess) return false;

    bool isAccepted = await requestExactAlarmPermission();
    if (!isAccepted) return false;

    NotificationDetails notificationDetails = const NotificationDetails(
      android: _sheduledAndroidNotifDetals,
    );

    await FlutterLocalNotificationsPlugin().zonedSchedule(
      id,
      title,
      body,
      scheduledDate ?? tz.TZDateTime.now(tz.local).add(duration ?? const Duration(seconds: 5)),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchDateTimeComponents,
    );

    return true;
  }

  static tz.TZDateTime _nextInstanceOfTimeByHour({required int hour, int minute = 0}) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static tz.TZDateTime _nextInstanceOfTimeByDayAndHour({required int day, required int hour, int minute = 0}) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTimeByHour(hour: hour, minute: minute);
    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  //schedule daily notification
  // hour ---> midnight: 0 ----> 23
  static Future<bool> showScheduledDailyNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    required int hour,
    required int minute,
    // int hour = 10,
    // int minute = 0,
  }) async {
    try {
      return await showScheduledNotif(
        id: id,
        title: title,
        body: body,
        scheduledDate: _nextInstanceOfTimeByHour(hour: hour, minute: minute),
        duration: null,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // logger.i('e: $e');
      return false;
    }
  }

  //schedule weekly notification
  // day ---> monday: 1 ---> sunday: 7
  // hour ---> midnight: 0 ----> 23
  static Future<bool> showScheduledWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    required int day,
    required int hour,
    required int minute,
    // int day = 1,
    // int hour = 10,
    // int minute = 0,
  }) async {
    try {
      return await showScheduledNotif(
        id: id,
        title: title,
        body: body,
        scheduledDate: _nextInstanceOfTimeByDayAndHour(day: day, hour: hour, minute: minute),
        duration: null,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      // logger.i('e: $e');
      return false;
    }
  }
}
