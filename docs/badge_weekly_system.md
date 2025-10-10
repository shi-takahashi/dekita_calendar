# バッジシステムの週単位化 - 実装ガイド

## 背景

現在のバッジシステムは「連続日数」ベースで動作している。これには以下の問題がある：

- **毎日の習慣**: 365日で最高ランク達成（約1年）
- **週1回の習慣**（例：月曜のみ）: 365日達成 = 7年かかる
- 習慣の頻度によって達成難易度が大きく異なり、不公平

このため、週単位の評価システムに移行する。

## 解決策：週単位の評価システム

### 基本コンセプト

**週クリア条件:**
- その週（月曜〜日曜）に予定されている全ての習慣を完了したら「週クリア」
- 毎日の習慣でも週1の習慣でも公平に評価

### 具体例

**毎日の習慣のみ設定している場合:**
- 月曜〜日曜まで7日間全て完了 → 1週クリア

**月・水の習慣のみ設定している場合:**
- その週の月曜と水曜を両方完了 → 1週クリア

**複数習慣（毎日 + 月・水）設定している場合:**
- 日曜の毎日習慣を完了した時点で、その週の全予定が完了 → 1週クリア
- （月〜日の毎日習慣 + 月・水の習慣、全て完了している状態）

## 新しいバッジ条件（週単位）

```
ブロンズ: 1週連続
シルバー: 2週連続
ゴールド: 4週連続（約1ヶ月）
プラチナ: 12週連続（約3ヶ月）
ダイヤモンド: 52週連続（1年）
```

### メリット

1. **公平性**: どの頻度の習慣でも同じ期間で評価される
2. **分かりやすさ**: 「1週間頑張った」という単位が直感的
3. **達成可能性**: 週1習慣でも1年で最高ランク到達可能

## 実装の変更点

### 1. モデルの変更

**badge.dart:**
- `requiredDays: int` → `requiredWeeks: int` に変更
- または互換性のため両方保持

### 2. 計算ロジックの変更

**badge_service.dart:**

新しいメソッド `calculateWeeklyStreak()` を実装:
```dart
/// 週単位の連続達成数を計算
int calculateWeeklyStreak(List<Habit> habits) {
  // 週の定義: 日曜0:00 〜 土曜23:59
  // 今週から遡って、各週が完全クリアされているか判定
  // 1週でも未達成があれば連続終了
}
```

週クリア判定:
```dart
/// 指定した週が全てクリアされているか
bool _isWeekCompleted(List<Habit> habits, DateTime weekStart) {
  // その週（日曜〜土曜）に予定されている全習慣の完了を確認
  // 例：月・水習慣なら、その週の月曜と水曜が完了しているか
}
```

### 3. UI表示の変更

**badge_widget.dart:**
- 「連続達成 ○日」→ 「○週目チャレンジ中」
- 「あと○日」→ 「あと○週」

**バッジ表示:**
- 「3日」→ 「1週」
- 「7日」→ 「2週」
- 「30日」→ 「4週」
- 「100日」→ 「12週」
- 「365日」→ 「52週」

### 4. デバッグ機能の調整

デバッグパネルで連続週数を設定できるように変更

## 実装時の注意点

### 週の定義
- 週の開始: 月曜 00:00:00
- 週の終了: 日曜 23:59:59
- `DateTime.weekday` を使用（月曜=1, 日曜=7）

### 今週の扱い
- 今週が完全クリアされている場合: 連続週数に含める
- 今週がまだ途中の場合: 先週までの連続を表示（「○週目チャレンジ中」）

### 連続の中断
- ある週に予定された習慣を1つでもスキップ → その週は未達成 → 連続終了
- 次の週からは新たに連続カウント開始

### バッジの永続化
- 一度獲得したバッジは、連続が途切れても保持（現在の仕様を維持）

## データ移行

既存ユーザーのデータ移行は不要:
- バッジ進捗は `SharedPreferences` に保存
- 次回起動時に週単位で再計算される
- 既存の獲得済みバッジは保持される

## テストケース

1. **毎日習慣**: 7日完了 → 1週クリア
2. **週1習慣（月曜）**: 月曜完了 → 1週クリア
3. **複数習慣**: 全習慣の予定を完了 → 1週クリア
4. **週途中**: 週の途中まで完了 → 「○週目チャレンジ中」表示
5. **スキップ**: 1日スキップ → その週は未達成 → 連続リセット
6. **連続**: 4週連続クリア → ゴールド獲得

---

## 実装手順（次回セッション用）

### ステップ1: モデルの更新

**ファイル: `lib/models/badge.dart`**

`AchievementBadge` クラスに `requiredWeeks` プロパティを追加（または `requiredDays` を置き換え）。

```dart
class AchievementBadge {
  final String id;
  final String name;
  final BadgeType type;
  final int requiredWeeks; // 変更: requiredDays → requiredWeeks
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
```

### ステップ2: バッジサービスの更新

**ファイル: `lib/services/badge_service.dart`**

#### 2-1. バッジ定義を週単位に更新

