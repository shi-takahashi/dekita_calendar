import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/habit.dart';
import '../controllers/habit_controller.dart';
import '../services/native_alarm_notification_service.dart';

class AddHabitScreen extends StatefulWidget {
  final HabitController habitController;

  const AddHabitScreen({
    Key? key,
    required this.habitController,
  }) : super(key: key);

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  
  HabitFrequency _selectedFrequency = HabitFrequency.daily;
  List<int> _selectedDays = [];
  TimeOfDay? _notificationTime;
  bool _enableNotification = false;
  DateTime? _startDate = DateTime.now();
  DateTime? _endDate;

  final List<String> _weekDays = [
    '月', '火', '水', '木', '金', '土', '日'
  ];

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

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
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

      final habit = Habit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        frequency: _selectedFrequency,
        specificDays: _selectedFrequency == HabitFrequency.specificDays ? _selectedDays : null,
        notificationTime: notificationDateTime,
        completedDates: [],
        createdAt: now,
        updatedAt: now,
        startDate: _startDate,
        endDate: _endDate,
      );

      try {
        await widget.habitController.addHabit(habit);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('習慣を追加しました')),
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
        title: const Text('新しい習慣'),
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

            const SizedBox(height: 24),

            const Text(
              '期間設定',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ListTile(
              title: const Text('開始日'),
              subtitle: _startDate != null
                  ? Text('${_startDate!.year}年${_startDate!.month}月${_startDate!.day}日')
                  : const Text('指定なし（過去すべて）'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_startDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                        });
                      },
                    ),
                  const Icon(Icons.calendar_today),
                ],
              ),
              onTap: _selectStartDate,
            ),

            ListTile(
              title: const Text('終了日'),
              subtitle: _endDate != null
                  ? Text('${_endDate!.year}年${_endDate!.month}月${_endDate!.day}日')
                  : const Text('指定なし'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_endDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _endDate = null;
                        });
                      },
                    ),
                  const Icon(Icons.calendar_today),
                ],
              ),
              onTap: _selectEndDate,
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
                    child: const Text('追加'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}