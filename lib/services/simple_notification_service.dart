import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class SimpleNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    debugPrint('=== TIMEZONE INITIALIZATION ===');
    
    // タイムゾーンデータベースを初期化
    tz.initializeTimeZones();
    debugPrint('Timezone database initialized');
    
    // システムタイムゾーン情報を取得
    final systemNow = DateTime.now();
    final utcNow = DateTime.now().toUtc();
    final offsetMinutes = systemNow.timeZoneOffset.inMinutes;
    debugPrint('System DateTime.now(): $systemNow');
    debugPrint('UTC DateTime.now(): $utcNow');
    debugPrint('System timezone offset: ${offsetMinutes}minutes (${offsetMinutes/60}hours)');
    
    // 複数のタイムゾーンをテスト
    final tokyoLocation = tz.getLocation('Asia/Tokyo');
    final utcLocation = tz.getLocation('UTC');
    
    debugPrint('Tokyo location: $tokyoLocation');
    debugPrint('UTC location: $utcLocation');
    
    // Asia/Tokyoで設定
    tz.setLocalLocation(tokyoLocation);
    
    final tzNow = tz.TZDateTime.now(tz.local);
    debugPrint('TZ local location set to: ${tz.local}');
    debugPrint('TZDateTime.now(tz.local): $tzNow');
    
    // 30秒後の時刻を計算
    final future30sec = tzNow.add(const Duration(seconds: 30));
    debugPrint('30 seconds from now (TZ): $future30sec');
    debugPrint('30 seconds from now (system): ${systemNow.add(const Duration(seconds: 30))}');
    
    debugPrint('=== TIMEZONE INIT COMPLETE ===');

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(initSettings);
    
    // Android通知チャンネルを作成
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'basic_channel',
        'Basic notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
      );

      await androidImplementation?.createNotificationChannel(channel);
    }
  }

  static Future<void> scheduleIn30Seconds() async {
    try {
      debugPrint('=== DETAILED SCHEDULING DEBUG ===');
      
      final now = DateTime.now();
      final tzNow = tz.TZDateTime.now(tz.local);
      final scheduledDate = tzNow.add(const Duration(seconds: 30));
      
      debugPrint('System DateTime.now(): $now');
      debugPrint('TZDateTime.now(tz.local): $tzNow');
      debugPrint('Target scheduled time: $scheduledDate');
      debugPrint('Time difference: ${scheduledDate.difference(tzNow).inSeconds} seconds');
      debugPrint('Timezone: ${tz.local}');
      debugPrint('Is in future: ${scheduledDate.isAfter(tzNow)}');
      
      // 権限チェック
      if (defaultTargetPlatform == TargetPlatform.android) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        final bool? canScheduleExact = await androidImplementation?.canScheduleExactNotifications();
        final bool? hasNotificationPermission = await androidImplementation?.areNotificationsEnabled();
        
        debugPrint('Can schedule exact notifications: $canScheduleExact');
        debugPrint('Has notification permission: $hasNotificationPermission');
      }
      
      debugPrint('About to call zonedSchedule...');
      
      await _notifications.zonedSchedule(
        12345, // 明確なID
        '30秒後のテスト',
        'これは30秒後に配信されるテストです - ${scheduledDate.toString()}',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'basic_channel',
            'Basic notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      debugPrint('zonedSchedule call completed successfully');
      
      // スケジュール後に予約済み通知を確認
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      debugPrint('Pending notifications count: ${pendingNotifications.length}');
      
      for (final notification in pendingNotifications) {
        debugPrint('Pending notification - ID: ${notification.id}, Title: ${notification.title}');
      }
      
      debugPrint('=== END DEBUG ===');
      
    } catch (e, stackTrace) {
      debugPrint('ERROR in scheduleIn30Seconds: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<void> showImmediateTest() async {
    try {
      debugPrint('=== IMMEDIATE NOTIFICATION TEST ===');
      
      await _notifications.show(
        99999,
        '即座テスト',
        '即座に表示される通知です',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'basic_channel',
            'Basic notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
      
      debugPrint('Immediate notification shown successfully');
      
    } catch (e, stackTrace) {
      debugPrint('ERROR in showImmediateTest: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // 最もシンプルなスケジュール（設定なしzonedSchedule）
  static Future<void> scheduleWithDateTime() async {
    try {
      debugPrint('=== SIMPLE ZONED SCHEDULE TEST ===');
      
      final scheduledDate = tz.TZDateTime.from(
        DateTime.now().add(const Duration(seconds: 30)), 
        tz.local
      );
      debugPrint('Scheduling with minimal settings: $scheduledDate');
      
      await _notifications.zonedSchedule(
        54321,
        'ミニマル版テスト',
        'minimal settingsでスケジュール: ${scheduledDate.toString()}',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'basic_channel',
            'Basic notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        // 最小限の設定のみ
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      debugPrint('Minimal zonedSchedule call completed');
      
    } catch (e, stackTrace) {
      debugPrint('ERROR in scheduleWithDateTime: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}