```dart
static const List<AchievementBadge> availableBadges = [
  AchievementBadge(
    id: 'bronze',
    name: 'ブロンズ',
    type: BadgeType.bronze,
    requiredWeeks: 1,  // 変更: 3 → 1
    color: Color(0xFFCD7F32),
    icon: Icons.star_outline,
  ),
  AchievementBadge(
    id: 'silver',
    name: 'シルバー',
    type: BadgeType.silver,
    requiredWeeks: 2,  // 変更: 7 → 2
    color: Color(0xFFC0C0C0),
    icon: Icons.star,
  ),
  // ... 以下同様に更新
];
```

#### 2-2. 週の開始日を取得するヘルパーメソッド

```dart
/// 指定日を含む週の開始日（月曜日）を取得
DateTime _getWeekStart(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final weekday = normalized.weekday; // 月曜=1, 日曜=7
  final daysToSubtract = weekday - 1; // 月曜なら0、火曜なら1、...、日曜なら6
  return normalized.subtract(Duration(days: daysToSubtract));
}
```

#### 2-3. 週クリア判定メソッド

```dart
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
```

#### 2-4. 週連続数の計算メソッド（既存の `calculateAllHabitsStreak` を置き換え）

```dart
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
```

#### 2-5. `updateProgress` メソッドの更新

```dart
Future<BadgeProgress> updateProgress(List<Habit> habits) async {
  final prefs = await SharedPreferences.getInstance();
  final debugMode = prefs.getBool(_debugModeKey) ?? false;
  final currentProgress = await getCurrentProgress();

  // 週単位で計算（デバッグモード対応）
  final streak = debugMode
      ? (prefs.getInt(_debugStreakKey) ?? 0)
      : calculateWeeklyStreak(habits);  // 変更: calculateAllHabitsStreak → calculateWeeklyStreak

  print('🏅 バッジ進捗更新: 連続${streak}週');  // 変更: 日 → 週

  final unlockedBadgeIds = Set<String>.from(currentProgress.unlockedBadgeIds);
  for (final badge in availableBadges) {
    if (streak >= badge.requiredWeeks) {  // 変更: requiredDays → requiredWeeks
      unlockedBadgeIds.add(badge.id);
    }
  }

  final newProgress = BadgeProgress(
    currentStreak: streak,  // 週数を保存
    unlockedBadgeIds: unlockedBadgeIds.toList(),
    lastUpdated: DateTime.now(),
  );

  await saveProgress(newProgress);
  return newProgress;
}
```

### ステップ3: UIの更新

**ファイル: `lib/widgets/badge_widget.dart`**

#### 3-1. ヘッダー表示の変更

```dart
// 変更前
Text(
  '連続達成',
  style: TextStyle(
    color: Colors.indigo[700],
    fontSize: 14,
  ),
),

// 変更後
Text(
  progress.currentStreak > 0
    ? '${progress.currentStreak}週目チャレンジ中'
    : '連続達成',
  style: TextStyle(
    color: Colors.indigo[700],
    fontSize: 14,
  ),
),
```

または週数の大きな表示はそのまま残して単位だけ変更：

```dart
Text(
  '週',  // 変更: '日' → '週'
  style: TextStyle(
    color: Colors.indigo[700],
    fontSize: 18,
  ),
),
```

#### 3-2. 次の目標表示の変更

```dart
Text(
  'あと${nextBadge.requiredWeeks - progress.currentStreak}週',  // 変更: requiredDays/日 → requiredWeeks/週
  style: TextStyle(
    color: Colors.indigo[700],
    fontSize: 12,
  ),
),
```

#### 3-3. バッジアイテムの表示変更

```dart
Text(
  '${badge.requiredWeeks}週',  // 変更: requiredDays/日 → requiredWeeks/週
  style: TextStyle(
    color: isUnlocked ? Colors.indigo[700] : Colors.grey[500],
    fontSize: 9,
  ),
),
```

### ステップ4: デバッグパネルの更新

**ファイル: `lib/views/home_view.dart`**

デバッグパネル内の表示を「日」→「週」に変更：

```dart
TextField(
  controller: _streakController,
  decoration: const InputDecoration(
    labelText: '連続週数',  // 変更: 連続日数 → 連続週数
    // ...
  ),
),
```

クイック設定ボタンも週数に合わせて調整：

```dart
ElevatedButton(
  onPressed: () {
    _streakController.text = '4';  // 変更: 例えば '30' → '4'（ゴールド）
    _setStreak();
  },
  child: const Text('ゴールド'),
),
```

### ステップ5: アニメーション時間の調整（オプション）

週単位でバッジを獲得する場合、獲得頻度が変わるため、必要に応じてアニメーション時間を調整。

### 完了チェックリスト

実装完了時にチェック：

- [ ] モデル: `requiredWeeks` に変更
- [ ] サービス: 週計算ロジック実装
- [ ] サービス: バッジ定義更新（1, 2, 4, 12, 52週）
- [ ] UI: 「日」→「週」表示変更
- [ ] UI: 「○週目チャレンジ中」表示
- [ ] デバッグパネル: 週数設定に変更
- [ ] テスト: 毎日習慣で1週クリア確認
- [ ] テスト: 週1習慣で1週クリア確認
- [ ] テスト: 連続リセット動作確認
