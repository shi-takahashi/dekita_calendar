import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/simple_notification_service.dart';
import 'services/improved_notification_service.dart';

class TestSimpleAlarm extends StatefulWidget {
  @override
  State<TestSimpleAlarm> createState() => _TestSimpleAlarmState();
}

class _TestSimpleAlarmState extends State<TestSimpleAlarm> {
  static const platform = MethodChannel('simple_alarm_test');
  final _improvedService = ImprovedNotificationService();
  String _statusText = '通知テストの準備完了';

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await ImprovedNotificationService.initialize();
      setState(() {
        _statusText = '改善版通知サービス初期化完了';
      });
    } catch (e) {
      setState(() {
        _statusText = 'サービス初期化エラー: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通知テスト - 改善版')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _statusText,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // 即時通知テスト
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('即時通知テスト', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await _improvedService.showTestNotification();
                          _showMessage('即時通知を送信しました（改善版）');
                        } catch (e) {
                          _showMessage('即時通知エラー: $e');
                        }
                      },
                      child: const Text('即時通知テスト（改善版）'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await SimpleNotificationService.showImmediateTest();
                          _showMessage('即時通知を送信しました（従来版）');
                        } catch (e) {
                          _showMessage('即時通知エラー: $e');
                        }
                      },
                      child: const Text('即時通知テスト（従来版）'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // スケジュール通知テスト
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('スケジュール通知テスト（30秒後）', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await _improvedService.scheduleTestNotificationImproved();
                          _showMessage('30秒後の通知をスケジュールしました（改善版）');
                        } catch (e) {
                          _showMessage('スケジュール通知エラー（改善版）: $e');
                        }
                      },
                      child: const Text('30秒後通知（改善版 - exactAllowWhileIdle）'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await SimpleNotificationService.scheduleIn30Seconds();
                          _showMessage('30秒後の通知をスケジュールしました（従来版）');
                        } catch (e) {
                          _showMessage('スケジュール通知エラー（従来版）: $e');
                        }
                      },
                      child: const Text('30秒後通知（従来版）'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await SimpleNotificationService.scheduleWithDateTime();
                          _showMessage('30秒後の通知をスケジュールしました（ミニマル版）');
                        } catch (e) {
                          _showMessage('スケジュール通知エラー（ミニマル版）: $e');
                        }
                      },
                      child: const Text('30秒後通知（ミニマル設定）'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 権限と状態確認
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('権限・状態確認', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final canSchedule = await _improvedService.canScheduleExactNotifications();
                          final pending = await _improvedService.getPendingNotifications();
                          setState(() {
                            _statusText = 'Exact Alarm権限: $canSchedule\n'
                                       '予約済み通知: ${pending.length}件\n'
                                       '詳細: ${pending.map((n) => '${n.id}: ${n.title}').join(', ')}';
                          });
                        } catch (e) {
                          _showMessage('権限確認エラー: $e');
                        }
                      },
                      child: const Text('権限・予約済み通知確認'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await _improvedService.requestExactAlarmPermission();
                          _showMessage('Exact Alarm権限をリクエストしました');
                        } catch (e) {
                          _showMessage('権限リクエストエラー: $e');
                        }
                      },
                      child: const Text('Exact Alarm権限リクエスト'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await _improvedService.cancelAllNotifications();
                          _showMessage('全通知をキャンセルしました');
                        } catch (e) {
                          _showMessage('通知キャンセルエラー: $e');
                        }
                      },
                      child: const Text('全通知キャンセル'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // ネイティブAlarmテスト（従来版）
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('ネイティブAlarmテスト', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final result = await platform.invokeMethod('setAlarmIn30Seconds');
                          _showMessage('ネイティブアラーム設定: $result');
                        } catch (e) {
                          _showMessage('ネイティブアラームエラー: $e');
                        }
                      },
                      child: const Text('ネイティブアラーム (30秒後)'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    setState(() {
      _statusText = message;
    });
  }
}