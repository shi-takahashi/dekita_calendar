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
        maxStreak: 0,
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

  /// 指定日を含む週の開始日（日曜日）を取得
  DateTime _getWeekStart(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final weekday = normalized.weekday; // 月曜=1, 日曜=7
    final daysToSubtract = weekday == 7 ? 0 : weekday; // 日曜なら0、月曜なら1、...、土曜なら6
    return normalized.subtract(Duration(days: daysToSubtract));
  }

  /// 指定した週が全てクリアされているか
  bool _isWeekCompleted(List<Habit> habits, DateTime weekStart) {
    if (habits.isEmpty) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool hasAnyScheduledDay = false; // この週に予定日があるかどうか

    // その週の日曜〜土曜までの7日間全てチェック
    for (int i = 0; i < 7; i++) {
      final checkDate = weekStart.add(Duration(days: i));

      // その日に予定されている習慣を取得
      final scheduledHabits = habits.where((habit) {
        return habit.isScheduledOn(checkDate);
      }).toList();

      // 予定がない日はスキップ
      if (scheduledHabits.isEmpty) {
        continue;
      }

      hasAnyScheduledDay = true; // 予定日があることを記録

      // 未来の予定日がある場合は、その週はまだ完了していない
      if (checkDate.isAfter(today)) {
        return false;
      }

      // 過去または今日の予定日：完了チェック
      final allCompleted = scheduledHabits.every((habit) =>
        habit.isCompletedOnDate(checkDate)
      );
      if (!allCompleted) {
        return false; // 未完了がある
      }
    }

    // 予定日が1日もない週は未達成として扱う
    return hasAnyScheduledDay;
  }

  /// 今週の予定日が全て過去になったかチェック（未完了確定判定用）
  bool _isWeekDefined(List<Habit> habits, DateTime weekStart) {
    if (habits.isEmpty) return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // その週の日曜〜土曜をチェック
    for (int i = 0; i < 7; i++) {
      final checkDate = weekStart.add(Duration(days: i));

      // その日に予定されている習慣があるかチェック
      final hasScheduledHabits = habits.any((habit) => habit.isScheduledOn(checkDate));

      // 予定日があり、かつ未来の場合 → まだ完了可能（未確定）
      if (hasScheduledHabits && !checkDate.isBefore(today)) {
        return false;
      }
    }

    // 全ての予定日が過去になった（確定）
    return true;
  }

  /// 週単位の連続達成数を計算（現在と最高の両方を返す）
  Map<String, int> calculateWeeklyStreaks(List<Habit> habits) {
    if (habits.isEmpty) {
      return {'current': 0, 'max': 0};
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeekStart = _getWeekStart(today);

    int maxStreak = 0;
    int tempStreak = 0;

    // 今週が完了しているかチェック
    final thisWeekCompleted = _isWeekCompleted(habits, thisWeekStart);
    // 今週の予定日が全て過去になったか（確定したか）
    final thisWeekDefined = _isWeekDefined(habits, thisWeekStart);

    int currentStreak = 0;

    // 今週の状態に応じて開始位置を決定
    if (thisWeekCompleted) {
      // 今週完了 → 今週から連続カウント
      for (int i = 0; i < 999; i++) {
        final checkWeekStart = thisWeekStart.subtract(Duration(days: i * 7));
        if (_isWeekCompleted(habits, checkWeekStart)) {
          currentStreak++;
        } else {
          break;
        }
      }
    } else if (!thisWeekDefined) {
      // 今週未完了だが、まだ予定日が来ていない → 先週から連続カウント
      for (int i = 1; i < 999; i++) {
        final checkWeekStart = thisWeekStart.subtract(Duration(days: i * 7));
        if (_isWeekCompleted(habits, checkWeekStart)) {
          currentStreak++;
        } else {
          break;
        }
      }
    } else {
      // 今週の予定日が全て過ぎて未完了 → 連続途切れ（0週）
      currentStreak = 0;
    }

    // 全履歴を見て最大連続週数を計算
    for (int i = 0; i < 999; i++) {
      final checkWeekStart = thisWeekStart.subtract(Duration(days: i * 7));
      final weekCompleted = _isWeekCompleted(habits, checkWeekStart);

      if (weekCompleted) {
        tempStreak++;
        if (tempStreak > maxStreak) {
          maxStreak = tempStreak;
        }
      } else {
        tempStreak = 0;
      }
    }

    print('📊 今週: ${thisWeekCompleted ? "完了" : "未完了"}${!thisWeekCompleted && !thisWeekDefined ? "(まだ予定日あり)" : thisWeekDefined ? "(確定)" : ""} → 現在${currentStreak}週, 過去最高${maxStreak}週');
    return {'current': currentStreak, 'max': maxStreak};
  }

  /// 現在の連続週数のみを計算（後方互換性のため残す）
  int calculateWeeklyStreak(List<Habit> habits) {
    return calculateWeeklyStreaks(habits)['current']!;
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

    int currentStreak;
    int maxStreak;

    if (debugMode) {
      // デバッグモードの場合は手動設定値を使用
      currentStreak = prefs.getInt(_debugStreakKey) ?? 0;
      maxStreak = currentStreak > currentProgress.maxStreak ? currentStreak : currentProgress.maxStreak;
    } else {
      // 履歴から現在と最高の両方を計算
      final streaks = calculateWeeklyStreaks(habits);
      currentStreak = streaks['current']!;
      maxStreak = streaks['max']!;
    }

    print('🏅 バッジ進捗更新: 現在${currentStreak}週 (過去最高: ${maxStreak}週)');

    // 既存の獲得済みバッジを保持しつつ、新しいバッジを追加
    // バッジ獲得判定は過去最高記録で行う（一度達成すれば獲得）
    final unlockedBadgeIds = Set<String>.from(currentProgress.unlockedBadgeIds);
    for (final badge in availableBadges) {
      if (maxStreak >= badge.requiredWeeks) {
        unlockedBadgeIds.add(badge.id);
      }
    }

    final newProgress = BadgeProgress(
      currentStreak: currentStreak,
      maxStreak: maxStreak,
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

    // 現在の最高記録を取得
    final currentProgress = await getCurrentProgress();
    final maxStreak = streak > currentProgress.maxStreak ? streak : currentProgress.maxStreak;

    // バッジ獲得判定は過去最高記録で行う
    final unlockedBadgeIds = <String>[];
    for (final badge in availableBadges) {
      if (maxStreak >= badge.requiredWeeks) {
        unlockedBadgeIds.add(badge.id);
      }
    }

    final newProgress = BadgeProgress(
      currentStreak: streak,
      maxStreak: maxStreak,
      unlockedBadgeIds: unlockedBadgeIds,
      lastUpdated: DateTime.now(),
    );

    await saveProgress(newProgress);
    print('🐛 [DEBUG] 連続週数を${streak}週に設定 (最高: ${maxStreak}週)');
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
