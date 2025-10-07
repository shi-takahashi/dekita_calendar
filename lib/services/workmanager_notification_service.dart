import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import '../models/habit.dart';

class WorkManagerNotificationService {
  static final WorkManagerNotificationService _instance = WorkManagerNotificationService._internal();
  factory WorkManagerNotificationService() => _instance;
  WorkManagerNotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('=== Initializing WorkManagerNotificationService ===');
    
    // WorkManagerの初期化
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    debugPrint('WorkManager initialized');

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

    // Androidチャンネル作成
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      const AndroidNotificationChannel workChannel = AndroidNotificationChannel(
        'workmanager_habits',
        '習慣リマインダー（WorkManager版）',
        description: 'WorkManagerを使用した習慣リマインダー',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      
      await androidImplementation?.createNotificationChannel(workChannel);
      debugPrint('WorkManager notification channel created');
    }

    await _requestPermissions();
    _initialized = true;
    debugPrint('WorkManagerNotificationService initialized successfully');
  }

  static Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      final bool? notificationPermission = await androidImplementation?.requestNotificationsPermission();
      debugPrint('WorkManager Notification permission granted: $notificationPermission');
    }
  }

  Future<void> scheduleHabitNotifications(Habit habit) async {
    debugPrint('=== Scheduling WorkManager notifications for habit: ${habit.title} ===');
    debugPrint('Habit ID: ${habit.id}');
    debugPrint('Notification time: ${habit.notificationTime}');
    debugPrint('Frequency: ${habit.frequency}');
    
    if (habit.notificationTime == null) {
      debugPrint('No notification time set, skipping...');
      return;
    }

    // 既存のワークをキャンセル
    await cancelHabitNotifications(habit.id);

    final notificationTime = habit.notificationTime!;
    final now = DateTime.now();

    switch (habit.frequency) {
      case HabitFrequency.daily:
        await _scheduleDailyWork(habit, notificationTime, now);
        break;
      case HabitFrequency.specificDays:
        if (habit.specificDays != null) {
          await _scheduleWeeklyWork(habit, notificationTime, habit.specificDays!, now);
        }
        break;
    }
  }

  Future<void> _scheduleDailyWork(Habit habit, DateTime notificationTime, DateTime now) async {
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

    final delay = nextNotification.difference(now);
    final workName = 'habit_daily_${habit.id}';
    
    debugPrint('Scheduling daily work: $workName');
    debugPrint('Next notification: $nextNotification');
    debugPrint('Delay: ${delay.inMinutes} minutes');

    await Workmanager().registerOneOffTask(
      workName,
      'showHabitNotification',
      initialDelay: delay,
      inputData: {
        'habitId': habit.id,
        'habitTitle': habit.title,
        'notificationTime': notificationTime.toIso8601String(),
        'frequency': 'daily',
      },
      constraints: Constraints(
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );

    debugPrint('Daily work scheduled successfully for habit: ${habit.title}');
  }

  Future<void> _scheduleWeeklyWork(Habit habit, DateTime notificationTime, List<int> specificDays, DateTime now) async {
    debugPrint('Scheduling weekly work for habit: ${habit.title}');
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

      final delay = nextNotification.difference(now);
      final workName = 'habit_weekly_${habit.id}_$dayOfWeek';
      
      debugPrint('Scheduling weekly work: $workName for day $dayOfWeek');
      debugPrint('Next notification: $nextNotification');
      debugPrint('Delay: ${delay.inMinutes} minutes');

      await Workmanager().registerOneOffTask(
        workName,
        'showHabitNotification',
        initialDelay: delay,
        inputData: {
          'habitId': habit.id,
          'habitTitle': habit.title,
          'notificationTime': notificationTime.toIso8601String(),
          'frequency': 'weekly',
          'dayOfWeek': dayOfWeek,
        },
        constraints: Constraints(
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      debugPrint('Weekly work scheduled for day $dayOfWeek');
    }
    
    debugPrint('All weekly work scheduled for habit: ${habit.title}');
  }

  Future<void> cancelHabitNotifications(String habitId) async {
    debugPrint('Canceling WorkManager tasks for habit: $habitId');
    
    // 日次ワーク
    await Workmanager().cancelByUniqueName('habit_daily_$habitId');
    
    // 週次ワーク（全曜日）
    for (int dayOfWeek = 1; dayOfWeek <= 7; dayOfWeek++) {
      await Workmanager().cancelByUniqueName('habit_weekly_${habitId}_$dayOfWeek');
    }
    
    debugPrint('All WorkManager tasks canceled for habit: $habitId');
  }

  Future<void> cancelAllNotifications() async {
    debugPrint('Canceling all WorkManager tasks');
    await Workmanager().cancelAll();
  }

  Future<void> showTestNotification() async {
    await _notifications.show(
      999,
      'WorkManagerテスト通知',
      'WorkManagerを使用したテスト通知です',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'workmanager_habits',
          '習慣リマインダー（WorkManager版）',
          channelDescription: 'WorkManagerを使用した習慣リマインダー',
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
    final delay = testTime.difference(now);
    
    debugPrint('=== Scheduling WorkManager test notification ===');
    debugPrint('Current time: $now');
    debugPrint('Test time: $testTime');
    debugPrint('Delay: ${delay.inSeconds} seconds');
    
    try {
      await Workmanager().registerOneOffTask(
        'test_notification_30s',
        'showTestNotification',
        initialDelay: delay,
        inputData: {
          'title': 'WorkManagerテスト（30秒後）',
          'body': '予定: ${testTime.hour}:${testTime.minute.toString().padLeft(2, '0')} 現在: ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
        },
        constraints: Constraints(
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
      
      debugPrint('WorkManager test notification scheduled successfully');
    } catch (e) {
      debugPrint('Error scheduling WorkManager test notification: $e');
      rethrow;
    }
  }
}

// WorkManagerのコールバック関数（トップレベル関数である必要がある）
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('=== WorkManager task executing: $task ===');
    debugPrint('Input data: $inputData');
    
    try {
      // flutter_local_notificationsを初期化
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );
      
      final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
      await notifications.initialize(initSettings);
      
      // チャンネル作成
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      const AndroidNotificationChannel workChannel = AndroidNotificationChannel(
        'workmanager_habits',
        '習慣リマインダー（WorkManager版）',
        description: 'WorkManagerを使用した習慣リマインダー',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      
      await androidImplementation?.createNotificationChannel(workChannel);
      
      if (task == 'showHabitNotification') {
        final habitTitle = inputData?['habitTitle'] ?? '習慣';
        final habitId = inputData?['habitId'] ?? 'unknown';
        
        await notifications.show(
          habitId.hashCode,
          '習慣のお時間です',
          '${habitTitle}の時間になりました！',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'workmanager_habits',
              '習慣リマインダー（WorkManager版）',
              channelDescription: 'WorkManagerを使用した習慣リマインダー',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              playSound: true,
              enableVibration: true,
              enableLights: true,
            ),
          ),
        );
        
        debugPrint('Habit notification shown: $habitTitle');
        
        // 日次の場合は次の日もスケジュール
        if (inputData?['frequency'] == 'daily') {
          // 次の日の通知をスケジュール（簡単な実装）
          // 実際のプロダクションでは、より複雑な再スケジュール機能が必要
          debugPrint('Daily habit notification completed, should reschedule for tomorrow');
        }
        
      } else if (task == 'showTestNotification') {
        final title = inputData?['title'] ?? 'WorkManagerテスト';
        final body = inputData?['body'] ?? 'WorkManagerからのテスト通知';
        
        await notifications.show(
          999,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'workmanager_habits',
              '習慣リマインダー（WorkManager版）',
              channelDescription: 'WorkManagerを使用した習慣リマインダー',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              playSound: true,
              enableVibration: true,
              enableLights: true,
            ),
          ),
        );
        
        debugPrint('Test notification shown: $title');
      }
      
      debugPrint('WorkManager task completed successfully: $task');
      return Future.value(true);
      
    } catch (e, stackTrace) {
      debugPrint('Error in WorkManager task: $e');
      debugPrint('Stack trace: $stackTrace');
      return Future.value(false);
    }
  });
}