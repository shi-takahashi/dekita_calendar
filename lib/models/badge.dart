import 'package:flutter/material.dart';

/// バッジの種類
enum BadgeType {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
}

/// バッジの定義
class AchievementBadge {
  final String id;
  final String name;
  final BadgeType type;
  final int requiredWeeks;
  final Color color;
  final IconData icon;

  const AchievementBadge({
    required this.id,
    required this.name,
    required this.type,
    required this.requiredWeeks,
    required this.color,
    required this.icon,
  });
}

/// バッジ進捗状態
class BadgeProgress {
  final int currentStreak; // 現在の連続週数
  final List<String> unlockedBadgeIds; // 獲得済みバッジID
  final DateTime? lastUpdated;

  const BadgeProgress({
    required this.currentStreak,
    required this.unlockedBadgeIds,
    this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'unlockedBadgeIds': unlockedBadgeIds,
        'lastUpdated': lastUpdated?.toIso8601String(),
      };

  factory BadgeProgress.fromJson(Map<String, dynamic> json) => BadgeProgress(
        currentStreak: json['currentStreak'] as int,
        unlockedBadgeIds: (json['unlockedBadgeIds'] as List).cast<String>(),
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.parse(json['lastUpdated'] as String)
            : null,
      );

  BadgeProgress copyWith({
    int? currentStreak,
    List<String>? unlockedBadgeIds,
    DateTime? lastUpdated,
  }) {
    return BadgeProgress(
      currentStreak: currentStreak ?? this.currentStreak,
      unlockedBadgeIds: unlockedBadgeIds ?? this.unlockedBadgeIds,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
