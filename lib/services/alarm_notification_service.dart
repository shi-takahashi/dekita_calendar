import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../models/habit.dart';

class AlarmNotificationService {
  static final AlarmNotificationService _instance = AlarmNotificationService._internal();
  factory AlarmNotificationService() => _instance;
  AlarmNotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // flutter_local_notificationsの初期化（通知表示用）
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

    await _notifications.initialize(initSettings);

    // Android Alarm Managerの初期化
    if (defaultTargetPlatform == TargetPlatform.android) {
      await AndroidAlarmManager.initialize();
      debugPrint('Android Alarm Manager initialized');
    }

    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
      
      debugPrint('Permissions requested for AlarmNotificationService');
    }
  }

  // バックグラウンドで実行される通知関数
  @pragma('vm:entry-point')
  static Future<void> showHabitNotification() async {
    debugPrint('Background alarm triggered - showing notification');
    
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '習慣のお時間です',
      '習慣を実行する時間になりました！',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_alarms',
          '習慣アラーム',
          channelDescription: 'アラームマネージャーを使用した習慣リマインダー',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  Future<void> scheduleHabitNotifications(Habit habit) async {
    if (habit.notificationTime == null) {
      debugPrint('No notification time set for habit: ${habit.title}');
      return;
    }

    debugPrint('Scheduling alarm for habit: ${habit.title}');
    debugPrint('Notification time: ${habit.notificationTime!.hour}:${habit.notificationTime!.minute}');

    // 既存のアラームをキャンセル
    await cancelHabitNotifications(habit.id);

    if (defaultTargetPlatform == TargetPlatform.android) {
      final now = DateTime.now();
      final notificationTime = habit.notificationTime!;
      
      switch (habit.frequency) {
        case HabitFrequency.daily:
          await _scheduleDailyAlarm(habit, notificationTime);
          break;
        case HabitFrequency.specificDays:
          if (habit.specificDays != null) {
            await _scheduleWeeklyAlarms(habit, notificationTime, habit.specificDays!);
          }
          break;
      }
    }
  }

  Future<void> _scheduleDailyAlarm(Habit habit, DateTime notificationTime) async {
    final now = DateTime.now();
    var nextAlarm = DateTime(
      now.year,
      now.month,
      now.day,
      notificationTime.hour,
      notificationTime.minute,
    );

    if (nextAlarm.isBefore(now) || nextAlarm.isAtSameMomentAs(now)) {
      nextAlarm = nextAlarm.add(const Duration(days: 1));
    }

    final alarmId = habit.id.hashCode;
    debugPrint('Scheduling daily alarm ID: $alarmId for ${nextAlarm}');

    try {
      await AndroidAlarmManager.oneShotAt(
        nextAlarm,
        alarmId,
        showHabitNotification,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );
      
      debugPrint('Daily alarm scheduled successfully');
      
      // 次の日のアラームも予約
      await AndroidAlarmManager.oneShotAt(
        nextAlarm.add(const Duration(days: 1)),
        alarmId + 1000000, // 別のIDを使用
        () => _rescheduleDaily(habit),
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );
      
    } catch (e) {
      debugPrint('Error scheduling daily alarm: $e');
    }
  }

  Future<void> _scheduleWeeklyAlarms(Habit habit, DateTime notificationTime, List<int> specificDays) async {
    final now = DateTime.now();

    for (final dayOfWeek in specificDays) {
      int daysUntilTarget = dayOfWeek - now.weekday;
      if (daysUntilTarget <= 0) {
        daysUntilTarget += 7;
      }

      var nextAlarm = DateTime(
        now.year,
        now.month,
        now.day + daysUntilTarget,
        notificationTime.hour,
        notificationTime.minute,
      );

      // 今日の場合で、時刻が過ぎていたら来週に
      if (dayOfWeek == now.weekday) {
        nextAlarm = DateTime(
          now.year,
          now.month,
          now.day,
          notificationTime.hour,
          notificationTime.minute,
        );
        
        if (nextAlarm.isBefore(now) || nextAlarm.isAtSameMomentAs(now)) {
          nextAlarm = nextAlarm.add(const Duration(days: 7));
        }
      }

      final alarmId = '${habit.id}_$dayOfWeek'.hashCode;
      debugPrint('Scheduling weekly alarm ID: $alarmId for day $dayOfWeek at $nextAlarm');

      try {
        await AndroidAlarmManager.oneShotAt(
          nextAlarm,
          alarmId,
          showHabitNotification,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
        );

        // 来週の同じ曜日のアラームも予約
        await AndroidAlarmManager.oneShotAt(
          nextAlarm.add(const Duration(days: 7)),
          alarmId + 1000000, // 別のIDを使用
          () => _rescheduleWeekly(habit, dayOfWeek),
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
        );
        
      } catch (e) {
        debugPrint('Error scheduling weekly alarm for day $dayOfWeek: $e');
      }
    }
    
    debugPrint('All weekly alarms scheduled for habit: ${habit.title}');
  }

  @pragma('vm:entry-point')
  static Future<void> _rescheduleDaily(Habit habit) async {
    // 翌日のアラームを再スケジュール
    final service = AlarmNotificationService();
    await service.scheduleHabitNotifications(habit);
  }

  @pragma('vm:entry-point')
  static Future<void> _rescheduleWeekly(Habit habit, int dayOfWeek) async {
    // 来週の同じ曜日のアラームを再スケジュール
    final service = AlarmNotificationService();
    await service.scheduleHabitNotifications(habit);
  }

  Future<void> cancelHabitNotifications(String habitId) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      debugPrint('Canceling alarms for habit: $habitId');
      
      // 基本アラーム
      await AndroidAlarmManager.cancel(habitId.hashCode);
      
      // リスケジュール用アラーム
      await AndroidAlarmManager.cancel(habitId.hashCode + 1000000);
      
      // 曜日別アラーム
      for (int dayOfWeek = 1; dayOfWeek <= 7; dayOfWeek++) {
        final alarmId = '${habitId}_$dayOfWeek'.hashCode;
        await AndroidAlarmManager.cancel(alarmId);
        await AndroidAlarmManager.cancel(alarmId + 1000000);
      }
      
      debugPrint('All alarms canceled for habit: $habitId');
    }
  }

  Future<void> cancelAllNotifications() async {
    // AndroidAlarmManagerには全キャンセル機能がないため、
    // 必要に応じて個別にキャンセルする
    debugPrint('Cancel all alarms - implement as needed');
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
      ),
    );
  }

  Future<void> scheduleTestAlarm() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final testTime = DateTime.now().add(const Duration(seconds: 30));
      debugPrint('Scheduling test alarm for: $testTime');
      
      try {
        await AndroidAlarmManager.oneShotAt(
          testTime,
          777,
          showHabitNotification,
          exact: true,
          wakeup: true,
        );
        
        debugPrint('Test alarm scheduled successfully');
      } catch (e) {
        debugPrint('Error scheduling test alarm: $e');
      }
    }
  }
}