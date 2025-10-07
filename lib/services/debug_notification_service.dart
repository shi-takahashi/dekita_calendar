import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class DebugNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    debugPrint('=== DEBUG NOTIFICATION SERVICE INIT ===');
    
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
    
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(initSettings);
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'debug_channel',
        'Debug notifications',
        description: 'Debug channel for testing notifications.',
        importance: Importance.max,
      );

      await androidImplementation?.createNotificationChannel(channel);
      
      // 権限状況を詳しく確認
      final bool? hasNotificationPermission = await androidImplementation?.areNotificationsEnabled();
      final bool? canScheduleExact = await androidImplementation?.canScheduleExactNotifications();
      
      debugPrint('=== PERMISSION STATUS ===');
      debugPrint('Has notification permission: $hasNotificationPermission');
      debugPrint('Can schedule exact notifications: $canScheduleExact');
      
      if (hasNotificationPermission == false) {
        debugPrint('⚠️ NOTIFICATION PERMISSION NOT GRANTED');
        await androidImplementation?.requestNotificationsPermission();
      }
      
      if (canScheduleExact == false) {
        debugPrint('⚠️ EXACT ALARM PERMISSION NOT GRANTED');
        await androidImplementation?.requestExactAlarmsPermission();
      }
      
      debugPrint('=== PERMISSION CHECK COMPLETE ===');
    }
  }

  static Future<void> scheduleTestWithFullDebugging() async {
    try {
      debugPrint('');
      debugPrint('🔥🔥🔥 STARTING FULL DEBUG TEST 🔥🔥🔥');
      debugPrint('');
      
      final now = tz.TZDateTime.now(tz.local);
      final scheduledTime = now.add(const Duration(seconds: 30));
      
      debugPrint('📅 Current time: $now');
      debugPrint('📅 Scheduled time: $scheduledTime');
      debugPrint('📅 Time difference: ${scheduledTime.difference(now).inSeconds} seconds');
      debugPrint('📅 Is in future: ${scheduledTime.isAfter(now)}');
      debugPrint('📅 Timezone: ${tz.local}');
      
      // 現在の予約済み通知をチェック
      final pendingBefore = await _notifications.pendingNotificationRequests();
      debugPrint('📱 Pending notifications BEFORE: ${pendingBefore.length}');
      for (final notif in pendingBefore) {
        debugPrint('   - ID: ${notif.id}, Title: ${notif.title}');
      }
      
      // 権限を再度チェック
      if (defaultTargetPlatform == TargetPlatform.android) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        final bool? canSchedule = await androidImplementation?.canScheduleExactNotifications();
        final bool? hasPermission = await androidImplementation?.areNotificationsEnabled();
        
        debugPrint('🔐 Can schedule exact: $canSchedule');
        debugPrint('🔐 Has notification permission: $hasPermission');
        
        if (canSchedule != true) {
          debugPrint('❌ CANNOT SCHEDULE EXACT NOTIFICATIONS - REQUESTING PERMISSION');
          await androidImplementation?.requestExactAlarmsPermission();
          return;
        }
        
        if (hasPermission != true) {
          debugPrint('❌ NO NOTIFICATION PERMISSION - REQUESTING PERMISSION');
          await androidImplementation?.requestNotificationsPermission();
          return;
        }
      }
      
      debugPrint('📤 About to call zonedSchedule...');
      debugPrint('   Notification ID: 77777');
      debugPrint('   Channel: debug_channel');
      debugPrint('   AndroidScheduleMode: exactAllowWhileIdle');
      
      await _notifications.zonedSchedule(
        77777, // 固定ID
        'DEBUG TEST 🚨',
        'Debug test scheduled at ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'debug_channel',
            'Debug notifications',
            channelDescription: 'Debug channel for testing notifications.',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      
      debugPrint('✅ zonedSchedule call completed successfully');
      
      // 予約済み通知を再度チェック
      await Future.delayed(const Duration(milliseconds: 500)); // 少し待つ
      final pendingAfter = await _notifications.pendingNotificationRequests();
      debugPrint('📱 Pending notifications AFTER: ${pendingAfter.length}');
      for (final notif in pendingAfter) {
        debugPrint('   - ID: ${notif.id}, Title: ${notif.title}');
      }
      
      if (pendingAfter.isEmpty) {
        debugPrint('❌ NO PENDING NOTIFICATIONS FOUND - SCHEDULE FAILED!');
      } else {
        final ourNotification = pendingAfter.where((n) => n.id == 77777).firstOrNull;
        if (ourNotification != null) {
          debugPrint('✅ OUR NOTIFICATION IS SCHEDULED: ${ourNotification.title}');
        } else {
          debugPrint('⚠️ OUR NOTIFICATION (ID 77777) NOT FOUND IN PENDING LIST');
        }
      }
      
      debugPrint('');
      debugPrint('🔥🔥🔥 DEBUG TEST COMPLETE 🔥🔥🔥');
      debugPrint('');
      
    } catch (e, stackTrace) {
      debugPrint('💥 ERROR in scheduleTestWithFullDebugging: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<void> showImmediateDebugTest() async {
    debugPrint('📤 Showing immediate debug test notification');
    
    await _notifications.show(
      88888,
      'IMMEDIATE DEBUG TEST ✅',
      'This immediate notification should work',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'debug_channel',
          'Debug notifications',
          channelDescription: 'Debug channel for testing notifications.',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
    
    debugPrint('✅ Immediate debug test notification sent');
  }

  static Future<void> cancelAllDebugNotifications() async {
    await _notifications.cancel(77777);
    await _notifications.cancel(88888);
    debugPrint('🗑️ All debug notifications canceled');
  }

  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}