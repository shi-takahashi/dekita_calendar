import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/badge.dart';
import '../models/habit.dart';

/// バッジ管理サービス
class BadgeService {
  static const String _progressKey = 'badge_progress';
  static const String _debugModeKey = 'badge_debug_mode';
  static const String _debugStreakKey = 'badge_debug_streak';

  /// 利用可能なバッジ一覧
  static const List<AchievementBadge> availableBadges = [
    AchievementBadge(
      id: 'bronze',
      name: 'ブロンズ',
      type: BadgeType.bronze,
      requiredDays: 3,
      color: Color(0xFFCD7F32),
      icon: Icons.star,
    ),
    AchievementBadge(
      id: 'silver',
      name: 'シルバー',
      type: BadgeType.silver,
      requiredDays: 7,
      color: Color(0xFFC0C0C0),
      icon: Icons.star,
    ),
    AchievementBadge(
      id: 'gold',
      name: 'ゴールド',
      type: BadgeType.gold,
      requiredDays: 14,
      color: Color(0xFFFFD700),
      icon: Icons.star,
    ),
    AchievementBadge(
      id: 'platinum',
      name: 'プラチナ',
      type: BadgeType.platinum,
      requiredDays: 21,
      color: Color(0xFFE5E4E2),
      icon: Icons.stars,
    ),
    AchievementBadge(
      id: 'diamond',
      name: 'ダイヤモンド',
      type: BadgeType.diamond,
      requiredDays: 30,
      color: Color(0xFFB9F2FF),
      icon: Icons.stars,
    ),
    AchievementBadge(
      id: 'master',
      name: 'マスター',
      type: BadgeType.master,
      requiredDays: 50,
      color: Color(0xFF9370DB),
      icon: Icons.military_tech,
    ),
    AchievementBadge(
      id: 'legend',
      name: 'レジェンド',
      type: BadgeType.legend,
      requiredDays: 75,
      color: Color(0xFFFF6347),
      icon: Icons.military_tech,
    ),
    AchievementBadge(
      id: 'ultimate',
      name: 'アルティメット',
      type: BadgeType.ultimate,
      requiredDays: 100,
      color: Color(0xFFFF1493),
      icon: Icons.workspace_premium,
    ),
  ];

  /// 現在の進捗を取得
  Future<BadgeProgress> getCurrentProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_progressKey);

    if (json == null) {
      return const BadgeProgress(
        currentStreak: 0,
        unlockedBadgeIds: [],
      );
    }

    return BadgeProgress.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );
  }

  /// 進捗を保存
  Future<void> saveProgress(BadgeProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey, jsonEncode(progress.toJson()));
  }

  /// その日に予定されている全ての習慣が完了しているかチェック
  bool _isAllHabitsCompletedOnDate(List<Habit> habits, DateTime date) {
    if (habits.isEmpty) return false;

    final scheduledHabits = habits.where((habit) {
      return habit.isScheduledOn(date);
    }).toList();

    if (scheduledHabits.isEmpty) return false;

    return scheduledHabits.every((habit) => habit.isCompletedOnDate(date));
  }

  /// 全習慣達成の連続日数を計算
  int calculateAllHabitsStreak(List<Habit> habits) {
    if (habits.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int streak = 0;

    for (int i = 0; i < 365; i++) {
      final checkDate = today.subtract(Duration(days: i));

      if (_isAllHabitsCompletedOnDate(habits, checkDate)) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /// 進捗を更新（習慣完了時に呼ばれる）
  Future<BadgeProgress> updateProgress(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final debugMode = prefs.getBool(_debugModeKey) ?? false;

    // デバッグモードの場合は手動設定値を使用
    final streak = debugMode
        ? (prefs.getInt(_debugStreakKey) ?? 0)
        : calculateAllHabitsStreak(habits);

    print('🏅 バッジ進捗更新: 連続${streak}日');

    // 獲得済みバッジを判定
    final unlockedBadgeIds = <String>[];
    for (final badge in availableBadges) {
      if (streak >= badge.requiredDays) {
        unlockedBadgeIds.add(badge.id);
      }
    }

    final newProgress = BadgeProgress(
      currentStreak: streak,
      unlockedBadgeIds: unlockedBadgeIds,
      lastUpdated: DateTime.now(),
    );

    await saveProgress(newProgress);
    return newProgress;
  }

  /// 獲得済みバッジのリストを取得
  List<AchievementBadge> getUnlockedBadges(BadgeProgress progress) {
    return availableBadges
        .where((badge) => progress.unlockedBadgeIds.contains(badge.id))
        .toList();
  }

  /// 次に獲得できるバッジを取得
  AchievementBadge? getNextBadge(BadgeProgress progress) {
    for (final badge in availableBadges) {
      if (!progress.unlockedBadgeIds.contains(badge.id)) {
        return badge;
      }
    }
    return null; // 全て獲得済み
  }

  /// 新しくバッジを獲得したかチェック
  List<AchievementBadge> getNewlyUnlockedBadges(
    BadgeProgress oldProgress,
    BadgeProgress newProgress,
  ) {
    final newBadges = <AchievementBadge>[];
    for (final badgeId in newProgress.unlockedBadgeIds) {
      if (!oldProgress.unlockedBadgeIds.contains(badgeId)) {
        final badge = availableBadges.firstWhere((b) => b.id == badgeId);
        newBadges.add(badge);
      }
    }
    return newBadges;
  }

  // ========== デバッグ用メソッド ==========

  /// [デバッグ専用] 連続日数を強制的に設定
  Future<void> debugSetStreak(int streak) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debugModeKey, true);
    await prefs.setInt(_debugStreakKey, streak);

    final unlockedBadgeIds = <String>[];
    for (final badge in availableBadges) {
      if (streak >= badge.requiredDays) {
        unlockedBadgeIds.add(badge.id);
      }
    }

    final newProgress = BadgeProgress(
      currentStreak: streak,
      unlockedBadgeIds: unlockedBadgeIds,
      lastUpdated: DateTime.now(),
    );

    await saveProgress(newProgress);
    print('🐛 [DEBUG] 連続日数を${streak}日に設定');
  }

  /// [デバッグ専用] デバッグモードを解除
  Future<void> debugDisableDebugMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debugModeKey, false);
    await prefs.remove(_debugStreakKey);
    print('🐛 [DEBUG] 通常モードに戻しました');
  }

  /// [デバッグ専用] 全てリセット
  Future<void> debugResetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_progressKey);
    await prefs.remove(_debugModeKey);
    await prefs.remove(_debugStreakKey);
    print('🐛 [DEBUG] 全ての進捗をリセット');
  }

  /// [デバッグ専用] デバッグモードが有効かチェック
  Future<bool> isDebugModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_debugModeKey) ?? false;
  }
}
