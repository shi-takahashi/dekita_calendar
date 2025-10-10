import 'package:flutter/material.dart';
import '../models/badge.dart';
import '../services/badge_service.dart';

/// バッジコレクションを表示するウィジェット
class BadgeCollectionWidget extends StatelessWidget {
  final BadgeProgress progress;

  const BadgeCollectionWidget({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final badgeService = BadgeService();
    final nextBadge = badgeService.getNextBadge(progress);
    final totalBadges = BadgeService.availableBadges.length;
    final unlockedCount = progress.unlockedBadgeIds.length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo[100]!,
            Colors.purple[100]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 現在の連続週数
                      Text(
                        '現在の連続達成',
                        style: TextStyle(
                          color: Colors.indigo[700],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${progress.currentStreak}',
                            style: TextStyle(
                              color: Colors.indigo[900],
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '週',
                            style: TextStyle(
                              color: Colors.indigo[700],
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 最高記録（履歴から計算）
                      if (progress.maxStreak > 0)
                        Row(
                          children: [
                            Icon(
                              Icons.emoji_events,
                              size: 16,
                              color: Colors.amber[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '最高記録: ${progress.maxStreak}週',
                              style: TextStyle(
                                color: Colors.indigo[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // バッジカウント
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.indigo[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$unlockedCount/$totalBadges',
                    style: TextStyle(
                      color: Colors.indigo[900],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 次のバッジ情報
            if (nextBadge != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flag,
                      color: nextBadge.color,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '次の目標: ${nextBadge.name}',
                            style: TextStyle(
                              color: Colors.indigo[900],
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'あと${nextBadge.requiredWeeks - progress.currentStreak}週',
                            style: TextStyle(
                              color: Colors.indigo[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // バッジリスト
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: BadgeService.availableBadges.length,
                itemBuilder: (context, index) {
                  final badge = BadgeService.availableBadges[index];
                  final isUnlocked = progress.unlockedBadgeIds.contains(badge.id);

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _BadgeItem(
                      badge: badge,
                      isUnlocked: isUnlocked,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 個別のバッジアイテム
class _BadgeItem extends StatelessWidget {
  final AchievementBadge badge;
  final bool isUnlocked;

  const _BadgeItem({
    required this.badge,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // バッジ円形
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isUnlocked ? badge.color : Colors.grey[300],
            border: Border.all(
              color: isUnlocked ? badge.color.withOpacity(0.3) : Colors.grey[400]!,
              width: 2,
            ),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: badge.color.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            badge.icon,
            color: isUnlocked ? Colors.white : Colors.grey[500],
            size: 28,
          ),
        ),
        const SizedBox(height: 4),
        // バッジ名
        Text(
          badge.name,
          style: TextStyle(
            color: isUnlocked ? Colors.indigo[900] : Colors.grey[500],
            fontSize: 10,
            fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '${badge.requiredWeeks}週',
          style: TextStyle(
            color: isUnlocked ? Colors.indigo[700] : Colors.grey[500],
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
