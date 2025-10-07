import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/habit.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
      macOS: iOSSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 明示的に通知チャンネルを作成
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      const AndroidNotificationChannel habitChannel = AndroidNotificationChannel(
        'habit_reminders',
        '習慣リマインダー',
        description: '習慣の実行をリマインドします',
        importance: Importance.high,
      );
      
      const AndroidNotificationChannel testChannel = AndroidNotificationChannel(
        'test_notifications',
        'テスト通知',
        description: 'アプリの通知機能をテストします',
        importance: Importance.high,
      );
      
      await androidImplementation?.createNotificationChannel(habitChannel);
      await androidImplementation?.createNotificationChannel(testChannel);
      
      debugPrint('Notification channels created');
    }

    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      await _notifications
          .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      // 基本通知権限をリクエスト
      final bool? notificationPermission = await androidImplementation?.requestNotificationsPermission();
      debugPrint('Notification permission granted: $notificationPermission');
      
      // exact alarm権限をチェック
      final bool? canScheduleExact = await androidImplementation?.canScheduleExactNotifications();
      debugPrint('Can schedule exact notifications: $canScheduleExact');
      
      // exact alarm権限がない場合は自動的にリクエスト
      if (canScheduleExact == false) {
        debugPrint('Requesting exact alarm permission...');
        await androidImplementation?.requestExactAlarmsPermission();
        
        // 再度チェック
        final bool? canScheduleExactAfter = await androidImplementation?.canScheduleExactNotifications();
        debugPrint('Can schedule exact notifications after request: $canScheduleExactAfter');
      }
      
      // バッテリー最適化の確認とリクエスト
      try {
        const platform = MethodChannel('battery_optimization');
        final bool isBatteryOptimized = await platform.invokeMethod('isIgnoringBatteryOptimizations');
        debugPrint('Is ignoring battery optimizations: $isBatteryOptimized');
        
        if (!isBatteryOptimized) {
          debugPrint('Requesting battery optimization exemption...');
          await platform.invokeMethod('requestIgnoreBatteryOptimizations');
        }
      } catch (e) {
        debugPrint('Battery optimization check failed: $e');
      }
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> scheduleHabitNotifications(Habit habit) async {
    debugPrint('=== Scheduling notifications for habit: ${habit.title} ===');
    debugPrint('Habit ID: ${habit.id}');
    debugPrint('Notification time: ${habit.notificationTime}');
    debugPrint('Frequency: ${habit.frequency}');
    debugPrint('Specific days: ${habit.specificDays}');
    
    if (habit.notificationTime == null) {
      debugPrint('No notification time set, skipping...');
      return;
    }

    // Android 12以降でexact alarmの権限をチェック
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      final bool? exactAlarmsAllowed = await androidImplementation?.canScheduleExactNotifications();
      debugPrint('Exact alarms allowed: $exactAlarmsAllowed');
      
      if (exactAlarmsAllowed != true) {
        debugPrint('Exact alarms not allowed, requesting permission...');
        await androidImplementation?.requestExactAlarmsPermission();
        
        // 権限リクエスト後に再チェック
        final bool? exactAlarmsAllowedAfter = await androidImplementation?.canScheduleExactNotifications();
        debugPrint('Exact alarms allowed after request: $exactAlarmsAllowedAfter');
        
        if (exactAlarmsAllowedAfter != true) {
          debugPrint('Exact alarm permission still not granted, cannot schedule notifications');
          throw Exception('Exact alarm permission required for scheduled notifications');
        }
      }
    }

    debugPrint('Canceling existing notifications for habit: ${habit.id}');
    await _cancelHabitNotifications(habit.id);

    final notificationTime = habit.notificationTime!;

    switch (habit.frequency) {
      case HabitFrequency.daily:
        await _scheduleDailyNotification(habit, notificationTime);
        break;
      case HabitFrequency.specificDays:
        if (habit.specificDays != null) {
          await _scheduleWeeklyNotifications(habit, notificationTime, habit.specificDays!);
        }
        break;
    }
  }

  Future<void> _scheduleDailyNotification(Habit habit, DateTime notificationTime) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      notificationTime.hour,
      notificationTime.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
    debugPrint('Scheduling daily notification for habit: ${habit.title}');
    debugPrint('Notification time: ${notificationTime.hour}:${notificationTime.minute}');
    debugPrint('Scheduled for: $scheduledDate');
    debugPrint('TZDateTime: $tzScheduledDate');
    debugPrint('Current time: $now');
    debugPrint('Current TZ time: ${tz.TZDateTime.now(tz.local)}');
    debugPrint('Time difference: ${tzScheduledDate.difference(tz.TZDateTime.now(tz.local)).inMinutes} minutes');
    debugPrint('Notification ID: ${habit.id.hashCode}');

    await _notifications.zonedSchedule(
      habit.id.hashCode,
      '習慣のお時間です',
      '${habit.title}の時間になりました！',
      tzScheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminders',
          '習慣リマインダー',
          channelDescription: '習慣の実行をリマインドします',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: habit.id,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    
    debugPrint('Daily notification scheduled successfully for habit: ${habit.title}');
  }

  Future<void> _scheduleWeeklyNotifications(
      Habit habit, DateTime notificationTime, List<int> specificDays) async {
    final now = DateTime.now();
    
    debugPrint('Scheduling weekly notifications for habit: ${habit.title}');
    debugPrint('Specific days: $specificDays');
    debugPrint('Notification time: ${notificationTime.hour}:${notificationTime.minute}');
    
    for (final dayOfWeek in specificDays) {
      int daysUntilTarget = dayOfWeek - now.weekday;
      if (daysUntilTarget <= 0) {
        daysUntilTarget += 7;
      }

      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day + daysUntilTarget,
        notificationTime.hour,
        notificationTime.minute,
      );

      if (dayOfWeek == now.weekday) {
        scheduledDate = DateTime(
          now.year,
          now.month,
          now.day,
          notificationTime.hour,
          notificationTime.minute,
        );
        
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 7));
        }
      }

      final notificationId = '${habit.id}_$dayOfWeek'.hashCode;
      debugPrint('Scheduling for day $dayOfWeek: $scheduledDate (ID: $notificationId)');

      await _notifications.zonedSchedule(
        '${habit.id}_$dayOfWeek'.hashCode,
        '習慣のお時間です',
        '${habit.title}の時間になりました！',
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_reminders',
            '習慣リマインダー',
            channelDescription: '習慣の実行をリマインドします',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          macOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: habit.id,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      debugPrint('Weekly notification scheduled for day $dayOfWeek');
    }
    
    debugPrint('All weekly notifications scheduled for habit: ${habit.title}');
  }

  Future<void> _cancelHabitNotifications(String habitId) async {
    await _notifications.cancel(habitId.hashCode);

    for (int dayOfWeek = 1; dayOfWeek <= 7; dayOfWeek++) {
      await _notifications.cancel('${habitId}_$dayOfWeek'.hashCode);
    }
  }

  Future<void> cancelHabitNotifications(String habitId) async {
    await _cancelHabitNotifications(habitId);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<void> showTestNotification() async {
    await _notifications.show(
      999,
      'テスト通知',
      'これはテスト通知です。通知機能が正常に動作しています。',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_notifications',
          'テスト通知',
          channelDescription: 'アプリの通知機能をテストします',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<bool> canScheduleExactNotifications() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidImplementation?.canScheduleExactNotifications() ?? false;
    }
    return true; // iOS/macOSでは常にtrue
  }

  Future<void> requestExactAlarmPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleTestNotification(DateTime scheduledTime) async {
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
    debugPrint('Scheduling test notification for: $scheduledTime');
    debugPrint('TZDateTime: $tzScheduledTime');
    debugPrint('Current time: ${DateTime.now()}');
    debugPrint('Current TZ time: ${tz.TZDateTime.now(tz.local)}');
    debugPrint('Time difference: ${tzScheduledTime.difference(tz.TZDateTime.now(tz.local)).inMinutes} minutes');
    
    try {
      await _notifications.zonedSchedule(
        888,
        'スケジュールテスト通知',
        '予定: ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')} 現在: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        tzScheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_notifications',
            'テスト通知',
            channelDescription: 'スケジュール機能をテストします',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          macOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      debugPrint('Test notification scheduled successfully');
    } catch (e) {
      debugPrint('Error scheduling test notification: $e');
      rethrow;
    }
  }

  Future<void> scheduleSimpleTest() async {
    debugPrint('=== Starting simple schedule test ===');
    final now = tz.TZDateTime.now(tz.local);
    final testTime = now.add(const Duration(seconds: 30));
    
    debugPrint('Scheduling simple test for 30 seconds from now: $testTime');
    debugPrint('Current TZ time: $now');
    debugPrint('Difference: ${testTime.difference(now).inSeconds} seconds');
    
    try {
      await _notifications.zonedSchedule(
        777,
        'シンプルテスト',
        '30秒後の通知テスト',
        testTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_notifications',
            'テスト通知',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      debugPrint('Simple test notification scheduled successfully');
      
      // すぐに予約済み通知を確認
      final pending = await getPendingNotifications();
      debugPrint('Pending notifications count: ${pending.length}');
      for (final notif in pending) {
        debugPrint('- ID: ${notif.id}, Title: ${notif.title}');
      }
      
    } catch (e) {
      debugPrint('Error scheduling simple test: $e');
      rethrow;
    }
  }

  Future<void> testAlarmManager() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        const platform = MethodChannel('battery_optimization');
        final String result = await platform.invokeMethod('testAlarmManager');
        debugPrint('AlarmManager test result: $result');
      } catch (e) {
        debugPrint('AlarmManager test failed: $e');
      }
    }
  }
}