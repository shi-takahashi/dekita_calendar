import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../controllers/habit_controller.dart';
import '../models/habit.dart';
import '../models/constellation.dart';
import '../utils/japanese_calendar_utils.dart';
import '../services/ad_service.dart';
import '../services/constellation_service.dart';
import '../services/badge_service.dart';
import '../widgets/shooting_star_animation.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late ValueNotifier<DateTime> _selectedDay;
  DateTime _focusedDay = DateTime.now();
  final _constellationService = ConstellationService();
  final _badgeService = BadgeService();

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
                  locale: 'ja_JP',
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay.value, day),
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  daysOfWeekVisible: true,
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
                    markersMaxCount: 10,
                    markerSize: 6,
                    markerMargin: const EdgeInsets.symmetric(horizontal: 1),
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
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    weekendStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    headerTitleBuilder: (context, day) {
                      return Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${day.year}年${day.month}月',
                          style: const TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                    dowBuilder: (context, day) {
                      final text = JapaneseCalendarUtils.getJapaneseDayOfWeek(day);
                      Color textColor;
                      if (day.weekday == DateTime.saturday) {
                        textColor = Colors.blue[600]!; // 土曜日は青
                      } else if (day.weekday == DateTime.sunday) {
                        textColor = Colors.red[400]!; // 日曜日は赤
                      } else {
                        textColor = Colors.black87; // 平日は黒
                      }
                      
                      return Center(
                        child: Text(
                          text,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                    defaultBuilder: (context, day, focusedDay) {
                      Color textColor;
                      if (day.weekday == DateTime.saturday) {
                        textColor = Colors.blue[600]!; // 土曜日は青
                      } else if (day.weekday == DateTime.sunday) {
                        textColor = Colors.red[400]!; // 日曜日は赤
                      } else {
                        textColor = Colors.black87; // 平日は黒
                      }

                      // 完了状態を取得
                      final completedCount = _getCompletedHabitsCount(habitController.habits, day);
                      final totalCount = _getTotalScheduledHabitsCount(habitController.habits, day);
                      final hasHabits = totalCount > 0;
                      final completionRate = hasHabits ? completedCount / totalCount : 0.0;

                      Widget? stampWidget;
                      if (hasHabits && completionRate >= 1.0) {
                        // 完了100%の場合のみスタンプを表示：赤い丸に「済」
                        stampWidget = Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.red[900]!, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.4),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '済',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      // 一部完了の場合は右上には何も表示しない（下の丸で表現）

                      return Stack(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            margin: const EdgeInsets.all(6.0),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (stampWidget != null) stampWidget,
                        ],
                      );
                    },
                    todayBuilder: (context, day, focusedDay) {
                      Color textColor;
                      if (day.weekday == DateTime.saturday) {
                        textColor = Colors.blue[600]!;
                      } else if (day.weekday == DateTime.sunday) {
                        textColor = Colors.red[400]!;
                      } else {
                        textColor = Colors.black87;
                      }

                      final completedCount = _getCompletedHabitsCount(habitController.habits, day);
                      final totalCount = _getTotalScheduledHabitsCount(habitController.habits, day);
                      final hasHabits = totalCount > 0;
                      final completionRate = hasHabits ? completedCount / totalCount : 0.0;

                      Widget? stampWidget;
                      if (hasHabits && completionRate >= 1.0) {
                        // 完了100%の場合のみスタンプを表示：赤い丸に「済」
                        stampWidget = Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.red[900]!, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.4),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '済',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      // 一部完了の場合は右上には何も表示しない（下の丸で表現）

                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.blue[300],
                              shape: BoxShape.circle,
                            ),
                            margin: const EdgeInsets.all(8.0),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (stampWidget != null) stampWidget,
                        ],
                      );
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      Color textColor;
                      if (day.weekday == DateTime.saturday) {
                        textColor = Colors.blue[600]!;
                      } else if (day.weekday == DateTime.sunday) {
                        textColor = Colors.red[400]!;
                      } else {
                        textColor = Colors.black87;
                      }

                      final completedCount = _getCompletedHabitsCount(habitController.habits, day);
                      final totalCount = _getTotalScheduledHabitsCount(habitController.habits, day);
                      final hasHabits = totalCount > 0;
                      final completionRate = hasHabits ? completedCount / totalCount : 0.0;

                      Widget? stampWidget;
                      if (hasHabits && completionRate >= 1.0) {
                        // 完了100%の場合のみスタンプを表示：赤い丸に「済」
                        stampWidget = Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.red[900]!, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.4),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '済',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      // 一部完了の場合は右上には何も表示しない（下の丸で表現）

                      return Stack(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.deepPurple,
                              shape: BoxShape.circle,
                            ),
                            margin: const EdgeInsets.all(8.0),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (stampWidget != null) stampWidget,
                        ],
                      );
                    },
                    markerBuilder: (context, day, events) {
                      if (events.isEmpty) return null;

                      final completedCount = _getCompletedHabitsCount(habitController.habits, day);
                      final totalCount = _getTotalScheduledHabitsCount(habitController.habits, day);

                      if (totalCount == 0) return null;

                      // 5個以下の場合は丸印で表示
                      if (totalCount <= 5) {
                        return Container(
                          margin: const EdgeInsets.only(top: 2),
                          height: 10,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(totalCount, (index) {
                              final isCompleted = index < completedCount;
                              return Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  color: isCompleted ? Colors.green : Colors.grey[400],
                                  shape: BoxShape.circle,
                                ),
                              );
                            }),
                          ),
                        );
                      } else {
                        // 6個以上の場合は数字で表示（丸印と同じ位置・高さ）
                        return Container(
                          margin: const EdgeInsets.only(top: 2),
                          height: 10,
                          alignment: Alignment.center,
                          child: Text(
                            '$completedCount/$totalCount',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: completedCount == totalCount
                                ? Colors.green[700]
                                : completedCount > 0
                                  ? Colors.orange[700]
                                  : Colors.grey[600],
                            ),
                          ),
                        );
                      }
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
                                            await _handleHabitToggle(context, habitController, habit, selectedDay);
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
      case HabitFrequency.specificDays:
        final days = habit.specificDays?.map((d) => _getWeekdayName(d)).join(', ') ?? '';
        return days;
    }
  }

  /// 星座の進捗を更新
  /// カレンダー画面では進捗更新のみ行い、アニメーションは表示しない
  Future<void> _updateConstellationProgress(
    BuildContext context,
    HabitController habitController,
  ) async {
    final habits = habitController.habits;

    if (habits.isNotEmpty) {
      await _constellationService.updateProgress(habits);
      // ホーム画面で表示するため、ここではアニメーションを出さない
    }
  }

  /// バッジの進捗を更新
  /// カレンダー画面では進捗更新のみ行い、アニメーションは表示しない
  /// 新しいバッジを獲得した場合は未表示フラグを保存
  Future<void> _updateBadgeProgress(
    BuildContext context,
    HabitController habitController,
  ) async {
    final habits = habitController.habits;

    if (habits.isNotEmpty) {
      // 更新前の進捗を取得
      final oldProgress = await _badgeService.getCurrentProgress();

      // 進捗を更新
      final newProgress = await _badgeService.updateProgress(habits);

      // 新しいバッジを獲得したかチェック
      final newBadges = _badgeService.getNewlyUnlockedBadges(oldProgress, newProgress);
      if (newBadges.isNotEmpty) {
        print('🎉 [Calendar] 新しいバッジを獲得: ${newBadges.map((b) => b.name).join(", ")}');
        // ホーム画面で表示するため、未表示フラグを保存
        await _badgeService.savePendingBadges(newBadges);
      }
    }
  }

  /// 習慣の完了状態をトグルする（過去日付の場合は広告を表示）
  Future<void> _handleHabitToggle(
    BuildContext context,
    HabitController habitController,
    Habit habit,
    DateTime selectedDay,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final isPastDate = targetDay.isBefore(today);
    final isCurrentlyCompleted = habit.isCompletedOnDate(selectedDay);

    // 過去日付で未完了→完了にする場合のみ広告を表示
    if (isPastDate && !isCurrentlyCompleted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('過去の習慣を完了にする'),
          content: const Text(
            '過去の日付を完了にします。よろしいですか？\n（広告の視聴後、完了状態になります）',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        // 広告を表示
        AdService.showInterstitialAd(
          onAdClosed: () async {
            // 広告が閉じられたら完了状態にする
            await habitController.toggleHabitCompletion(habit.id, selectedDay);
            // 星座とバッジの進捗を更新
            await _updateConstellationProgress(context, habitController);
            await _updateBadgeProgress(context, habitController);
          },
          onAdFailedToShow: () async {
            // 広告の表示に失敗した場合でも完了状態にする
            await habitController.toggleHabitCompletion(habit.id, selectedDay);
            // 星座とバッジの進捗を更新
            await _updateConstellationProgress(context, habitController);
            await _updateBadgeProgress(context, habitController);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('広告の読み込みに失敗しましたが、完了状態を変更しました')),
              );
            }
          },
        );
      }
    } else {
      // 今日の日付、または過去日付で完了→未完了にする場合は広告なしで切り替え
      await habitController.toggleHabitCompletion(habit.id, selectedDay);
      // 星座とバッジの進捗を更新
      await _updateConstellationProgress(context, habitController);
      await _updateBadgeProgress(context, habitController);
    }
  }

}