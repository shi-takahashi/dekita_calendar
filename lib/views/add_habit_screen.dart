import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/habit.dart';
import '../controllers/habit_controller.dart';

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
              onChanged: (value) {
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