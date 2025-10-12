import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/habit_repository.dart';
import '../services/native_alarm_notification_service.dart';

class HabitController extends ChangeNotifier {
  final HabitRepository _repository = HabitRepository();
  final NativeAlarmNotificationService _notificationService = NativeAlarmNotificationService();
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
    return _habits.where((habit) => habit.isScheduledOn(today)).toList();
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