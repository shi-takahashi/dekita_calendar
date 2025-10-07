import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/habit_controller.dart';
import '../models/habit.dart';
import '../services/notification_service.dart';
import '../services/alarm_notification_service.dart';
import '../services/simple_notification_service.dart';
import '../services/improved_notification_service.dart';
import '../services/workmanager_notification_service.dart';
import '../services/native_alarm_notification_service.dart';
import '../test_simple_alarm.dart';
import '../debug_notification_screen.dart';
import 'edit_habit_screen.dart';
import 'add_habit_screen.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('習慣管理'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<HabitController>(
        builder: (context, habitController, child) {
          if (habitController.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (habitController.habits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '習慣がありません',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '新しい習慣を追加してみましょう',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddHabitScreen(
                            habitController: habitController,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('習慣を追加'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => habitController.loadHabits(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: habitController.habits.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _NotificationSettingsCard();
                }
                
                final habit = habitController.habits[index - 1];
                return _HabitManageCard(
                  habit: habit,
                  habitController: habitController,
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddHabitScreen(
                habitController: Provider.of<HabitController>(context, listen: false),
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HabitManageCard extends StatelessWidget {
  final Habit habit;
  final HabitController habitController;

  const _HabitManageCard({
    required this.habit,
    required this.habitController,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      _buildFrequencyChip(),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'edit':
                        await _editHabit(context);
                        break;
                      case 'delete':
                        await _deleteHabit(context);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('編集'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('削除', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem(
                  icon: Icons.local_fire_department,
                  label: '現在の連続記録',
                  value: '${habit.currentStreak}日',
                  color: habit.currentStreak > 0 ? Colors.orange : Colors.grey,
                ),
                const SizedBox(width: 24),
                _buildStatItem(
                  icon: Icons.calendar_today,
                  label: '作成日',
                  value: _formatDate(habit.createdAt),
                  color: Colors.blue,
                ),
              ],
            ),
            if (habit.notificationTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.notifications,
                    size: 16,
                    color: Colors.green[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '通知: ${_formatTime(habit.notificationTime!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green[600],
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyChip() {
    String frequencyText;
    Color chipColor;
    
    switch (habit.frequency) {
      case HabitFrequency.daily:
        frequencyText = '毎日';
        chipColor = Colors.blue;
        break;
      case HabitFrequency.specificDays:
        final days = ['月', '火', '水', '木', '金', '土', '日'];
        final selectedDays = habit.specificDays!
            .map((day) => days[day - 1])
            .join(',');
        frequencyText = selectedDays;
        chipColor = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Text(
        frequencyText,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _editHabit(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditHabitScreen(
          habitController: habitController,
          habit: habit,
        ),
      ),
    );
  }

  Future<void> _deleteHabit(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('習慣を削除'),
        content: Text('「${habit.title}」を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await habitController.deleteHabit(habit.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('習慣を削除しました')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラーが発生しました: $e')),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _NotificationSettingsCard extends StatefulWidget {
  @override
  State<_NotificationSettingsCard> createState() => _NotificationSettingsCardState();
}

class _NotificationSettingsCardState extends State<_NotificationSettingsCard> {
  bool _canScheduleExactNotifications = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final canSchedule = await NotificationService().canScheduleExactNotifications();
    if (mounted) {
      setState(() {
        _canScheduleExactNotifications = canSchedule;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '通知設定',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '習慣のリマインダー通知を管理できます',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            if (!_canScheduleExactNotifications) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '正確な時刻での通知には権限が必要です',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            if (!_canScheduleExactNotifications) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await NotificationService().requestExactAlarmPermission();
                    await _checkPermissions();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('権限リクエストを送信しました')),
                      );
                    }
                  },
                  icon: const Icon(Icons.security),
                  label: const Text('通知権限を許可'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // ネイティブAlarmManagerテストボタン（最優先・最確実）
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final nativeService = NativeAlarmNotificationService();
                  await nativeService.scheduleTestNotification();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ネイティブAlarmManager30秒テスト開始（最確実）')),
                    );
                  }
                },
                icon: const Icon(Icons.alarm),
                label: const Text('ネイティブAlarmManager30秒テスト（最確実）'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // WorkManagerテストボタン（問題があったので一時的に非表示）
            // SizedBox(
            //   width: double.infinity,
            //   child: ElevatedButton.icon(
            //     onPressed: () async {
            //       final workService = WorkManagerNotificationService();
            //       await workService.scheduleTestNotification();
            //       if (context.mounted) {
            //         ScaffoldMessenger.of(context).showSnackBar(
            //           const SnackBar(content: Text('WorkManager30秒テスト開始')),
            //         );
            //       }
            //     },
            //     icon: const Icon(Icons.work),
            //     label: const Text('WorkManager30秒テスト'),
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.indigo,
            //       foregroundColor: Colors.white,
            //     ),
            //   ),
            // ),
            const SizedBox(height: 8),
            // 改善版テストボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final improvedService = ImprovedNotificationService();
                  await improvedService.scheduleTestNotificationImproved();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('改善版30秒テスト開始')),
                    );
                  }
                },
                icon: const Icon(Icons.new_releases),
                label: const Text('改善版30秒テスト'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await SimpleNotificationService.showImmediateTest();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('即座テスト実行')),
                        );
                      }
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('即座テスト'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await SimpleNotificationService.scheduleIn30Seconds();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('シンプル30秒テスト開始')),
                        );
                      }
                    },
                    icon: const Icon(Icons.schedule),
                    label: const Text('シンプル30秒'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await SimpleNotificationService.scheduleWithDateTime();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ミニマル版テスト開始')),
                        );
                      }
                    },
                    icon: const Icon(Icons.access_time),
                    label: const Text('ミニマル版'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TestSimpleAlarm(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.science),
                    label: const Text('詳細テスト'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // デバッグ画面ボタン（最重要）
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DebugNotificationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.bug_report),
                label: const Text('🔥 フルデバッグ画面（問題解析）'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final notifications = await NotificationService().getPendingNotifications();
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('予約済み通知'),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: notifications.isEmpty
                                  ? const Text('予約済みの通知はありません')
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: notifications.length,
                                      itemBuilder: (context, index) {
                                        final notification = notifications[index];
                                        return ListTile(
                                          title: Text(notification.title ?? 'タイトルなし'),
                                          subtitle: Text(
                                            'ID: ${notification.id}\n'
                                            'Body: ${notification.body ?? ""}\n'
                                            'Payload: ${notification.payload ?? ""}',
                                          ),
                                          dense: true,
                                        );
                                      },
                                    ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('閉じる'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.schedule),
                    label: const Text('予約通知確認'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await AlarmNotificationService().scheduleTestAlarm();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('30秒後にアラームテストを予約しました'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.timer),
                    label: const Text('アラームテスト'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await NotificationService().testAlarmManager();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('AlarmManagerテストを実行しました（30秒後にアプリが起動）'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.alarm, color: Colors.orange),
                label: const Text('AlarmManagerテスト', style: TextStyle(color: Colors.orange)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('すべての通知をキャンセル'),
                      content: const Text('すべての習慣通知をキャンセルしますか？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('すべてキャンセル'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await NotificationService().cancelAllNotifications();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('すべての通知をキャンセルしました')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.notifications_off, color: Colors.red),
                label: const Text('すべての通知をキャンセル', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}