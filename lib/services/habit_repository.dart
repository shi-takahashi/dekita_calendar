import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';

class HabitRepository {
  static const String _habitsKey = 'habits';
  
  Future<List<Habit>> getAllHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitsJson = prefs.getString(_habitsKey);
    
    if (habitsJson == null) {
      return [];
    }
    
    final habitsList = json.decode(habitsJson) as List;
    return habitsList.map((habitMap) => Habit.fromJson(habitMap)).toList();
  }
  
  Future<Habit?> getHabitById(String id) async {
    final habits = await getAllHabits();
    try {
      return habits.firstWhere((habit) => habit.id == id);
    } catch (e) {
      return null;
    }
  }
  
  Future<void> saveHabit(Habit habit) async {
    final prefs = await SharedPreferences.getInstance();
    final habits = await getAllHabits();
    
    final existingIndex = habits.indexWhere((h) => h.id == habit.id);
    if (existingIndex != -1) {
      habits[existingIndex] = habit;
    } else {
      habits.add(habit);
    }
    
    final habitsJson = json.encode(habits.map((h) => h.toJson()).toList());
    await prefs.setString(_habitsKey, habitsJson);
  }
  
  Future<void> deleteHabit(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final habits = await getAllHabits();
    
    habits.removeWhere((habit) => habit.id == id);
    
    final habitsJson = json.encode(habits.map((h) => h.toJson()).toList());
    await prefs.setString(_habitsKey, habitsJson);
  }
  
  Future<void> updateHabitCompletion(String habitId, DateTime date, bool completed) async {
    final habit = await getHabitById(habitId);
    if (habit == null) return;
    
    final updatedHabit = habit.copyWithCompletedDate(date, completed);
    await saveHabit(updatedHabit);
  }
}