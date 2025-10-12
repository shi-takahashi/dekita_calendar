import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../controllers/habit_controller.dart';
import '../models/habit.dart';
import '../models/badge.dart';
import '../services/badge_service.dart';
import '../widgets/badge_widget.dart';
import '../widgets/shooting_star_animation.dart';
import 'add_habit_screen.dart';
import 'edit_habit_screen.dart';
import 'help_screen.dart';

class HomeView extends StatefulWidget {
  final HabitController habitController;

  const HomeView({
    super.key,
    required this.habitController,
  });

  @override
  HomeViewState createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  final _badgeService = BadgeService();
  BadgeProgress? _badgeProgress;
  bool _isUpdating = false; // 更新中フラグで無限ループ防止

  /// 外部から呼び出すためのバッジ進捗更新メソッド
  void refreshBadgeProgress() {
    _loadBadgeProgress();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.habitController.loadHabits();
      _loadBadgeProgress();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('📱 アプリ再開: バッジ進捗を更新');
      _loadBadgeProgress();
    }
  }

  Future<void> _loadBadgeProgress() async {
    if (_isUpdating) {
      print('⚠️ 既に更新中のため、スキップ');
      return;
    }

    _isUpdating = true;
    print('🏅 バッジ進捗読み込み開始');

    try {
      // まず未表示のバッジをチェック（カレンダー画面などで獲得したバッジ）
      final pendingBadges = await _badgeService.getPendingBadges();
      if (pendingBadges.isNotEmpty && mounted) {
        // 複数獲得した場合は最高価値のものだけを表示
        final highestBadge = pendingBadges.reduce((a, b) =>
          a.requiredWeeks > b.requiredWeeks ? a : b
        );

        print('🎉 未表示バッジを検出: ${highestBadge.name}');

        // 未表示フラグをクリア
        await _badgeService.clearPendingBadges();

        // 少し待ってから演出を開始
        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) {
          // 流れ星アニメーション（バッジを渡す）
          ShootingStarAnimation.show(context, highestBadge);

          // アニメーションの長さに応じて待つ
          final animationDuration = _getAnimationDuration(highestBadge.type);
          await Future.delayed(Duration(milliseconds: animationDuration + 800));

          if (mounted) {
            _showBadgeAchievedDialog(context, highestBadge);
          }
        }
      }

      // 現在の進捗を取得
      final currentProgress = await _badgeService.getCurrentProgress();

      print('🏅 現在の進捗: 連続${currentProgress.currentStreak}週, バッジ${currentProgress.unlockedBadgeIds.length}個獲得');

      if (!mounted) return;

      setState(() {
        _badgeProgress = currentProgress;
      });

      // 習慣データから進捗を更新（ホーム画面で完了した場合のため）
      final habits = widget.habitController.habits;
      if (habits.isNotEmpty) {
        final oldProgress = currentProgress;
        final newProgress = await _badgeService.updateProgress(habits);

        if (!mounted) return;

        setState(() {
          _badgeProgress = newProgress;
        });

        print('🏅 更新後の進捗: 連続${newProgress.currentStreak}週, バッジ${newProgress.unlockedBadgeIds.length}個獲得');

        // 新しいバッジを獲得したかチェック（ホーム画面で完了した場合）
        final newBadges = _badgeService.getNewlyUnlockedBadges(oldProgress, newProgress);
        if (newBadges.isNotEmpty) {
          // 複数獲得した場合は最高価値のものだけを表示
          final highestBadge = newBadges.reduce((a, b) =>
            a.requiredWeeks > b.requiredWeeks ? a : b
          );

          print('🎉 新しいバッジを獲得: ${highestBadge.name}');

          // 少し待ってから演出を開始
          await Future.delayed(const Duration(milliseconds: 300));

          if (mounted) {
            // 流れ星アニメーション（バッジを渡す）
            ShootingStarAnimation.show(context, highestBadge);

            // アニメーションの長さに応じて待つ
            final animationDuration = _getAnimationDuration(highestBadge.type);
            await Future.delayed(Duration(milliseconds: animationDuration + 800));

            if (mounted) {
              _showBadgeAchievedDialog(context, highestBadge);
            }
          }
        }
      }
    } finally {
      _isUpdating = false;
      print('🏅 バッジ進捗読み込み完了');
    }
  }

  /// アニメーション時間を取得（全バッジ統一）
  int _getAnimationDuration(BadgeType type) {
    return 1800; // 全バッジで統一（ダイヤモンド相当）
  }

  /// バッジ獲得ダイアログを表示
  void _showBadgeAchievedDialog(BuildContext context, AchievementBadge badge) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => _BadgeAchievedDialog(badge: badge),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('今日の習慣'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.habitController,
        builder: (context, child) {
          if (widget.habitController.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final todayHabits = widget.habitController.getTodayHabits();

          return RefreshIndicator(
            onRefresh: () async {
              await widget.habitController.loadHabits();
              await _loadBadgeProgress();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // バッジ表示
                if (_badgeProgress != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: BadgeCollectionWidget(
                        progress: _badgeProgress!,
                      ),
                    ),
                  ),
                // デバッグパネル（デバッグビルドのみ）
                if (kDebugMode && _badgeProgress != null)
                  SliverToBoxAdapter(
                    child: _BadgeDebugPanel(
                      badgeService: _badgeService,
                      progress: _badgeProgress!,
                      onRefresh: _loadBadgeProgress,
                      onShowBadgeDialog: (badges) => _showBadgeAchievedDialog(context, badges),
                    ),
                  ),
                // 習慣リストまたは案内メッセージ
                if (todayHabits.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.habitController.habits.isEmpty
                                  ? Icons.event_available
                                  : Icons.free_breakfast,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              widget.habitController.habits.isEmpty
                                  ? 'まだ習慣が登録されていません'
                                  : '今日の習慣はありません',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.habitController.habits.isEmpty
                                  ? '右下の＋ボタンをタップして\n新しい習慣を追加してみましょう'
                                  : '今日は予定されている習慣がありません\nゆっくり休んでください',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final habit = todayHabits[index];
                          final today = DateTime.now();
                          final isCompleted = habit.isCompletedOnDate(today);

                          return _HabitCard(
                            habit: habit,
                            isCompleted: isCompleted,
                            onTap: () async {
                              await widget.habitController.toggleHabitCompletion(
                                habit.id,
                                today,
                              );
                              await _loadBadgeProgress();
                            },
                            onEdit: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditHabitScreen(
                                    habitController: widget.habitController,
                                    habit: habit,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        childCount: todayHabits.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddHabitScreen(
                habitController: widget.habitController,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final bool isCompleted;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _HabitCard({
    required this.habit,
    required this.isCompleted,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isCompleted ? Colors.green[50] : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    width: 2,
                  ),
                  color: isCompleted
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            habit.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: isCompleted ? Colors.grey[600] : null,
                                ),
                          ),
                        ),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '本日完了✓',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: habit.currentStreak > 0
                              ? Colors.orange
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${habit.currentStreak}日',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(width: 16),
                        _buildFrequencyText(context),
                      ],
                    ),
                    if (isCompleted)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _getNextMessage(habit),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green[700],
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: onEdit,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencyText(BuildContext context) {
    String frequencyText;
    switch (habit.frequency) {
      case HabitFrequency.daily:
        frequencyText = '毎日';
        break;
      case HabitFrequency.specificDays:
        final days = ['月', '火', '水', '木', '金', '土', '日'];
        final selectedDays = habit.specificDays!
            .map((day) => days[day - 1])
            .join(',');
        frequencyText = selectedDays;
        break;
    }

    return Row(
      children: [
        Icon(
          Icons.repeat,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          frequencyText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  String _getNextMessage(Habit habit) {
    final today = DateTime.now();

    switch (habit.frequency) {
      case HabitFrequency.daily:
        return '明日も続けましょう！';

      case HabitFrequency.specificDays:
        final nextDate = _getNextScheduledDate(habit, today);
        if (nextDate == null) {
          return '次回も頑張りましょう！';
        }

        final daysDiff = nextDate.difference(today).inDays;
        if (daysDiff == 1) {
          return '明日も続けましょう！';
        } else if (daysDiff <= 7) {
          final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
          final nextWeekday = weekdays[nextDate.weekday - 1];
          return '次は${nextWeekday}曜日です！';
        } else {
          return '次回も頑張りましょう！';
        }
    }
  }

  DateTime? _getNextScheduledDate(Habit habit, DateTime today) {
    if (habit.specificDays == null || habit.specificDays!.isEmpty) {
      return null;
    }

    for (int i = 1; i <= 7; i++) {
      final nextDate = today.add(Duration(days: i));
      if (habit.specificDays!.contains(nextDate.weekday)) {
        return nextDate;
      }
    }

    return null;
  }

}

/// バッジ用デバッグパネル（デバッグビルドのみ表示）
class _BadgeDebugPanel extends StatefulWidget {
  final BadgeService badgeService;
  final BadgeProgress progress;
  final VoidCallback onRefresh;
  final Function(AchievementBadge) onShowBadgeDialog;

  const _BadgeDebugPanel({
    required this.badgeService,
    required this.progress,
    required this.onRefresh,
    required this.onShowBadgeDialog,
  });

  @override
  State<_BadgeDebugPanel> createState() => _BadgeDebugPanelState();
}

class _BadgeDebugPanelState extends State<_BadgeDebugPanel> {
  final TextEditingController _streakController = TextEditingController();
  bool _isExpanded = false;
  bool _isDebugMode = false;

  @override
  void initState() {
    super.initState();
    _streakController.text = widget.progress.currentStreak.toString();
    _loadDebugMode();
  }

  @override
  void didUpdateWidget(_BadgeDebugPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress.currentStreak != widget.progress.currentStreak) {
      _streakController.text = widget.progress.currentStreak.toString();
    }
  }

  @override
  void dispose() {
    _streakController.dispose();
    super.dispose();
  }

  Future<void> _loadDebugMode() async {
    final isDebugMode = await widget.badgeService.isDebugModeEnabled();
    if (mounted) {
      setState(() {
        _isDebugMode = isDebugMode;
      });
    }
  }

  Future<void> _setStreak() async {
    final streak = int.tryParse(_streakController.text);
    if (streak != null && streak >= 0) {
      // 変更前の進捗を取得
      final oldProgress = await widget.badgeService.getCurrentProgress();

      // デバッグ用にstreakを設定
      await widget.badgeService.debugSetStreak(streak);
      await _loadDebugMode();

      // 新しい進捗を取得
      final newProgress = await widget.badgeService.getCurrentProgress();

      // UIを更新
      widget.onRefresh();

      // 新しくバッジを獲得したかチェック
      final newBadges = widget.badgeService.getNewlyUnlockedBadges(oldProgress, newProgress);
      if (newBadges.isNotEmpty && mounted) {
        // 複数獲得した場合は最高価値のものだけを表示
        final highestBadge = newBadges.reduce((a, b) =>
          a.requiredWeeks > b.requiredWeeks ? a : b
        );

        print('🎉 [DEBUG] 新しいバッジを獲得: ${highestBadge.name}');

        // 少し待ってから演出を開始
        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) {
          // 流れ星アニメーション（バッジを渡す）
          ShootingStarAnimation.show(context, highestBadge);

          // アニメーションの長さに応じて待つ
          final animationDuration = _getAnimationDuration(highestBadge.type);
          await Future.delayed(Duration(milliseconds: animationDuration + 800));

          if (mounted) {
            widget.onShowBadgeDialog(highestBadge);
          }
        }
      }
    }
  }

  /// アニメーション時間を取得（全バッジ統一）
  int _getAnimationDuration(BadgeType type) {
    return 1800; // 全バッジで統一（ダイヤモンド相当）
  }

  Future<void> _disableDebugMode() async {
    await widget.badgeService.debugDisableDebugMode();
    await _loadDebugMode();
    widget.onRefresh();
  }

  Future<void> _resetAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('全てリセット'),
        content: const Text('全ての進捗をリセットしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('リセット', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.badgeService.debugResetAll();
      await _loadDebugMode();
      widget.onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: Colors.orange[50],
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.bug_report, color: Colors.orange),
              title: Row(
                children: [
                  const Text(
                    'デバッグパネル',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (_isDebugMode) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'DEBUG',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Text('連続${widget.progress.currentStreak}日 / バッジ${widget.progress.unlockedBadgeIds.length}個'),
              trailing: IconButton(
                icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              ),
            ),
            if (_isExpanded)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // デバッグモード状態表示
                    if (_isDebugMode)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'デバッグモード有効: 習慣完了しても連続週数は固定されます',
                                style: TextStyle(fontSize: 12, color: Colors.red),
                              ),
                            ),
                            TextButton(
                              onPressed: _disableDebugMode,
                              child: const Text('解除', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    // 連続週数設定
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _streakController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '連続週数',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _setStreak,
                          child: const Text('設定'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // クイックボタン
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            _streakController.text = '0';
                            _setStreak();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('0にリセット'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _streakController.text = '4';
                            _setStreak();
                          },
                          icon: const Icon(Icons.fast_forward),
                          label: const Text('4週に設定'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _streakController.text = '13';
                            _setStreak();
                          },
                          icon: const Icon(Icons.workspace_premium),
                          label: const Text('13週に設定'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _resetAll,
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('全てリセット'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// バッジ獲得ダイアログ
class _BadgeAchievedDialog extends StatefulWidget {
  final AchievementBadge badge;

  const _BadgeAchievedDialog({required this.badge});

  @override
  State<_BadgeAchievedDialog> createState() => _BadgeAchievedDialogState();
}

class _BadgeAchievedDialogState extends State<_BadgeAchievedDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // elasticOutを使わずに、bounceOutを使用
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.bounceOut),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.badge.color.withOpacity(0.9),
                    widget.badge.color.withOpacity(0.7),
                    Colors.indigo[900]!.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.badge.color.withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // キラキラアイコン
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // 後ろの輝き
                      Transform.rotate(
                        angle: _rotationAnimation.value,
                        child: Icon(
                          Icons.auto_awesome,
                          color: Colors.yellow.withOpacity(0.3),
                          size: 100,
                        ),
                      ),
                      const Icon(
                        Icons.celebration,
                        color: Colors.yellow,
                        size: 70,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // タイトル
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        Colors.yellow[300]!,
                        Colors.orange[300]!,
                        Colors.yellow[300]!,
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      'バッジゲット！',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // バッジ
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // 光の輪
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      // バッジ本体
                      Transform.rotate(
                        angle: _rotationAnimation.value * 0.5,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                widget.badge.color,
                                widget.badge.color.withOpacity(0.7),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.badge.color.withOpacity(0.8),
                                blurRadius: 25,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Transform.rotate(
                            angle: -_rotationAnimation.value * 0.5,
                            child: Icon(
                              widget.badge.icon,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // バッジ名
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.badge.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 連続週数
                  Text(
                    '${widget.badge.requiredWeeks}週連続達成！',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // OKボタン
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: widget.badge.color,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}