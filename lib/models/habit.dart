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
  final DateTime? startDate;  // 開始日（nullの場合は制限なし）
  final DateTime? endDate;    // 終了日（nullの場合は無期限）

  Habit({
    required this.id,
    required this.title,
    required this.frequency,
    this.specificDays,
    this.notificationTime,
    required this.completedDates,
    required this.createdAt,
    required this.updatedAt,
    this.startDate,
    this.endDate,
  });

  bool isCompletedOnDate(DateTime date) {
    return completedDates.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  /// 指定された日付にこの習慣が予定されているかチェック
  bool isScheduledOn(DateTime date) {
    // 開始日より前の場合は予定されていない
    if (startDate != null) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      final startDateOnly = DateTime(startDate!.year, startDate!.month, startDate!.day);
      if (dateOnly.isBefore(startDateOnly)) {
        return false;
      }
    }

    // 終了日より後の場合は予定されていない
    if (endDate != null) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      final endDateOnly = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (dateOnly.isAfter(endDateOnly)) {
        return false;
      }
    }

    // 頻度によるチェック
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

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 今日が予定日かつ完了しているか確認
    final todayIsScheduled = isScheduledOn(today);
    final todayCompleted = isCompletedOnDate(today);

    // 開始日を決定
    DateTime checkDate;
    if (todayIsScheduled && todayCompleted) {
      // 今日が予定日で完了している場合は今日から
      checkDate = today;
    } else {
      // それ以外の場合は昨日から遡る
      checkDate = today.subtract(const Duration(days: 1));
    }

    int streak = 0;

    // 最大365日遡る（過去1年分）
    for (int i = 0; i < 365; i++) {
      // この日が予定日でない場合
      if (!isScheduledOn(checkDate)) {
        // 開始日より前の日付に到達したら終了
        if (startDate != null) {
          final checkDateOnly = DateTime(checkDate.year, checkDate.month, checkDate.day);
          final startDateOnly = DateTime(startDate!.year, startDate!.month, startDate!.day);
          if (checkDateOnly.isBefore(startDateOnly)) {
            break; // 開始日より前なので終了
          }
        }
        // 終了日より後の日付の場合もスキップして次へ
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      }

      // この日が完了していれば連続記録を増やす
      if (isCompletedOnDate(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        // 予定日だが完了していない場合は連続記録終了
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
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
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
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : null,
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
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
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
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
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