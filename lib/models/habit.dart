enum HabitFrequency {
  daily,
  specificDays,
}

class Habit {
  final String id;
  final String title;
  final HabitFrequency frequency;
  final List<int>? specificDays;
  final DateTime? notificationTime;
  final List<DateTime> completedDates;
  final DateTime createdAt;
  final DateTime updatedAt;

  Habit({
    required this.id,
    required this.title,
    required this.frequency,
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

  /// 指定された日付にこの習慣が予定されているかチェック
  bool isScheduledOn(DateTime date) {
    switch (frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.specificDays:
        if (specificDays == null || specificDays!.isEmpty) {
          return false;
        }
        return specificDays!.contains(date.weekday);
    }
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

    final sortedDates = List<DateTime>.from(completedDates)
      ..sort((a, b) => b.compareTo(a));
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // 今日が完了しているか確認
    final todayCompleted = sortedDates.any((date) => 
      date.year == today.year && 
      date.month == today.month && 
      date.day == today.day
    );
    
    // 開始日を決定（今日完了してるなら今日から、してないなら昨日から）
    final startDate = todayCompleted ? today : today.subtract(const Duration(days: 1));
    
    int streak = 0;
    DateTime checkDate = startDate;
    
    for (final completedDate in sortedDates) {
      final completed = DateTime(completedDate.year, completedDate.month, completedDate.day);
      
      if (completed.isAtSameMomentAs(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (completed.isBefore(checkDate)) {
        // 連続が途切れた
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

}