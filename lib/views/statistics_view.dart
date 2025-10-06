import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/habit_controller.dart';
import '../models/habit.dart';

class StatisticsView extends StatefulWidget {
  const StatisticsView({super.key});

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> with AutomaticKeepAliveClientMixin {
  int _selectedPeriod = 0; // 0: 週間, 1: 月間
  Habit? _selectedHabit;

  @override
  bool get wantKeepAlive => false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('統計'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<HabitController>(
        builder: (context, habitController, child) {
          if (habitController.habits.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '習慣を追加すると統計が表示されます',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          // 選択された習慣が削除されていたら、最初の習慣を選択
          if (_selectedHabit != null && 
              !habitController.habits.any((h) => h.id == _selectedHabit!.id)) {
            _selectedHabit = null;
          }
          
          // 習慣リストから最新のデータを取得
          if (_selectedHabit != null) {
            _selectedHabit = habitController.habits.firstWhere(
              (h) => h.id == _selectedHabit!.id,
              orElse: () => habitController.habits.first,
            );
          } else {
            _selectedHabit = habitController.habits.first;
          }

          return Column(
            children: [
              _buildPeriodSelector(),
              _buildHabitSelector(habitController.habits),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStreakCard(),
                      const SizedBox(height: 16),
                      _buildCompletionRateCard(),
                      const SizedBox(height: 16),
                      _buildAchievementChart(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment(
            value: 0,
            label: Text('週間'),
            icon: Icon(Icons.calendar_view_week),
          ),
          ButtonSegment(
            value: 1,
            label: Text('月間'),
            icon: Icon(Icons.calendar_month),
          ),
        ],
        selected: {_selectedPeriod},
        onSelectionChanged: (Set<int> newSelection) {
          setState(() {
            _selectedPeriod = newSelection.first;
          });
        },
      ),
    );
  }

  Widget _buildHabitSelector(List<Habit> habits) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '習慣を選択',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  underline: const SizedBox(),
                  value: _selectedHabit?.id,
                  items: habits.map((habit) {
                    return DropdownMenuItem(
                      value: habit.id,
                      child: Row(
                        children: [
                          Expanded(child: Text(habit.title)),
                          Text(
                            _getFrequencyShortText(habit),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            onChanged: (String? newId) {
              setState(() {
                _selectedHabit = habits.firstWhere((h) => h.id == newId);
              });
            },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    if (_selectedHabit == null) return const SizedBox();

    final currentStreak = _selectedHabit!.currentStreak;
    final maxStreak = _getMaxStreak(_selectedHabit!);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '連続記録',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStreakItem(
                    icon: Icons.local_fire_department,
                    label: '現在の連続日数',
                    value: '$currentStreak日',
                    color: currentStreak > 0 ? Colors.orange : Colors.grey,
                  ),
                ),
                Expanded(
                  child: _buildStreakItem(
                    icon: Icons.emoji_events,
                    label: '最大連続日数',
                    value: '$maxStreak日',
                    color: maxStreak > 0 ? Colors.amber : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 40, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionRateCard() {
    if (_selectedHabit == null) return const SizedBox();

    final result = _getCompletionRateWithDetails(_selectedHabit!, _selectedPeriod);
    final completionRate = result['rate'] as double;
    final completedDays = result['completed'] as int;
    final targetDays = result['target'] as int;
    final color = _getColorForRate(completionRate);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedPeriod == 0 ? '今週の達成率' : '今月の達成率',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: completionRate,
                    minHeight: 20,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${(completionRate * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getAchievementText(completedDays, targetDays, _selectedPeriod),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementChart() {
    if (_selectedHabit == null) return const SizedBox();

    final data = _getChartData(_selectedHabit!, _selectedPeriod);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedPeriod == 0 ? '週別の達成率' : '月別の達成率',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _selectedPeriod == 0 
                  ? '過去4週間の達成率推移' 
                  : '過去4ヶ月の達成率推移',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1.0,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${(rod.toY * 100).toStringAsFixed(0)}%',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              data[value.toInt()].label,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        interval: 0.2,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 0.2,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: data.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value,
                          color: _getColorForRate(entry.value.value),
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getMaxStreak(Habit habit) {
    if (habit.completedDates.isEmpty) return 0;
    
    final sortedDates = List<DateTime>.from(habit.completedDates)
      ..sort((a, b) => a.compareTo(b));
    
    int maxStreak = 1;
    int currentStreak = 1;
    
    for (int i = 1; i < sortedDates.length; i++) {
      final diff = sortedDates[i].difference(sortedDates[i - 1]).inDays;
      
      if (diff == 1) {
        currentStreak++;
        maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;
      } else {
        currentStreak = 1;
      }
    }
    
    return maxStreak;
  }

  Map<String, dynamic> _getCompletionRateWithDetails(Habit habit, int period) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;
    
    if (period == 0) {
      // 週間：今週の月曜から日曜まで（固定7日間）
      final weekday = now.weekday;
      startDate = now.subtract(Duration(days: weekday - 1));
      endDate = startDate.add(const Duration(days: 6));
    } else {
      // 月間：今月の1日から末日まで
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0);
    }
    
    // 毎日・特定曜日の習慣の処理
    int targetDays = 0;
    int completedDays = 0;
    
    // 全期間の予定日数をカウント（未来も含む）
    DateTime date = startDate;
    while (date.isBefore(endDate.add(const Duration(days: 1)))) {
      if (_shouldCountDay(habit, date)) {
        targetDays++;
        // 過去と今日の完了のみカウント
        if (!date.isAfter(now) && habit.isCompletedOnDate(date)) {
          completedDays++;
        }
      }
      date = date.add(const Duration(days: 1));
    }
    
    return {
      'rate': targetDays > 0 ? completedDays / targetDays.toDouble() : 0.0,
      'completed': completedDays,
      'target': targetDays,
    };
  }


  bool _shouldCountDay(Habit habit, DateTime date) {
    switch (habit.frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.specificDays:
        return habit.specificDays?.contains(date.weekday) ?? false;
    }
  }

  List<ChartData> _getChartData(Habit habit, int period) {
    final now = DateTime.now();
    final List<ChartData> data = [];
    
    if (period == 0) {
      // 週間：過去4週間の週別達成率（月曜始まりの週で集計）
      final currentWeekday = now.weekday;
      final currentWeekStart = now.subtract(Duration(days: currentWeekday - 1));
      
      for (int week = 4; week >= 1; week--) {
        final weekStart = currentWeekStart.subtract(Duration(days: week * 7));
        final weekEnd = weekStart.add(const Duration(days: 6));
        
        int targetDays = 0;
        int completedDays = 0;
        
        // 毎日・特定曜日の習慣の処理
        DateTime date = weekStart;
        while (date.isBefore(weekEnd.add(const Duration(days: 1)))) {
          if (_shouldCountDay(habit, date)) {
            targetDays++;
            if (habit.isCompletedOnDate(date)) {
              completedDays++;
            }
          }
          date = date.add(const Duration(days: 1));
        }
        
        final month = weekStart.month;
        final day = weekStart.day;
        final weekLabel = '$month/$day~';
        
        data.add(ChartData(
          label: weekLabel,
          value: targetDays > 0 ? completedDays / targetDays.toDouble() : 0.0,
        ));
      }
    } else {
      // 月間：過去4ヶ月の月別達成率
      for (int monthOffset = 4; monthOffset >= 1; monthOffset--) {
        final targetMonth = DateTime(now.year, now.month - monthOffset, 1);
        final monthStart = DateTime(targetMonth.year, targetMonth.month, 1);
        final monthEnd = DateTime(targetMonth.year, targetMonth.month + 1, 0);
        
        int targetDays = 0;
        int completedDays = 0;
        
        // 毎日・特定曜日の習慣の処理
        DateTime date = monthStart;
        while (date.isBefore(monthEnd.add(const Duration(days: 1)))) {
          if (_shouldCountDay(habit, date)) {
            targetDays++;
            if (habit.isCompletedOnDate(date)) {
              completedDays++;
            }
          }
          date = date.add(const Duration(days: 1));
        }
        
        final monthLabel = '${targetMonth.month}月';
        
        data.add(ChartData(
          label: monthLabel,
          value: targetDays > 0 ? completedDays / targetDays.toDouble() : 0.0,
        ));
      }
    }
    
    return data;
  }

  Color _getColorForRate(double rate) {
    if (rate >= 0.8) return Colors.green;
    if (rate >= 0.6) return Colors.orange;
    if (rate >= 0.4) return Colors.yellow[700]!;
    return Colors.red;
  }

  String _getFrequencyShortText(Habit habit) {
    switch (habit.frequency) {
      case HabitFrequency.daily:
        return '毎日';
      case HabitFrequency.specificDays:
        final days = ['月', '火', '水', '木', '金', '土', '日'];
        final selectedDays = habit.specificDays
            ?.map((day) => days[day - 1])
            .join('') ?? '';
        return selectedDays;
    }
  }

  String _getAchievementText(int completed, int target, int period) {
    return '達成: $completed日 / ${period == 0 ? '週間' : '月間'}目標: $target日';
  }

}

class ChartData {
  final String label;
  final double value;

  ChartData({required this.label, required this.value});
}