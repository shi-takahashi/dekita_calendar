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
                    Text(
                      habit.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            decoration:
                                isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted ? Colors.grey : null,
                          ),
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
}