enum HabitFrequency {
  daily,
  weekly,
  specificDays,
}

class Habit {
  final String id;
  final String title;
  final HabitFrequency frequency;
  final int? targetWeeklyCount;
  final List<int>? specificDays;
  final DateTime? notificationTime;
  final List<DateTime> completedDates;
  final DateTime createdAt;
  final DateTime updatedAt;

  Habit({
    required this.id,
    required this.title,
    required this.frequency,
    this.targetWeeklyCount,
    this.specificDays,
    this.notificationTime,
    required this.completedDates,
    required this.createdAt,
    required this.updatedAt,
  });

  bool isCompletedOnDate(DateTime date) {
    return completedDates.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  void toggleCompletion(DateTime date) {
    if (isCompletedOnDate(date)) {
      completedDates.removeWhere((d) =>
          d.year == date.year && d.month == date.month && d.day == date.day);
    } else {
      completedDates.add(date);
    }
  }

  int get currentStreak {
    if (completedDates.isEmpty) return 0;

    completedDates.sort((a, b) => b.compareTo(a));
    
    int streak = 0;
    DateTime currentDate = DateTime.now();
    
    for (int i = 0; i < completedDates.length; i++) {
      final date = completedDates[i];
      final dayDifference = currentDate.difference(date).inDays;
      
      if (dayDifference == i) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'frequency': frequency.index,
      'targetWeeklyCount': targetWeeklyCount,
      'specificDays': specificDays,
      'notificationTime': notificationTime?.toIso8601String(),
      'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      title: json['title'],
      frequency: HabitFrequency.values[json['frequency']],
      targetWeeklyCount: json['targetWeeklyCount'],
      specificDays: json['specificDays'] != null
          ? List<int>.from(json['specificDays'])
          : null,
      notificationTime: json['notificationTime'] != null
          ? DateTime.parse(json['notificationTime'])
          : null,
      completedDates: (json['completedDates'] as List<dynamic>)
          .map((d) => DateTime.parse(d))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}