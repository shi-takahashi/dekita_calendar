import 'package:flutter/material.dart';
import 'services/debug_notification_service.dart';
import 'services/improved_notification_service.dart';
import 'services/simple_notification_service.dart';

class DebugNotificationScreen extends StatefulWidget {
  @override
  State<DebugNotificationScreen> createState() => _DebugNotificationScreenState();
}

class _DebugNotificationScreenState extends State<DebugNotificationScreen> {
  String _debugLog = 'デバッグログが表示されます';
  List<String> _logEntries = [];

  @override
  void initState() {
    super.initState();
    _initializeDebugService();
  }

  Future<void> _initializeDebugService() async {
    try {
      await DebugNotificationService.initialize();
      _addLog('✅ DebugNotificationService initialized');
    } catch (e) {
      _addLog('❌ Error initializing DebugNotificationService: $e');
    }
  }

  void _addLog(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _logEntries.insert(0, '[$timestamp] $message');
      _debugLog = _logEntries.take(20).join('\n'); // 最新20件を表示
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知デバッグ画面'),
        backgroundColor: Colors.red.shade100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // デバッグログ表示
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugLog,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // テストボタン群
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 即時テスト
                    _buildTestCard(
                      'IMMEDIATE TESTS',
                      Colors.green,
                      [
                        _buildTestButton(
                          'Debug即時テスト',
                          Colors.green,
                          () async {
                            try {
                              await DebugNotificationService.showImmediateDebugTest();
                              _addLog('✅ Debug immediate test sent');
                            } catch (e) {
                              _addLog('❌ Debug immediate test error: $e');
                            }
                          },
                        ),
                        _buildTestButton(
                          '改善版即時テスト',
                          Colors.green.shade300,
                          () async {
                            try {
                              final service = ImprovedNotificationService();
                              await service.showTestNotification();
                              _addLog('✅ Improved immediate test sent');
                            } catch (e) {
                              _addLog('❌ Improved immediate test error: $e');
                            }
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // スケジュールテスト
                    _buildTestCard(
                      'SCHEDULED TESTS (30秒後)',
                      Colors.purple,
                      [
                        _buildTestButton(
                          'フルデバッグテスト',
                          Colors.red,
                          () async {
                            try {
                              _addLog('🔥 Starting full debug test...');
                              await DebugNotificationService.scheduleTestWithFullDebugging();
                              _addLog('✅ Full debug test completed');
                            } catch (e) {
                              _addLog('❌ Full debug test error: $e');
                            }
                          },
                        ),
                        _buildTestButton(
                          '改善版スケジュール',
                          Colors.purple,
                          () async {
                            try {
                              final service = ImprovedNotificationService();
                              await service.scheduleTestNotificationImproved();
                              _addLog('✅ Improved scheduled test set');
                            } catch (e) {
                              _addLog('❌ Improved scheduled test error: $e');
                            }
                          },
                        ),
                        _buildTestButton(
                          'Simple30秒テスト',
                          Colors.purple.shade300,
                          () async {
                            try {
                              await SimpleNotificationService.scheduleIn30Seconds();
                              _addLog('✅ Simple 30s test set');
                            } catch (e) {
                              _addLog('❌ Simple 30s test error: $e');
                            }
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 管理・確認
                    _buildTestCard(
                      'MANAGEMENT & STATUS',
                      Colors.blue,
                      [
                        _buildTestButton(
                          '予約済み通知確認',
                          Colors.blue,
                          () async {
                            try {
                              final pending = await DebugNotificationService.getPendingNotifications();
                              _addLog('📱 Pending notifications: ${pending.length}');
                              for (final notif in pending) {
                                _addLog('   - ID: ${notif.id}, Title: ${notif.title}');
                              }
                              if (pending.isEmpty) {
                                _addLog('⚠️ NO PENDING NOTIFICATIONS FOUND');
                              }
                            } catch (e) {
                              _addLog('❌ Error checking pending notifications: $e');
                            }
                          },
                        ),
                        _buildTestButton(
                          '権限状況確認',
                          Colors.blue.shade300,
                          () async {
                            try {
                              final service = ImprovedNotificationService();
                              final canSchedule = await service.canScheduleExactNotifications();
                              _addLog('🔐 Can schedule exact: $canSchedule');
                            } catch (e) {
                              _addLog('❌ Error checking permissions: $e');
                            }
                          },
                        ),
                        _buildTestButton(
                          '全通知キャンセル',
                          Colors.orange,
                          () async {
                            try {
                              await DebugNotificationService.cancelAllDebugNotifications();
                              final service = ImprovedNotificationService();
                              await service.cancelAllNotifications();
                              _addLog('🗑️ All notifications canceled');
                            } catch (e) {
                              _addLog('❌ Error canceling notifications: $e');
                            }
                          },
                        ),
                        _buildTestButton(
                          'ログクリア',
                          Colors.grey,
                          () {
                            setState(() {
                              _logEntries.clear();
                              _debugLog = 'ログをクリアしました';
                            });
                          },
                        ),
                      ],
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

  Widget _buildTestCard(String title, Color color, List<Widget> children) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String label, Color color, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        child: Text(label),
      ),
    );
  }
}