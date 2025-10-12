import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/habit.dart';

class NativeAlarmNotificationService {
  static final NativeAlarmNotificationService _instance = NativeAlarmNotificationService._internal();
  factory NativeAlarmNotificationService() => _instance;
  NativeAlarmNotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static const MethodChannel _methodChannel = MethodChannel('native_alarm_manager');
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('=== Initializing NativeAlarmNotificationService ===');

    // flutter_local_notificationsの初期化（通知表示用のみ）
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

    // Androidチャンネル作成
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      const AndroidNotificationChannel nativeChannel = AndroidNotificationChannel(
        'native_habit_alarms',
        '習慣リマインダー（ネイティブ版）',
        description: 'ネイティブAlarmManagerを使用した習慣リマインダー',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      
      await androidImplementation?.createNotificationChannel(nativeChannel);
      debugPrint('Native alarm notification channel created');
    }

    // 通知許可は後で求める（ホーム画面で説明してから）

    // ネイティブのAlarmManagerを初期化
    try {
      final result = await _methodChannel.invokeMethod('initialize');
      debugPrint('Native AlarmManager initialized: $result');
    } catch (e) {
      debugPrint('Error initializing native AlarmManager: $e');
    }

    _initialized = true;
    debugPrint('NativeAlarmNotificationService initialized successfully');
  }

  /// 通知の許可をリクエスト（外部から呼び出し可能）
  Future<void> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      final bool? notificationPermission = await androidImplementation?.requestNotificationsPermission();
      debugPrint('Native Notification permission granted: $notificationPermission');
      
      // Exact alarm権限もリクエスト
      final bool? canScheduleExact = await androidImplementation?.canScheduleExactNotifications();
      debugPrint('Native Can schedule exact notifications: $canScheduleExact');
      
      if (canScheduleExact == false) {
        debugPrint('Requesting native exact alarm permission...');
        await androidImplementation?.requestExactAlarmsPermission();
      }
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Native notification tapped: ${response.payload}');
  }

  Future<void> scheduleHabitNotifications(Habit habit) async {
    debugPrint('=== Scheduling native alarm notifications for habit: ${habit.title} ===');
    debugPrint('Habit ID: ${habit.id}');
    debugPrint('Notification time: ${habit.notificationTime}');
    debugPrint('Frequency: ${habit.frequency}');
    
    if (habit.notificationTime == null) {
      debugPrint('No notification time set, skipping...');
      return;
    }

    // 既存のアラームをキャンセル
    await cancelHabitNotifications(habit.id);

    final notificationTime = habit.notificationTime!;
    final now = DateTime.now();

    switch (habit.frequency) {
      case HabitFrequency.daily:
        await _scheduleDailyNativeAlarm(habit, notificationTime, now);
        break;
      case HabitFrequency.specificDays:
        if (habit.specificDays != null) {
          await _scheduleWeeklyNativeAlarms(habit, notificationTime, habit.specificDays!, now);
        }
        break;
    }
  }

  Future<void> _scheduleDailyNativeAlarm(Habit habit, DateTime notificationTime, DateTime now) async {
    // 今日の通知時刻を計算
    var nextNotification = DateTime(
      now.year,
      now.month,
      now.day,
      notificationTime.hour,
      notificationTime.minute,
    );

    // 既に時刻が過ぎていたら明日に
    if (nextNotification.isBefore(now)) {
      nextNotification = nextNotification.add(const Duration(days: 1));
    }

    final alarmId = habit.id.hashCode;
    
    debugPrint('Scheduling daily native alarm: $alarmId');
    debugPrint('Next notification: $nextNotification');
    debugPrint('Delay: ${nextNotification.difference(now).inMinutes} minutes');

    try {
      await _methodChannel.invokeMethod('scheduleAlarm', {
        'alarmId': alarmId,
        'triggerTimeMillis': nextNotification.millisecondsSinceEpoch,
        'habitId': habit.id,
        'habitTitle': habit.title,
        'frequency': 'daily',
      });
      
      debugPrint('Daily native alarm scheduled successfully for habit: ${habit.title}');
    } catch (e) {
      debugPrint('Error scheduling daily native alarm: $e');
      rethrow;
    }
  }

  Future<void> _scheduleWeeklyNativeAlarms(Habit habit, DateTime notificationTime, List<int> specificDays, DateTime now) async {
    debugPrint('Scheduling weekly native alarms for habit: ${habit.title}');
    debugPrint('Specific days: $specificDays');
    
    for (final dayOfWeek in specificDays) {
      int daysUntilTarget = dayOfWeek - now.weekday;
      if (daysUntilTarget <= 0) {
        daysUntilTarget += 7;
      }

      var nextNotification = DateTime(
        now.year,
        now.month,
        now.day + daysUntilTarget,
        notificationTime.hour,
        notificationTime.minute,
      );

      // 今日の場合で、時刻が過ぎていたら来週に
      if (dayOfWeek == now.weekday) {
        nextNotification = DateTime(
          now.year,
          now.month,
          now.day,
          notificationTime.hour,
          notificationTime.minute,
        );
        
        if (nextNotification.isBefore(now)) {
          nextNotification = nextNotification.add(const Duration(days: 7));
        }
      }

      final alarmId = '${habit.id}_$dayOfWeek'.hashCode;
      
      debugPrint('Scheduling weekly native alarm: $alarmId for day $dayOfWeek');
      debugPrint('Next notification: $nextNotification');

      try {
        await _methodChannel.invokeMethod('scheduleAlarm', {
          'alarmId': alarmId,
          'triggerTimeMillis': nextNotification.millisecondsSinceEpoch,
          'habitId': habit.id,
          'habitTitle': habit.title,
          'frequency': 'weekly',
          'dayOfWeek': dayOfWeek,
        });

        debugPrint('Weekly native alarm scheduled for day $dayOfWeek');
      } catch (e) {
        debugPrint('Error scheduling weekly native alarm for day $dayOfWeek: $e');
      }
    }
    
    debugPrint('All weekly native alarms scheduled for habit: ${habit.title}');
  }

  Future<void> cancelHabitNotifications(String habitId) async {
    debugPrint('Canceling native alarms for habit: $habitId');
    
    try {
      // 日次アラーム
      await _methodChannel.invokeMethod('cancelAlarm', {
        'alarmId': habitId.hashCode,
      });
      
      // 週次アラーム（全曜日）
      for (int dayOfWeek = 1; dayOfWeek <= 7; dayOfWeek++) {
        await _methodChannel.invokeMethod('cancelAlarm', {
          'alarmId': '${habitId}_$dayOfWeek'.hashCode,
        });
      }
      
      debugPrint('All native alarms canceled for habit: $habitId');
    } catch (e) {
      debugPrint('Error canceling native alarms: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    debugPrint('Canceling all native alarms');
    try {
      await _methodChannel.invokeMethod('cancelAllAlarms');
    } catch (e) {
      debugPrint('Error canceling all native alarms: $e');
    }
  }

  Future<void> showTestNotification() async {
    await _notifications.show(
      999,
      'ネイティブテスト通知',
      'ネイティブAlarmManagerを使用したテスト通知です',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'native_habit_alarms',
          '習慣リマインダー（ネイティブ版）',
          channelDescription: 'ネイティブAlarmManagerを使用した習慣リマインダー',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  Future<void> scheduleTestNotification() async {
    final now = DateTime.now();
    final testTime = now.add(const Duration(seconds: 30));
    
    debugPrint('=== Scheduling native test alarm ===');
    debugPrint('Current time: $now');
    debugPrint('Test time: $testTime');
    debugPrint('Delay: ${testTime.difference(now).inSeconds} seconds');
    
    try {
      await _methodChannel.invokeMethod('scheduleAlarm', {
        'alarmId': 88888,
        'triggerTimeMillis': testTime.millisecondsSinceEpoch,
        'habitId': 'test',
        'habitTitle': 'ネイティブテスト（30秒後）',
        'frequency': 'test',
      });
      
      debugPrint('Native test alarm scheduled successfully');
    } catch (e) {
      debugPrint('Error scheduling native test alarm: $e');
      rethrow;
    }
  }

  Future<String> getAlarmManagerStatus() async {
    try {
      final status = await _methodChannel.invokeMethod('getStatus');
      return status.toString();
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// 通知許可状態をチェック
  Future<bool> isNotificationPermissionGranted() async {
    final status = await Permission.notification.status;
    debugPrint('Notification permission status: $status');
    return status.isGranted;
  }

  /// システム設定画面を開く
  Future<void> openSettings() async {
    debugPrint('Opening app settings...');
    await openAppSettings();
  }
}