import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../controllers/habit_controller.dart';
import '../models/habit.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late ValueNotifier<DateTime> _selectedDay;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDay = ValueNotifier(DateTime.now());
  }

  @override
  void dispose() {
    _selectedDay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カレンダー'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<HabitController>(
        builder: (context, habitController, child) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: TableCalendar<Habit>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay.value, day),
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  headerStyle: const HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    leftChevronIcon: Icon(Icons.chevron_left),
                    rightChevronIcon: Icon(Icons.chevron_right),
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    weekendTextStyle: TextStyle(color: Colors.red[400]),
                    holidayTextStyle: TextStyle(color: Colors.red[400]),
                    defaultTextStyle: const TextStyle(fontSize: 16),
                    todayDecoration: BoxDecoration(
                      color: Colors.blue[300],
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 1,
                  ),
                  eventLoader: (day) => _getHabitsForDay(habitController.habits, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay.value = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      if (events.isNotEmpty) {
                        final completedCount = _getCompletedHabitsCount(habitController.habits, day);
                        final totalCount = _getTotalScheduledHabitsCount(habitController.habits, day);
                        
                        if (totalCount == 0) return null;
                        
                        final completionRate = completedCount / totalCount;
                        Color markerColor;
                        
                        if (completionRate >= 1.0) {
                          markerColor = Colors.green;
                        } else if (completionRate >= 0.5) {
                          markerColor = Colors.orange;
                        } else if (completionRate > 0) {
                          markerColor = Colors.yellow[700]!;
                        } else {
                          markerColor = Colors.red[300]!;
                        }
                        
                        return Container(
                          margin: const EdgeInsets.only(top: 32),
                          height: 6,
                          width: 6,
                          decoration: BoxDecoration(
                            color: markerColor,
                            shape: BoxShape.circle,
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: ValueListenableBuilder<DateTime>(
                  valueListenable: _selectedDay,
                  builder: (context, selectedDay, _) {
                    final dayHabits = _getScheduledHabitsForDay(habitController.habits, selectedDay);
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '${selectedDay.month}/${selectedDay.day} (${_getWeekdayName(selectedDay.weekday)})',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        Expanded(
                          child: dayHabits.isEmpty
                              ? const Center(
                                  child: Text(
                                    'この日に予定されている習慣はありません',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: dayHabits.length,
                                  itemBuilder: (context, index) {
                                    final habit = dayHabits[index];
                                    final isCompleted = habit.isCompletedOnDate(selectedDay);
                                    
                                    return Card(
                                      child: ListTile(
                                        leading: Icon(
                                          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                          color: isCompleted ? Colors.green : Colors.grey,
                                          size: 28,
                                        ),
                                        title: Text(habit.title),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(_getFrequencyText(habit)),
                                            if (habit.frequency == HabitFrequency.weekly)
                                              Text(
                                                _getWeeklyStatus(habit, selectedDay),
                                                style: TextStyle(
                                                  color: habit.isWeeklyTargetMet(selectedDay) 
                                                      ? Colors.green[600] 
                                                      : Colors.blue[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                        trailing: isCompleted 
                                            ? Text(
                                                '完了',
                                                style: TextStyle(
                                                  color: Colors.green[600],
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : const Text(
                                                '未完了',
                                                style: TextStyle(color: Colors.grey),
                                              ),
                                        onTap: () async {
                                          if (!selectedDay.isAfter(DateTime.now())) {
                                            await habitController.toggleHabitCompletion(habit.id, selectedDay);
                                          }
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Habit> _getHabitsForDay(List<Habit> habits, DateTime day) {
    return habits.where((habit) => _isHabitScheduledForDay(habit, day)).toList();
  }

  List<Habit> _getScheduledHabitsForDay(List<Habit> habits, DateTime day) {
    return habits.where((habit) => _isHabitScheduledForDay(habit, day)).toList();
  }

  bool _isHabitScheduledForDay(Habit habit, DateTime day) {
    switch (habit.frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.weekly:
        return !habit.isWeeklyTargetMet(day) || habit.isCompletedOnDate(day);
      case HabitFrequency.specificDays:
        return habit.specificDays?.contains(day.weekday) ?? false;
    }
  }

  int _getCompletedHabitsCount(List<Habit> habits, DateTime day) {
    final scheduledHabits = _getScheduledHabitsForDay(habits, day);
    return scheduledHabits.where((habit) => habit.isCompletedOnDate(day)).length;
  }

  int _getTotalScheduledHabitsCount(List<Habit> habits, DateTime day) {
    return _getScheduledHabitsForDay(habits, day).length;
  }

  String _getWeekdayName(int weekday) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return weekdays[weekday - 1];
  }

  String _getFrequencyText(Habit habit) {
    switch (habit.frequency) {
      case HabitFrequency.daily:
        return '毎日';
      case HabitFrequency.weekly:
        return '週${habit.targetWeeklyCount}回';
      case HabitFrequency.specificDays:
        final days = habit.specificDays?.map((d) => _getWeekdayName(d)).join(', ') ?? '';
        return days;
    }
  }

  String _getWeeklyStatus(Habit habit, DateTime date) {
    final completed = habit.getWeeklyCompletionCount(date);
    final target = habit.targetWeeklyCount ?? 0;
    
    if (habit.isWeeklyTargetMet(date)) {
      return 'この週の目標達成！($completed/$target)';
    } else {
      final remaining = target - completed;
      return 'この週あと${remaining}回 ($completed/$target)';
    }
  }
}