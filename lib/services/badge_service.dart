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
  static const String _pendingBadgesKey = 'badge_pending_badges';

  /// 利用可能なバッジ一覧
  static const List<AchievementBadge> availableBadges = [
    AchievementBadge(
      id: 'bronze',
      name: 'ブロンズ',
      type: BadgeType.bronze,
      requiredWeeks: 1,
      color: Color(0xFFCD7F32),
      icon: Icons.star_outline, // 星の輪郭
    ),
    AchievementBadge(
      id: 'silver',
      name: 'シルバー',
      type: BadgeType.silver,
      requiredWeeks: 2,
      color: Color(0xFFC0C0C0),
      icon: Icons.star, // 塗りつぶし星
    ),
    AchievementBadge(
      id: 'gold',
      name: 'ゴールド',
      type: BadgeType.gold,
      requiredWeeks: 4,
      color: Color(0xFFFFD700),
      icon: Icons.stars, // 複数の星
    ),
    AchievementBadge(
      id: 'platinum',
      name: 'プラチナ',
      type: BadgeType.platinum,
      requiredWeeks: 12,
      color: Color(0xFFE5E4E2),
      icon: Icons.military_tech, // メダル
    ),
    AchievementBadge(
      id: 'diamond',
      name: 'ダイヤモンド',
      type: BadgeType.diamond,
      requiredWeeks: 52,
      color: Color(0xFFB9F2FF),
      icon: Icons.workspace_premium, // プレミアムバッジ
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

  /// 指定日を含む週の開始日（月曜日）を取得
  DateTime _getWeekStart(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final weekday = normalized.weekday; // 月曜=1, 日曜=7
    final daysToSubtract = weekday - 1; // 月曜なら0、火曜なら1、...、日曜なら6
    return normalized.subtract(Duration(days: daysToSubtract));
  }

  /// 指定した週が全てクリアされているか
  bool _isWeekCompleted(List<Habit> habits, DateTime weekStart) {
    if (habits.isEmpty) return false;

    // その週の月曜〜日曜までチェック
    for (int i = 0; i < 7; i++) {
      final checkDate = weekStart.add(Duration(days: i));

      // その日に予定されている習慣を取得
      final scheduledHabits = habits.where((habit) {
        return habit.isScheduledOn(checkDate);
      }).toList();

      // 予定された習慣が1つでもあり、全て完了していない場合は週未達成
      if (scheduledHabits.isNotEmpty) {
        final allCompleted = scheduledHabits.every((habit) =>
          habit.isCompletedOnDate(checkDate)
        );
        if (!allCompleted) {
          return false;
        }
      }
    }

    return true;
  }

  /// 週単位の連続達成数を計算
  int calculateWeeklyStreak(List<Habit> habits) {
    if (habits.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeekStart = _getWeekStart(today);

    int streak = 0;

    // 今週が完了している場合は今週から、未完了の場合は先週から開始
    final thisWeekCompleted = _isWeekCompleted(habits, thisWeekStart);
    final startOffset = thisWeekCompleted ? 0 : 1;

    // 最大52週（1年分）まで遡る
    for (int i = startOffset; i < 52; i++) {
      final checkWeekStart = thisWeekStart.subtract(Duration(days: i * 7));

      if (_isWeekCompleted(habits, checkWeekStart)) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /// 全習慣達成の連続日数を計算（旧バージョン - 参考用）
  int calculateAllHabitsStreak(List<Habit> habits) {
    if (habits.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int streak = 0;

    // 今日が完了している場合は今日から、未完了の場合は昨日から開始
    // （今日はまだ途中なので、未完了でも昨日までの連続は保持）
    final todayCompleted = _isAllHabitsCompletedOnDate(habits, today);
    final startOffset = todayCompleted ? 0 : 1;

    for (int i = startOffset; i < 365; i++) {
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

    // 現在の保存済み進捗を取得
    final currentProgress = await getCurrentProgress();

    // デバッグモードの場合は手動設定値を使用
    final streak = debugMode
        ? (prefs.getInt(_debugStreakKey) ?? 0)
        : calculateWeeklyStreak(habits);

    print('🏅 バッジ進捗更新: 連続${streak}週');

    // 既存の獲得済みバッジを保持しつつ、新しいバッジを追加
    // 一度獲得したバッジは、連続週数が下がっても保持する
    final unlockedBadgeIds = Set<String>.from(currentProgress.unlockedBadgeIds);
    for (final badge in availableBadges) {
      if (streak >= badge.requiredWeeks) {
        unlockedBadgeIds.add(badge.id);
      }
    }

    final newProgress = BadgeProgress(
      currentStreak: streak,
      unlockedBadgeIds: unlockedBadgeIds.toList(),
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

  /// [デバッグ専用] 連続週数を強制的に設定
  Future<void> debugSetStreak(int streak) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debugModeKey, true);
    await prefs.setInt(_debugStreakKey, streak);

    final unlockedBadgeIds = <String>[];
    for (final badge in availableBadges) {
      if (streak >= badge.requiredWeeks) {
        unlockedBadgeIds.add(badge.id);
      }
    }

    final newProgress = BadgeProgress(
      currentStreak: streak,
      unlockedBadgeIds: unlockedBadgeIds,
      lastUpdated: DateTime.now(),
    );

    await saveProgress(newProgress);
    print('🐛 [DEBUG] 連続週数を${streak}週に設定');
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

  // ========== 未表示バッジ管理 ==========

  /// 未表示のバッジを保存
  Future<void> savePendingBadges(List<AchievementBadge> badges) async {
    if (badges.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final badgeIds = badges.map((b) => b.id).toList();
    await prefs.setStringList(_pendingBadgesKey, badgeIds);
    print('💾 未表示バッジを保存: ${badgeIds.join(", ")}');
  }

  /// 未表示のバッジを取得
  Future<List<AchievementBadge>> getPendingBadges() async {
    final prefs = await SharedPreferences.getInstance();
    final badgeIds = prefs.getStringList(_pendingBadgesKey) ?? [];

    if (badgeIds.isEmpty) return [];

    final badges = badgeIds
        .map((id) => availableBadges.firstWhere(
              (b) => b.id == id,
              orElse: () => availableBadges.first,
            ))
        .toList();

    print('📖 未表示バッジを取得: ${badgeIds.join(", ")}');
    return badges;
  }

  /// 未表示のバッジをクリア
  Future<void> clearPendingBadges() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingBadgesKey);
    print('🗑️ 未表示バッジをクリア');
  }
}
