import 'package:flutter/material.dart';
import '../controllers/habit_controller.dart';
import '../models/habit.dart';
import 'add_habit_screen.dart';
import 'edit_habit_screen.dart';

class HomeView extends StatefulWidget {
  final HabitController habitController;

  const HomeView({
    super.key,
    required this.habitController,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.habitController.loadHabits();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('今日の習慣'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              DefaultTabController.of(context)!.animateTo(1);
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.habitController,
        builder: (context, child) {
          if (widget.habitController.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final todayHabits = widget.habitController.getTodayHabits();

          if (todayHabits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '今日の習慣はありません',
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
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => widget.habitController.loadHabits(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: todayHabits.length,
              itemBuilder: (context, index) {
                final habit = todayHabits[index];
                final today = DateTime.now();
                final isCompleted = habit.isCompletedOnDate(today);

                return _HabitCard(
                  habit: habit,
                  isCompleted: isCompleted,
                  onTap: () async {
                    await widget.habitController.toggleHabitCompletion(
                      habit.id,
                      today,
                    );
                  },
                  onEdit: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditHabitScreen(
                          habitController: widget.habitController,
                          habit: habit,
                        ),
                      ),
                    );
                  },
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
                habitController: widget.habitController,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final bool isCompleted;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _HabitCard({
    required this.habit,
    required this.isCompleted,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isCompleted ? Colors.green[50] : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    width: 2,
                  ),
                  color: isCompleted
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            habit.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: isCompleted ? Colors.grey[600] : null,
                                ),
                          ),
                        ),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '本日完了✓',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: habit.currentStreak > 0
                              ? Colors.orange
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${habit.currentStreak}日',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(width: 16),
                        _buildFrequencyText(context),
                      ],
                    ),
                    if (habit.frequency == HabitFrequency.weekly)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _buildWeeklyProgress(context, habit),
                      ),
                    if (isCompleted)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _getNextMessage(habit),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green[700],
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: onEdit,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencyText(BuildContext context) {
    String frequencyText;
    switch (habit.frequency) {
      case HabitFrequency.daily:
        frequencyText = '毎日';
        break;
      case HabitFrequency.weekly:
        frequencyText = '週${habit.targetWeeklyCount}回';
        break;
      case HabitFrequency.specificDays:
        final days = ['月', '火', '水', '木', '金', '土', '日'];
        final selectedDays = habit.specificDays!
            .map((day) => days[day - 1])
            .join(',');
        frequencyText = selectedDays;
        break;
    }

    return Row(
      children: [
        Icon(
          Icons.repeat,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          frequencyText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  String _getNextMessage(Habit habit) {
    final today = DateTime.now();
    
    switch (habit.frequency) {
      case HabitFrequency.daily:
        return '明日も続けましょう！';
      
      case HabitFrequency.weekly:
        if (habit.isWeeklyTargetMet()) {
          return '今週の目標達成！お疲れ様でした！';
        } else {
          return '今週の目標達成に向けて頑張りましょう！';
        }
      
      case HabitFrequency.specificDays:
        final nextDate = _getNextScheduledDate(habit, today);
        if (nextDate == null) {
          return '次回も頑張りましょう！';
        }
        
        final daysDiff = nextDate.difference(today).inDays;
        if (daysDiff == 1) {
          return '明日も続けましょう！';
        } else if (daysDiff <= 7) {
          final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
          final nextWeekday = weekdays[nextDate.weekday - 1];
          return '次は${nextWeekday}曜日です！';
        } else {
          return '次回も頑張りましょう！';
        }
    }
  }

  DateTime? _getNextScheduledDate(Habit habit, DateTime today) {
    if (habit.specificDays == null || habit.specificDays!.isEmpty) {
      return null;
    }
    
    for (int i = 1; i <= 7; i++) {
      final nextDate = today.add(Duration(days: i));
      if (habit.specificDays!.contains(nextDate.weekday)) {
        return nextDate;
      }
    }
    
    return null;
  }

  Widget _buildWeeklyProgress(BuildContext context, Habit habit) {
    final completed = habit.getWeeklyCompletionCount();
    final target = habit.targetWeeklyCount ?? 0;
    final remaining = habit.getRemainingWeeklyCount();
    
    return Row(
      children: [
        Icon(
          Icons.calendar_view_week,
          size: 14,
          color: habit.isWeeklyTargetMet() ? Colors.green : Colors.blue,
        ),
        const SizedBox(width: 4),
        Text(
          habit.isWeeklyTargetMet() 
              ? '今週目標達成！($completed/$target)'
              : '今週あと${remaining}回 ($completed/$target)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: habit.isWeeklyTargetMet() ? Colors.green[700] : Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}