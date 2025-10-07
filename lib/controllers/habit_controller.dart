import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/habit_repository.dart';
import '../services/alarm_notification_service.dart';
import '../services/improved_notification_service.dart';
import '../services/workmanager_notification_service.dart';
import '../services/native_alarm_notification_service.dart';

class HabitController extends ChangeNotifier {
  final HabitRepository _repository = HabitRepository();
  // ネイティブAlarmManager通知サービスを使用（最優先・最確実）
  final NativeAlarmNotificationService _notificationService = NativeAlarmNotificationService();
  // WorkManager版も保持（比較・切り替え用）
  final WorkManagerNotificationService _workManagerNotificationService = WorkManagerNotificationService();
  // 改善版も保持（比較・切り替え用）
  final ImprovedNotificationService _improvedNotificationService = ImprovedNotificationService();
  // 従来版も保持（必要に応じて切り替え可能）
  final AlarmNotificationService _alarmNotificationService = AlarmNotificationService();
  List<Habit> _habits = [];
  bool _isLoading = false;

  List<Habit> get habits => _habits;
  bool get isLoading => _isLoading;

  Future<void> loadHabits() async {
    _isLoading = true;
    
    try {
      _habits = await _repository.getAllHabits();
    } catch (e) {
      debugPrint('Error loading habits: $e');
      _habits = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addHabit(Habit habit) async {
    try {
      await _repository.saveHabit(habit);
      _habits.add(habit);
      
      if (habit.notificationTime != null) {
        await _notificationService.scheduleHabitNotifications(habit);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding habit: $e');
      rethrow;
    }
  }

  Future<void> updateHabit(Habit habit) async {
    try {
      await _repository.saveHabit(habit);
      final index = _habits.indexWhere((h) => h.id == habit.id);
      if (index != -1) {
        _habits[index] = habit;
        
        await _notificationService.cancelHabitNotifications(habit.id);
        if (habit.notificationTime != null) {
          await _notificationService.scheduleHabitNotifications(habit);
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating habit: $e');
      rethrow;
    }
  }

  Future<void> deleteHabit(String habitId) async {
    try {
      await _repository.deleteHabit(habitId);
      await _notificationService.cancelHabitNotifications(habitId);
      _habits.removeWhere((h) => h.id == habitId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting habit: $e');
      rethrow;
    }
  }

  Future<void> toggleHabitCompletion(String habitId, DateTime date) async {
    try {
      final habit = _habits.firstWhere((h) => h.id == habitId);
      final isCompleted = habit.isCompletedOnDate(date);
      
      await _repository.updateHabitCompletion(habitId, date, !isCompleted);
      
      final updatedHabit = habit.copyWithCompletedDate(date, !isCompleted);
      final index = _habits.indexWhere((h) => h.id == habitId);
      if (index != -1) {
        _habits[index] = updatedHabit;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling habit completion: $e');
      rethrow;
    }
  }

  List<Habit> getTodayHabits() {
    final today = DateTime.now();
    final weekday = today.weekday;
    
    return _habits.where((habit) {
      switch (habit.frequency) {
        case HabitFrequency.daily:
          return true;
        case HabitFrequency.specificDays:
          return habit.specificDays?.contains(weekday) ?? false;
      }
    }).toList();
  }

  Habit? getHabitById(String id) {
    try {
      return _habits.firstWhere((h) => h.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> rescheduleAllNotifications() async {
    for (final habit in _habits) {
      await _notificationService.cancelHabitNotifications(habit.id);
      if (habit.notificationTime != null) {
        await _notificationService.scheduleHabitNotifications(habit);
      }
    }
  }
}