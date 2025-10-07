import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/habit.dart';

class ImprovedNotificationService {
  static final ImprovedNotificationService _instance = ImprovedNotificationService._internal();
  factory ImprovedNotificationService() => _instance;
  ImprovedNotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('=== Initializing ImprovedNotificationService ===');
    
    // 重要: タイムゾーン初期化（既知の問題の解決策）
    tz.initializeTimeZones();
    // Asia/Tokyoに直接設定（最も確実）
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
    debugPrint('Local timezone set to: Asia/Tokyo');

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

    // Android通知チャンネルを作成（Android 12+対応）
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      const AndroidNotificationChannel habitChannel = AndroidNotificationChannel(
        'habit_reminders_v2',
        '習慣リマインダー（改善版）',
        description: '習慣の実行をリマインドします（改善版）',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      
      const AndroidNotificationChannel testChannel = AndroidNotificationChannel(
        'test_notifications_v2',
        'テスト通知（改善版）',
        description: 'アプリの通知機能をテストします（改善版）',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      
      await androidImplementation?.createNotificationChannel(habitChannel);
      await androidImplementation?.createNotificationChannel(testChannel);
      
      debugPrint('Improved notification channels created');
    }

    await _requestPermissions();
    _initialized = true;
    debugPrint('ImprovedNotificationService initialized successfully');
  }

  static Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      // 基本通知権限をリクエスト（Android 13+必須）
      final bool? notificationPermission = await androidImplementation?.requestNotificationsPermission();
      debugPrint('Notification permission granted: $notificationPermission');
      
      // exact alarm権限をチェック（Android 12+必須）
      final bool? canScheduleExact = await androidImplementation?.canScheduleExactNotifications();
      debugPrint('Can schedule exact notifications: $canScheduleExact');
      
      if (canScheduleExact == false) {
        debugPrint('Requesting exact alarm permission...');
        await androidImplementation?.requestExactAlarmsPermission();
        
        // 再度チェック
        final bool? canScheduleExactAfter = await androidImplementation?.canScheduleExactNotifications();
        debugPrint('Can schedule exact notifications after request: $canScheduleExactAfter');
      }
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> scheduleHabitNotifications(Habit habit) async {
    debugPrint('=== Scheduling notifications for habit: ${habit.title} (IMPROVED) ===');
    debugPrint('Habit ID: ${habit.id}');
    debugPrint('Notification time: ${habit.notificationTime}');
    debugPrint('Frequency: ${habit.frequency}');
    debugPrint('Specific days: ${habit.specificDays}');
    
    if (habit.notificationTime == null) {
      debugPrint('No notification time set, skipping...');
      return;
    }

    // 既存の通知をキャンセル
    debugPrint('Canceling existing notifications for habit: ${habit.id}');
    await _cancelHabitNotifications(habit.id);

    final notificationTime = habit.notificationTime!;

    switch (habit.frequency) {
      case HabitFrequency.daily:
        await _scheduleDailyNotificationImproved(habit, notificationTime);
        break;
      case HabitFrequency.specificDays:
        if (habit.specificDays != null) {
          await _scheduleWeeklyNotificationsImproved(habit, notificationTime, habit.specificDays!);
        }
        break;
    }
  }

  Future<void> _scheduleDailyNotificationImproved(Habit habit, DateTime notificationTime) async {
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
    debugPrint('Scheduling daily notification (IMPROVED) for habit: ${habit.title}');
    debugPrint('Scheduled for: $scheduledDate');
    debugPrint('TZDateTime: $tzScheduledDate');
    debugPrint('Notification ID: ${habit.id.hashCode}');

    try {
      await _notifications.zonedSchedule(
        habit.id.hashCode,
        '習慣のお時間です',
        '${habit.title}の時間になりました！',
        tzScheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_reminders_v2',
            '習慣リマインダー（改善版）',
            channelDescription: '習慣の実行をリマインドします（改善版）',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            enableLights: true,
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
        // Android 12+対応の重要な設定
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      
      debugPrint('Daily notification (IMPROVED) scheduled successfully for habit: ${habit.title}');
    } catch (e) {
      debugPrint('Error scheduling daily notification (IMPROVED): $e');
      rethrow;
    }
  }

  Future<void> _scheduleWeeklyNotificationsImproved(
      Habit habit, DateTime notificationTime, List<int> specificDays) async {
    final now = DateTime.now();
    
    debugPrint('Scheduling weekly notifications (IMPROVED) for habit: ${habit.title}');
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

      try {
        await _notifications.zonedSchedule(
          notificationId,
          '習慣のお時間です',
          '${habit.title}の時間になりました！',
          tz.TZDateTime.from(scheduledDate, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'habit_reminders_v2',
              '習慣リマインダー（改善版）',
              channelDescription: '習慣の実行をリマインドします（改善版）',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              playSound: true,
              enableVibration: true,
              enableLights: true,
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
          // Android 12+対応の重要な設定
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        
        debugPrint('Weekly notification (IMPROVED) scheduled for day $dayOfWeek');
      } catch (e) {
        debugPrint('Error scheduling weekly notification for day $dayOfWeek: $e');
      }
    }
    
    debugPrint('All weekly notifications (IMPROVED) scheduled for habit: ${habit.title}');
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
      'テスト通知（改善版）',
      'これはテスト通知です。通知機能が正常に動作しています。',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_notifications_v2',
          'テスト通知（改善版）',
          channelDescription: 'アプリの通知機能をテストします（改善版）',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
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

  // 改良版のテスト用スケジュール通知（30秒後）
  Future<void> scheduleTestNotificationImproved() async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = now.add(const Duration(seconds: 30));
    
    debugPrint('=== Scheduling IMPROVED test notification ===');
    debugPrint('Current time: $now');
    debugPrint('Scheduled time: $scheduledTime');
    debugPrint('Time difference: ${scheduledTime.difference(now).inSeconds} seconds');
    
    // 権限チェック
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      final bool? canScheduleExact = await androidImplementation?.canScheduleExactNotifications();
      debugPrint('Can schedule exact notifications: $canScheduleExact');
      
      if (canScheduleExact != true) {
        debugPrint('Requesting exact alarm permission before test...');
        await androidImplementation?.requestExactAlarmsPermission();
      }
    }
    
    try {
      await _notifications.zonedSchedule(
        888,
        'スケジュールテスト（改善版）',
        '30秒後の通知テスト - 予定: ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_notifications_v2',
            'テスト通知（改善版）',
            channelDescription: 'スケジュール機能をテストします（改善版）',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            enableLights: true,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // Android 12+対応の最も重要な設定
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      
      debugPrint('IMPROVED test notification scheduled successfully');
      
      // すぐに予約済み通知を確認
      final pending = await getPendingNotifications();
      debugPrint('Pending notifications count: ${pending.length}');
      for (final notif in pending) {
        debugPrint('- ID: ${notif.id}, Title: ${notif.title}');
      }
      
    } catch (e) {
      debugPrint('Error scheduling IMPROVED test notification: $e');
      rethrow;
    }
  }
}