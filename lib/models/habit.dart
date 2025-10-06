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

  Habit copyWith({
    String? id,
    String? title,
    HabitFrequency? frequency,
    int? targetWeeklyCount,
    List<int>? specificDays,
    DateTime? notificationTime,
    List<DateTime>? completedDates,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      frequency: frequency ?? this.frequency,
      targetWeeklyCount: targetWeeklyCount ?? this.targetWeeklyCount,
      specificDays: specificDays ?? this.specificDays,
      notificationTime: notificationTime ?? this.notificationTime,
      completedDates: completedDates ?? this.completedDates,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Habit copyWithCompletedDate(DateTime date, bool completed) {
    final newCompletedDates = List<DateTime>.from(completedDates);
    
    if (completed) {
      if (!isCompletedOnDate(date)) {
        newCompletedDates.add(date);
      }
    } else {
      newCompletedDates.removeWhere((d) =>
          d.year == date.year && d.month == date.month && d.day == date.day);
    }
    
    return copyWith(
      completedDates: newCompletedDates,
      updatedAt: DateTime.now(),
    );
  }

  DateTime _getStartOfWeek(DateTime date) {
    int weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  DateTime _getEndOfWeek(DateTime date) {
    int weekday = date.weekday;
    return date.add(Duration(days: 7 - weekday));
  }

  int getWeeklyCompletionCount([DateTime? forDate]) {
    final targetDate = forDate ?? DateTime.now();
    final startOfWeek = _getStartOfWeek(targetDate);
    final endOfWeek = _getEndOfWeek(targetDate);
    
    return completedDates.where((date) {
      return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
             date.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).length;
  }

  bool isWeeklyTargetMet([DateTime? forDate]) {
    if (frequency != HabitFrequency.weekly || targetWeeklyCount == null) {
      return false;
    }
    return getWeeklyCompletionCount(forDate) >= targetWeeklyCount!;
  }

  int getRemainingWeeklyCount([DateTime? forDate]) {
    if (frequency != HabitFrequency.weekly || targetWeeklyCount == null) {
      return 0;
    }
    final completed = getWeeklyCompletionCount(forDate);
    return (targetWeeklyCount! - completed).clamp(0, targetWeeklyCount!);
  }
}