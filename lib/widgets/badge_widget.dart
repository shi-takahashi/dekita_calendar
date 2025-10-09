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
    final nextBadge = BadgeService().getNextBadge(progress);
    final totalBadges = BadgeService.availableBadges.length;
    final unlockedCount = progress.unlockedBadgeIds.length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo[900]!,
            Colors.purple[900]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '連続達成',
                      style: TextStyle(
                        color: Colors.white70,
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '日',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // バッジカウント
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$unlockedCount/$totalBadges',
                    style: const TextStyle(
                      color: Colors.white,
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
                  color: Colors.white.withOpacity(0.1),
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'あと${nextBadge.requiredDays - progress.currentStreak}日',
                            style: const TextStyle(
                              color: Colors.white70,
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
            color: isUnlocked ? badge.color : Colors.grey[800],
            border: Border.all(
              color: isUnlocked ? Colors.white.withOpacity(0.3) : Colors.grey[700]!,
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
            color: isUnlocked ? Colors.white : Colors.grey[600],
            size: 28,
          ),
        ),
        const SizedBox(height: 4),
        // バッジ名
        Text(
          badge.name,
          style: TextStyle(
            color: isUnlocked ? Colors.white : Colors.grey[600],
            fontSize: 10,
            fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '${badge.requiredDays}日',
          style: TextStyle(
            color: isUnlocked ? Colors.white70 : Colors.grey[700],
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
