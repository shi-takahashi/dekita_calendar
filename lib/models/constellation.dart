/// 星座機能のデータモデル

/// 星の位置情報
class StarPosition {
  final double x; // 0.0 - 1.0 (相対座標)
  final double y; // 0.0 - 1.0 (相対座標)
  final int unlockDay; // この星が解放される日数（1始まり）

  const StarPosition({
    required this.x,
    required this.y,
    required this.unlockDay,
  });

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'unlockDay': unlockDay,
      };

  factory StarPosition.fromJson(Map<String, dynamic> json) => StarPosition(
        x: json['x'] as double,
        y: json['y'] as double,
        unlockDay: json['unlockDay'] as int,
      );
}

/// 星を結ぶ線の情報
class StarConnection {
  final int fromIndex; // 始点の星のインデックス
  final int toIndex; // 終点の星のインデックス

  const StarConnection({
    required this.fromIndex,
    required this.toIndex,
  });

  Map<String, dynamic> toJson() => {
        'fromIndex': fromIndex,
        'toIndex': toIndex,
      };

  factory StarConnection.fromJson(Map<String, dynamic> json) =>
      StarConnection(
        fromIndex: json['fromIndex'] as int,
        toIndex: json['toIndex'] as int,
      );
}

/// 星座の定義
class Constellation {
  final String id;
  final String name;
  final List<StarPosition> stars; // 星の座標リスト
  final List<StarConnection> lines; // 星を結ぶ線
  final int requiredDays; // 完成に必要な日数

  const Constellation({
    required this.id,
    required this.name,
    required this.stars,
    required this.lines,
    required this.requiredDays,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'stars': stars.map((s) => s.toJson()).toList(),
        'lines': lines.map((l) => l.toJson()).toList(),
        'requiredDays': requiredDays,
      };

  factory Constellation.fromJson(Map<String, dynamic> json) => Constellation(
        id: json['id'] as String,
        name: json['name'] as String,
        stars: (json['stars'] as List)
            .map((s) => StarPosition.fromJson(s as Map<String, dynamic>))
            .toList(),
        lines: (json['lines'] as List)
            .map((l) => StarConnection.fromJson(l as Map<String, dynamic>))
            .toList(),
        requiredDays: json['requiredDays'] as int,
      );
}

/// 星座の進捗状態
class ConstellationProgress {
  final String constellationId;
  final int currentStreak; // 現在の連続日数
  final List<int> unlockedStars; // 解放済みの星インデックス
  final bool isCompleted; // 完成済みフラグ
  final DateTime? completedAt; // 完成日時
  final bool celebrationShown; // お祝いアニメーション表示済みフラグ

  const ConstellationProgress({
    required this.constellationId,
    required this.currentStreak,
    required this.unlockedStars,
    required this.isCompleted,
    this.completedAt,
    this.celebrationShown = false,
  });

  Map<String, dynamic> toJson() => {
        'constellationId': constellationId,
        'currentStreak': currentStreak,
        'unlockedStars': unlockedStars,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
        'celebrationShown': celebrationShown,
      };

  factory ConstellationProgress.fromJson(Map<String, dynamic> json) =>
      ConstellationProgress(
        constellationId: json['constellationId'] as String,
        currentStreak: json['currentStreak'] as int,
        unlockedStars: (json['unlockedStars'] as List).cast<int>(),
        isCompleted: json['isCompleted'] as bool,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        celebrationShown: json['celebrationShown'] as bool? ?? false,
      );

  ConstellationProgress copyWith({
    String? constellationId,
    int? currentStreak,
    List<int>? unlockedStars,
    bool? isCompleted,
    DateTime? completedAt,
    bool? celebrationShown,
  }) {
    return ConstellationProgress(
      constellationId: constellationId ?? this.constellationId,
      currentStreak: currentStreak ?? this.currentStreak,
      unlockedStars: unlockedStars ?? this.unlockedStars,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      celebrationShown: celebrationShown ?? this.celebrationShown,
    );
  }
}

/// 完成した星座の記録
class CompletedConstellation {
  final String constellationId;
  final DateTime completedAt;

  const CompletedConstellation({
    required this.constellationId,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'constellationId': constellationId,
        'completedAt': completedAt.toIso8601String(),
      };

  factory CompletedConstellation.fromJson(Map<String, dynamic> json) =>
      CompletedConstellation(
        constellationId: json['constellationId'] as String,
        completedAt: DateTime.parse(json['completedAt'] as String),
      );
}

/// 星座コレクション全体の管理
class ConstellationCollection {
  final String currentConstellationId; // 現在チャレンジ中の星座ID
  final List<CompletedConstellation> completedConstellations; // 完成した星座リスト

  const ConstellationCollection({
    required this.currentConstellationId,
    required this.completedConstellations,
  });

  Map<String, dynamic> toJson() => {
        'currentConstellationId': currentConstellationId,
        'completedConstellations':
            completedConstellations.map((c) => c.toJson()).toList(),
      };

  factory ConstellationCollection.fromJson(Map<String, dynamic> json) =>
      ConstellationCollection(
        currentConstellationId: json['currentConstellationId'] as String,
        completedConstellations: (json['completedConstellations'] as List)
            .map((c) => CompletedConstellation.fromJson(c as Map<String, dynamic>))
            .toList(),
      );

  ConstellationCollection copyWith({
    String? currentConstellationId,
    List<CompletedConstellation>? completedConstellations,
  }) {
    return ConstellationCollection(
      currentConstellationId: currentConstellationId ?? this.currentConstellationId,
      completedConstellations: completedConstellations ?? this.completedConstellations,
    );
  }
}
