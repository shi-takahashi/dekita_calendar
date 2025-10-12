import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/habit.dart';
import '../controllers/habit_controller.dart';
import '../services/native_alarm_notification_service.dart';

class EditHabitScreen extends StatefulWidget {
  final HabitController habitController;
  final Habit habit;

  const EditHabitScreen({
    Key? key,
    required this.habitController,
    required this.habit,
  }) : super(key: key);

  @override
  State<EditHabitScreen> createState() => _EditHabitScreenState();
}

class _EditHabitScreenState extends State<EditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  
  late HabitFrequency _selectedFrequency;
  late List<int> _selectedDays;
  TimeOfDay? _notificationTime;
  late bool _enableNotification;

  final List<String> _weekDays = [
    '月', '火', '水', '木', '金', '土', '日'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.habit.title);
    _selectedFrequency = widget.habit.frequency;
    _selectedDays = List<int>.from(widget.habit.specificDays ?? []);
    _enableNotification = widget.habit.notificationTime != null;
    
    if (widget.habit.notificationTime != null) {
      _notificationTime = TimeOfDay(
        hour: widget.habit.notificationTime!.hour,
        minute: widget.habit.notificationTime!.minute,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _notificationTime = picked;
      });
    }
  }

  Future<void> _saveHabit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedFrequency == HabitFrequency.specificDays && _selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('曜日を選択してください')),
        );
        return;
      }

      final now = DateTime.now();
      DateTime? notificationDateTime;
      
      if (_enableNotification && _notificationTime != null) {
        notificationDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          _notificationTime!.hour,
          _notificationTime!.minute,
        );
      }

      final updatedHabit = widget.habit.copyWith(
        title: _titleController.text.trim(),
        frequency: _selectedFrequency,
        specificDays: _selectedFrequency == HabitFrequency.specificDays ? _selectedDays : null,
        notificationTime: notificationDateTime,
        updatedAt: now,
      );

      try {
        await widget.habitController.updateHabit(updatedHabit);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('習慣を更新しました')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラーが発生しました: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteHabit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('習慣を削除'),
        content: Text('「${widget.habit.title}」を削除しますか？\nこの操作は取り消せません。'),
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
        await widget.habitController.deleteHabit(widget.habit.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('習慣を削除しました')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラーが発生しました: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('習慣を編集'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteHabit,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '習慣の名前',
                hintText: '例: 朝のジョギング',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '習慣の名前を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            const Text(
              '頻度',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            RadioListTile<HabitFrequency>(
              title: const Text('毎日'),
              value: HabitFrequency.daily,
              groupValue: _selectedFrequency,
              onChanged: (value) {
                setState(() {
                  _selectedFrequency = value!;
                });
              },
            ),
            
            
            RadioListTile<HabitFrequency>(
              title: const Text('特定の曜日'),
              value: HabitFrequency.specificDays,
              groupValue: _selectedFrequency,
              onChanged: (value) {
                setState(() {
                  _selectedFrequency = value!;
                });
              },
            ),
            
            if (_selectedFrequency == HabitFrequency.specificDays)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Wrap(
                  spacing: 8.0,
                  children: List.generate(7, (index) {
                    final dayNumber = index + 1;
                    return FilterChip(
                      label: Text(_weekDays[index]),
                      selected: _selectedDays.contains(dayNumber),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedDays.add(dayNumber);
                          } else {
                            _selectedDays.remove(dayNumber);
                          }
                          _selectedDays.sort();
                        });
                      },
                    );
                  }),
                ),
              ),
            
            const SizedBox(height: 24),
            
            SwitchListTile(
              title: const Text('リマインダー通知'),
              subtitle: _enableNotification && _notificationTime != null
                  ? Text('${_notificationTime!.format(context)}')
                  : null,
              value: _enableNotification,
              onChanged: (value) async {
                if (value) {
                  // ONにしようとしたときに通知許可をチェック
                  final notificationService = NativeAlarmNotificationService();
                  final isGranted = await notificationService.isNotificationPermissionGranted();

                  if (!isGranted && mounted) {
                    // 通知許可がない場合、警告ダイアログを表示
                    final shouldOpenSettings = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.notifications_off, color: Colors.orange),
                            SizedBox(width: 12),
                            Text('通知がオフです'),
                          ],
                        ),
                        content: const Text(
                          '通知が許可されていないため、リマインダーが届きません。\n\n'
                          'システムの設定画面から、このアプリの通知を許可してください。',
                          style: TextStyle(height: 1.6),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('キャンセル'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('設定を開く'),
                          ),
                        ],
                      ),
                    );

                    if (shouldOpenSettings == true) {
                      await notificationService.openSettings();
                    }
                    return; // ONにしない
                  }
                }

                setState(() {
                  _enableNotification = value;
                  if (value && _notificationTime == null) {
                    _selectTime();
                  }
                });
              },
            ),
            
            if (_enableNotification)
              ListTile(
                title: const Text('通知時間'),
                subtitle: Text(_notificationTime != null
                    ? _notificationTime!.format(context)
                    : '未設定'),
                trailing: const Icon(Icons.access_time),
                onTap: _selectTime,
              ),
            
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '統計情報',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('現在の連続記録: ${widget.habit.currentStreak}日'),
                    Text('作成日: ${_formatDate(widget.habit.createdAt)}'),
                    Text('更新日: ${_formatDate(widget.habit.updatedAt)}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('キャンセル'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveHabit,
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}