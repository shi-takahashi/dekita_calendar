import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/constellation.dart';
import '../models/habit.dart';

/// 星座管理サービス
class ConstellationService {
  static const String _progressKey = 'constellation_progress';
  static const String _collectionKey = 'constellation_collection';
  static const String _debugModeKey = 'constellation_debug_mode';
  static const String _debugStreakKey = 'constellation_debug_streak';

  /// 利用可能な星座一覧を取得（順番通り）
  List<Constellation> getAvailableConstellations() {
    return [
      _cassiopeia,
      _bigDipper,
      _orion,
      _scorpius,
      _lyra,
      _cygnus,
      _aquila,
      _pegasus,
      _leo,
      _taurus,
      _gemini,
      _aquarius,
      _virgo,
      _libra,
      _sagittarius,
      _capricornus,
      _pisces,
      _aries,
      _cancer,
      _southernCross,
    ];
  }

  /// 1. カシオペア座（W字型の5つ星）
  static const Constellation _cassiopeia = Constellation(
    id: 'cassiopeia',
    name: 'カシオペア座',
    stars: [
      StarPosition(x: 0.15, y: 0.35, unlockDay: 1),
      StarPosition(x: 0.32, y: 0.6, unlockDay: 2),
      StarPosition(x: 0.5, y: 0.25, unlockDay: 3),
      StarPosition(x: 0.68, y: 0.55, unlockDay: 4),
      StarPosition(x: 0.85, y: 0.3, unlockDay: 5),
    ],
    lines: [
      StarConnection(fromIndex: 0, toIndex: 1),
      StarConnection(fromIndex: 1, toIndex: 2),
      StarConnection(fromIndex: 2, toIndex: 3),
      StarConnection(fromIndex: 3, toIndex: 4),
    ],
    requiredDays: 5,
  );

  /// 2. 北斗七星（おおぐま座の一部・柄杓の形）
  static const Constellation _bigDipper = Constellation(
    id: 'big_dipper',
    name: '北斗七星',
    stars: [
      // 柄杓の本体（四角形）
      StarPosition(x: 0.25, y: 0.45, unlockDay: 1), // 左下
      StarPosition(x: 0.25, y: 0.25, unlockDay: 2), // 左上
      StarPosition(x: 0.45, y: 0.25, unlockDay: 3), // 右上
      StarPosition(x: 0.45, y: 0.5, unlockDay: 4),  // 右下
      // 取っ手（曲線的に配置）
      StarPosition(x: 0.58, y: 0.55, unlockDay: 5), // 取っ手1
      StarPosition(x: 0.7, y: 0.5, unlockDay: 6),   // 取っ手2
      StarPosition(x: 0.82, y: 0.4, unlockDay: 7),  // 取っ手3
    ],
    lines: [
      // 柄杓本体の四角形
      StarConnection(fromIndex: 0, toIndex: 1),
      StarConnection(fromIndex: 1, toIndex: 2),
      StarConnection(fromIndex: 2, toIndex: 3),
      StarConnection(fromIndex: 3, toIndex: 0),
      // 取っ手
      StarConnection(fromIndex: 3, toIndex: 4),
      StarConnection(fromIndex: 4, toIndex: 5),
      StarConnection(fromIndex: 5, toIndex: 6),
    ],
    requiredDays: 7,
  );

  /// 3. オリオン座（三つ星が特徴・砂時計型）
  static const Constellation _orion = Constellation(
    id: 'orion',
    name: 'オリオン座',
    stars: [
      // 肩の星
      StarPosition(x: 0.3, y: 0.2, unlockDay: 1),  // ベテルギウス（左肩）
      StarPosition(x: 0.7, y: 0.2, unlockDay: 2),  // ベラトリックス（右肩）
      // 三つ星（ベルト）
      StarPosition(x: 0.38, y: 0.48, unlockDay: 3), // 左
      StarPosition(x: 0.5, y: 0.5, unlockDay: 4),   // 中央
      StarPosition(x: 0.62, y: 0.48, unlockDay: 5), // 右
      // 足の星
      StarPosition(x: 0.35, y: 0.8, unlockDay: 6),  // リゲル（左足）
      StarPosition(x: 0.65, y: 0.8, unlockDay: 7),  // サイフ（右足）
    ],
    lines: [
      // 左側のライン
      StarConnection(fromIndex: 0, toIndex: 2),
      StarConnection(fromIndex: 2, toIndex: 5),
      // 右側のライン
      StarConnection(fromIndex: 1, toIndex: 4),
      StarConnection(fromIndex: 4, toIndex: 6),
      // 三つ星
      StarConnection(fromIndex: 2, toIndex: 3),
      StarConnection(fromIndex: 3, toIndex: 4),
    ],
    requiredDays: 7,
  );

  /// 4. さそり座（S字カーブ）
  static const Constellation _scorpius = Constellation(
    id: 'scorpius',
    name: 'さそり座',
    stars: [
      // 頭部
      StarPosition(x: 0.25, y: 0.25, unlockDay: 1), // 頭
      StarPosition(x: 0.35, y: 0.3, unlockDay: 2),  // アンタレス
      // 体部
      StarPosition(x: 0.48, y: 0.38, unlockDay: 3),
      StarPosition(x: 0.58, y: 0.5, unlockDay: 4),
      // 尾部（カーブ）
      StarPosition(x: 0.65, y: 0.62, unlockDay: 5),
      StarPosition(x: 0.75, y: 0.7, unlockDay: 6),
      StarPosition(x: 0.82, y: 0.65, unlockDay: 7), // 尾の先端（上に曲がる）
    ],
    lines: [
      StarConnection(fromIndex: 0, toIndex: 1),
      StarConnection(fromIndex: 1, toIndex: 2),
      StarConnection(fromIndex: 2, toIndex: 3),
      StarConnection(fromIndex: 3, toIndex: 4),
      StarConnection(fromIndex: 4, toIndex: 5),
      StarConnection(fromIndex: 5, toIndex: 6),
    ],
    requiredDays: 7,
  );

  /// 5. こと座（ベガを含む・平行四辺形）
  static const Constellation _lyra = Constellation(
    id: 'lyra',
    name: 'こと座',
    stars: [
      StarPosition(x: 0.5, y: 0.25, unlockDay: 1),  // ベガ（最も明るい星）
      StarPosition(x: 0.38, y: 0.48, unlockDay: 2),
      StarPosition(x: 0.62, y: 0.48, unlockDay: 3),
      StarPosition(x: 0.33, y: 0.7, unlockDay: 4),
      StarPosition(x: 0.57, y: 0.7, unlockDay: 5),
    ],
    lines: [
      StarConnection(fromIndex: 0, toIndex: 1),
      StarConnection(fromIndex: 0, toIndex: 2),
      StarConnection(fromIndex: 1, toIndex: 3),
      StarConnection(fromIndex: 2, toIndex: 4),
      StarConnection(fromIndex: 3, toIndex: 4),
    ],
    requiredDays: 5,
  );

  /// 6. はくちょう座（北十字）
  static const Constellation _cygnus = Constellation(
    id: 'cygnus',
    name: 'はくちょう座',
    stars: [
      StarPosition(x: 0.5, y: 0.2, unlockDay: 1),  // デネブ（尾）
      StarPosition(x: 0.5, y: 0.45, unlockDay: 2), // 中心
      StarPosition(x: 0.3, y: 0.45, unlockDay: 3), // 左翼
      StarPosition(x: 0.7, y: 0.45, unlockDay: 4), // 右翼
      StarPosition(x: 0.5, y: 0.75, unlockDay: 5), // 頭
    ],
    lines: [
      // 縦のライン（尾から頭）
      StarConnection(fromIndex: 0, toIndex: 1),
      StarConnection(fromIndex: 1, toIndex: 4),
      // 横のライン（翼）
      StarConnection(fromIndex: 2, toIndex: 1),
      StarConnection(fromIndex: 1, toIndex: 3),
    ],
    requiredDays: 5,
  );

  /// 7. わし座（アルタイルを含む・V字型）
  static const Constellation _aquila = Constellation(
    id: 'aquila',
    name: 'わし座',
    stars: [
      StarPosition(x: 0.5, y: 0.28, unlockDay: 1),  // アルタイル（中央）
      StarPosition(x: 0.38, y: 0.5, unlockDay: 2),  // 左翼
      StarPosition(x: 0.62, y: 0.5, unlockDay: 3),  // 右翼
      StarPosition(x: 0.28, y: 0.72, unlockDay: 4), // 左端
      StarPosition(x: 0.72, y: 0.72, unlockDay: 5), // 右端
    ],
    lines: [
      StarConnection(fromIndex: 0, toIndex: 1),
      StarConnection(fromIndex: 0, toIndex: 2),
      StarConnection(fromIndex: 1, toIndex: 3),
      StarConnection(fromIndex: 2, toIndex: 4),
    ],
    requiredDays: 5,
  );

  /// 8. ペガスス座（秋の四辺形）
  static const Constellation _pegasus = Constellation(
    id: 'pegasus',
    name: 'ペガスス座',
    stars: [
      StarPosition(x: 0.28, y: 0.35, unlockDay: 1),
      StarPosition(x: 0.72, y: 0.35, unlockDay: 2),
      StarPosition(x: 0.72, y: 0.68, unlockDay: 3),
      StarPosition(x: 0.28, y: 0.68, unlockDay: 4),
    ],
    lines: [
      StarConnection(fromIndex: 0, toIndex: 1),
      StarConnection(fromIndex: 1, toIndex: 2),
      StarConnection(fromIndex: 2, toIndex: 3),
      StarConnection(fromIndex: 3, toIndex: 0),
    ],
    requiredDays: 4,
  );

  /// 9. しし座（逆クエスチョンマーク型）
  static const Constellation _leo = Constellation(
    id: 'leo',
    name: 'しし座',
    stars: [
      // 頭部（逆クエスチョンマーク）
      StarPosition(x: 0.25, y: 0.3, unlockDay: 1),
      StarPosition(x: 0.38, y: 0.25, unlockDay: 2),
      StarPosition(x: 0.5, y: 0.28, unlockDay: 3),  // レグルス
      StarPosition(x: 0.55, y: 0.4, unlockDay: 4),
      // 体部
      StarPosition(x: 0.65, y: 0.55, unlockDay: 5),
      StarPosition(x: 0.72, y: 0.68, unlockDay: 6),
    ],
    lines: [
      StarConnection(fromIndex: 0, toIndex: 1),
      StarConnection(fromIndex: 1, toIndex: 2),
      StarConnection(fromIndex: 2, toIndex: 3),
      StarConnection(fromIndex: 3, toIndex: 4),
      StarConnection(fromIndex: 4, toIndex: 5),
    ],
    requiredDays: 6,
  );

  /// 10. おうし座（V字型）
  static const Constellation _taurus = Constellation(
    id: 'taurus',
    name: 'おうし座',
    stars: [
      StarPosition(x: 0.5, y: 0.3, unlockDay: 1),  // アルデバラン
      StarPosition(x: 0.35, y: 0.5, unlockDay: 2),
      StarPosition(x: 0.65, y: 0.5, unlockDay: 3),
      StarPosition(x: 0.25, y: 0.68, unlockDay: 4),
      StarPosition(x: 0.75, y: 0.68, unlockDay: 5),
    ],
    lines: [
      StarConnection(fromIndex: 0, toIndex: 1),
      StarConnection(fromIndex: 0, toIndex: 2),
      StarConnection(fromIndex: 1, toIndex: 3),
      StarConnection(fromIndex: 2, toIndex: 4),
    ],
    requiredDays: 5,
  );

  /// 11. ふたご座
  static const Constellation _gemini = Constellation(
    id: 'gemini',
    name: 'ふたご座',
    stars: [
      StarPosition(x: 0.3, y: 0.3, unlockDay: 1),
      StarPosition(x: 0.3, y: 0.7, unlockDay: 2),
      StarPosition(x: 0.4, y: 0.5, unlockDay: 3),
      StarPosition(x: 0.6, y: 0.3, unlockDay: 4),
      StarPosition(x: 0.6, y: 0.7, unlockDay: 5),
      StarPosition(x: 0.7, y: 0.5, unlockDay: 6),
    ],
    lines: [
      StarConnection(fromIndex: 0, toIndex: 2),
      StarConnection(fromIndex: 2, toIndex: 1),
      StarConnection(fromIndex: 3, toIndex: 5),
      StarConnection(fromIndex: 5, toIndex: 4),
      StarConnection(fromIndex: 2, toIndex: 5),
    ],
    requiredDays: 6,
  );

  /// 12. みずがめ座
  static const Constellation _aquarius = Constellation(
    id: 'aquarius',
    name: 'みずがめ座',
    stars: [
      StarPosition(x: 0.3, y: 0.3, unlockDay: 1),
      StarPosition(x: 0.45, y: 0.4, unlockDay: 2),
      StarPosition(x: 0.6, y: 0.35, unlockDay: 3),
      StarPosition(x: 0.4, y: 0.6, unlockDay: 4),
      StarPosition(x: 0.55, y: 0.65, unlockDay: 5),
      StarPosition(x: 0.7, y: 0.7, unlockDay: 6),
    ],
    lines: [
      StarConnection(fromIndex: 0, toIndex: 1),
      StarConnection(fromIndex: 1, toIndex: 2),
      StarConnection(fromIndex: 1, toIndex: 3),
      StarConnection(fromIndex: 3, toIndex: 4),
      StarConnection(fromIndex: 4, toIndex: 5),
    ],
    requiredDays: 6,
  );

  /// 13. おとめ座
  static const Constellation _virgo = Constellation(
    id: 'virgo',
    name: 'おとめ座',
    stars: [
      StarPosition(x: 0.4, y: 0.3, unlockDay: 1),
      StarPosition(x: 0.5, y: 0.45, unlockDay: 2),
      StarPosition(x: 0.6, y: 0.35, unlockDay: 3),
      StarPosition(x: 0.35, y: 0.6, unlockDay: 4),
      StarPosition(x: 0.5, y: 0.7, unlockDay: 5),
      StarPosition(x: 0.65, y: 0.65, unlockDay: 6),
    ],
    lines: [
      StarConnection(fromIndex: 0, toIndex: 1),
      StarConnection(fromIndex: 1, toIndex: 2),
      StarConnection(fromIndex: 1, toIndex: 3),
      StarConnection(fromIndex: 1, toIndex: 4),
      StarConnection(fromIndex: 2, toIndex: 5),
    ],
    requiredDays: 6,
  );

  /// 14. てんびん座
  static const Constellation _libra = Constellation(
    id: 'libra',
    name: 'てんびん座',
    stars: [
      StarPosition(x: 0.3, y: 0.4, unlockDay: 1),
      StarPosition(x: 0.5, y: 0.5, unlockDay: 2),
      StarPosition(x: 0.7, y: 0.4, unlockDay: 3),
      StarPosition(x: 0.5, y: 0.7, unlockDay: 4),
    ],
    lines: [
      StarConnection(fromIndex: 0, toIndex: 1),
      StarConnection(fromIndex: 1, toIndex: 2),
      StarConnection(fromIndex: 1, toIndex: 3),
    ],
    requiredDays: 4,
  );

  /// 15. いて座
  static const Constellation _sagittarius = Constellation(
    id: 'sagittarius',
    name: 'いて座',
    stars: [
      StarPosition(x: 0.3, y: 0.5, unlockDay: 1),
      StarPosition(x: 0.45, y: 0.4, unlockDay: 2),
      StarPosition(x: 0.6, y: 0.35, unlockDay: 3),
      StarPosition(x: 0.5, y: 0.6, unlockDay: 4),
      StarPosition(x: 0.65, y: 0.7, unlockDay: 5),
      StarPosition(x: 0.8, y: 0.5, unlockDay: 6),
    ],
    lines: [
      StarConnection(fromIndex: 0, toIndex: 1),
      StarConnection(fromIndex: 1, toIndex: 2),
      StarConnection(fromIndex: 1, toIndex: 3),
      StarConnection(fromIndex: 3, toIndex: 4),
      StarConnection(fromIndex: 2, toIndex: 5),
    ],
    requiredDays: 6,
  );

  /// 16. やぎ座
  static const Constellation _capricornus = Constellation(
    id: 'capricornus',
    name: 'やぎ座',
    stars: [
      StarPosition(x: 0.3, y: 0.4, unlockDay: 1),
      StarPosition(x: 0.45, y: 0.5, unlockDay: 2),
      StarPosition(x: 0.6, y: 0.45, unlockDay: 3),
      StarPosition(x: 0.5, y: 0.65, unlockDay: 4),
      StarPosition(x: 0.7, y: 0.7, unlockDay: 5),
    ],
    lines: [
      StarConnection(fromIndex: 0, toIndex: 1),
      StarConnection(fromIndex: 1, toIndex: 2),
      StarConnection(fromIndex: 1, toIndex: 3),
      StarConnection(fromIndex: 2, toIndex: 4),
    ],
    requiredDays: 5,
  );

  /// 17. うお座
  static const Constellation _pisces = Constellation(
    id: 'pisces',
    name: 'うお座',
    stars: [
      StarPosition(x: 0.2, y: 0.3, unlockDay: 1),
      StarPosition(x: 0.35, y: 0.4, unlockDay: 2),
      StarPosition(x: 0.5, y: 0.5, unlockDay: 3),
      StarPosition(x: 0.65, y: 0.6, unlockDay: 4),
      StarPosition(x: 0.8, y: 0.7, unlockDay: 5),
      StarPosition(x: 0.8, y: 0.3, unlockDay: 6),
    ],
    lines: [
      StarConnection(fromIndex: 0, toIndex: 1),
      StarConnection(fromIndex: 1, toIndex: 2),
      StarConnection(fromIndex: 2, toIndex: 3),
      StarConnection(fromIndex: 3, toIndex: 4),
      StarConnection(fromIndex: 2, toIndex: 5),
    ],
    requiredDays: 6,
  );

  /// 18. おひつじ座
  static const Constellation _aries = Constellation(
    id: 'aries',
    name: 'おひつじ座',
    stars: [
      StarPosition(x: 0.4, y: 0.4, unlockDay: 1),
      StarPosition(x: 0.55, y: 0.5, unlockDay: 2),
      StarPosition(x: 0.7, y: 0.45, unlockDay: 3),
      StarPosition(x: 0.6, y: 0.7, unlockDay: 4),
    ],
    lines: [
      StarConnection(fromIndex: 0, toIndex: 1),
      StarConnection(fromIndex: 1, toIndex: 2),
      StarConnection(fromIndex: 1, toIndex: 3),
    ],
    requiredDays: 4,
  );

  /// 19. かに座
  static const Constellation _cancer = Constellation(
    id: 'cancer',
    name: 'かに座',
    stars: [
      StarPosition(x: 0.3, y: 0.4, unlockDay: 1),
      StarPosition(x: 0.5, y: 0.5, unlockDay: 2),
      StarPosition(x: 0.7, y: 0.4, unlockDay: 3),
      StarPosition(x: 0.4, y: 0.7, unlockDay: 4),
      StarPosition(x: 0.6, y: 0.7, unlockDay: 5),
    ],
    lines: [
      StarConnection(fromIndex: 0, toIndex: 1),
      StarConnection(fromIndex: 1, toIndex: 2),
      StarConnection(fromIndex: 1, toIndex: 3),
      StarConnection(fromIndex: 1, toIndex: 4),
    ],
    requiredDays: 5,
  );

  /// 20. みなみじゅうじ座（南十字星）
  static const Constellation _southernCross = Constellation(
    id: 'southern_cross',
    name: 'みなみじゅうじ座',
    stars: [
      StarPosition(x: 0.5, y: 0.2, unlockDay: 1),
      StarPosition(x: 0.5, y: 0.65, unlockDay: 2),
      StarPosition(x: 0.3, y: 0.45, unlockDay: 3),
      StarPosition(x: 0.7, y: 0.45, unlockDay: 4),
    ],
    lines: [
      StarConnection(fromIndex: 0, toIndex: 1),
      StarConnection(fromIndex: 2, toIndex: 3),
    ],
    requiredDays: 4,
  );

  /// コレクション情報を取得
  Future<ConstellationCollection> getCollection() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_collectionKey);

    if (json == null) {
      // 初期状態：カシオペア座から開始
      return const ConstellationCollection(
        currentConstellationId: 'cassiopeia',
        completedConstellations: [],
      );
    }

    return ConstellationCollection.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );
  }

  /// コレクション情報を保存
  Future<void> saveCollection(ConstellationCollection collection) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_collectionKey, jsonEncode(collection.toJson()));
  }

  /// 現在チャレンジ中の星座を取得
  Future<Constellation> getCurrentConstellation() async {
    final collection = await getCollection();
    final constellations = getAvailableConstellations();

    return constellations.firstWhere(
      (c) => c.id == collection.currentConstellationId,
      orElse: () => constellations.first,
    );
  }

  /// IDから星座を取得
  Constellation? getConstellationById(String id) {
    final constellations = getAvailableConstellations();
    try {
      return constellations.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 次の星座を取得
  Constellation? getNextConstellation(String currentId) {
    final constellations = getAvailableConstellations();
    final currentIndex = constellations.indexWhere((c) => c.id == currentId);

    if (currentIndex == -1 || currentIndex >= constellations.length - 1) {
      return null; // 最後の星座
    }

    return constellations[currentIndex + 1];
  }

  /// 現在の星座進捗を取得
  Future<ConstellationProgress> getCurrentProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_progressKey);
    final collection = await getCollection();

    if (json == null) {
      // 初期状態
      return ConstellationProgress(
        constellationId: collection.currentConstellationId,
        currentStreak: 0,
        unlockedStars: [],
        isCompleted: false,
      );
    }

    final progress = ConstellationProgress.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );

    // 進捗の星座IDとコレクションの現在星座IDが一致しているか確認
    if (progress.constellationId != collection.currentConstellationId) {
      // 不一致の場合は新しい星座の進捗を返す
      return ConstellationProgress(
        constellationId: collection.currentConstellationId,
        currentStreak: 0,
        unlockedStars: [],
        isCompleted: false,
      );
    }

    return progress;
  }

  /// 進捗を保存
  Future<void> saveProgress(ConstellationProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey, jsonEncode(progress.toJson()));
  }

  /// その日に予定されている全ての習慣が完了しているかチェック
  bool _isAllHabitsCompletedOnDate(List<Habit> habits, DateTime date) {
    if (habits.isEmpty) return false;

    // その日に予定されている習慣のみをフィルタ
    final scheduledHabits = habits.where((habit) {
      return habit.isScheduledOn(date);
    }).toList();

    // 予定されている習慣が1つもない場合はfalse
    if (scheduledHabits.isEmpty) return false;

    // 全ての予定された習慣が完了しているかチェック
    return scheduledHabits.every((habit) => habit.isCompletedOnDate(date));
  }

  /// 全習慣達成の連続日数を計算
  /// 「その日に予定されている全ての習慣を完了した日」が何日連続しているか
  int calculateAllHabitsStreak(List<Habit> habits) {
    if (habits.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int streak = 0;

    // 今日から過去に遡ってチェック
    for (int i = 0; i < 365; i++) {
      final checkDate = today.subtract(Duration(days: i));

      if (_isAllHabitsCompletedOnDate(habits, checkDate)) {
        streak++;
      } else {
        // 連続が途切れた
        break;
      }
    }

    return streak;
  }

  /// 進捗を更新（習慣完了時に呼ばれる）
  Future<ConstellationProgress> updateProgress(List<Habit> habits) async {
    final currentProgress = await getCurrentProgress();

    // デバッグモードチェック
    final prefs = await SharedPreferences.getInstance();
    final debugMode = prefs.getBool(_debugModeKey) ?? false;

    // デバッグモードの場合は手動設定値を使用、それ以外は実際の習慣から計算
    final streak = debugMode
        ? (prefs.getInt(_debugStreakKey) ?? 0)
        : calculateAllHabitsStreak(habits);

    final constellation = await getCurrentConstellation();

    print('🌟 星座進捗更新: ${constellation.name}, 全習慣達成連続日数=$streak, 習慣数=${habits.length}');
    for (final habit in habits) {
      print('  - ${habit.title}: 個別${habit.currentStreak}日連続');
    }

    // 解放済みの星を判定
    final unlockedStars = <int>[];
    for (int i = 0; i < constellation.stars.length; i++) {
      if (streak >= constellation.stars[i].unlockDay) {
        unlockedStars.add(i);
      }
    }

    print('🌟 解放済みの星: ${unlockedStars.length}/${constellation.stars.length}');

    // 星座完成判定
    final isCompleted = streak >= constellation.requiredDays;

    // 完成日時の処理
    final DateTime? completedAt;
    if (isCompleted && !currentProgress.isCompleted) {
      // 初めて完成した
      completedAt = DateTime.now();
      print('🎉 星座完成！${constellation.name}');

      // コレクションに追加
      final collection = await getCollection();
      final newCompletedList = List<CompletedConstellation>.from(
        collection.completedConstellations,
      )..add(CompletedConstellation(
          constellationId: constellation.id,
          completedAt: completedAt,
        ));

      // 次の星座へ移行
      final nextConstellation = getNextConstellation(constellation.id);
      if (nextConstellation != null) {
        print('🌟 次の星座へ移行: ${nextConstellation.name}');
        final newCollection = collection.copyWith(
          currentConstellationId: nextConstellation.id,
          completedConstellations: newCompletedList,
        );
        await saveCollection(newCollection);

        // 新しい星座の進捗を作成
        final newProgress = ConstellationProgress(
          constellationId: nextConstellation.id,
          currentStreak: 0,
          unlockedStars: [],
          isCompleted: false,
          completedAt: null,
          celebrationShown: false,
        );
        await saveProgress(newProgress);

        // 完成した星座の進捗を返す（お祝いアニメーション表示のため）
        return ConstellationProgress(
          constellationId: constellation.id,
          currentStreak: streak,
          unlockedStars: unlockedStars,
          isCompleted: true,
          completedAt: completedAt,
          celebrationShown: false, // まだ表示していない
        );
      } else {
        print('🎊 全ての星座を完成しました！');
        final newCollection = collection.copyWith(
          completedConstellations: newCompletedList,
        );
        await saveCollection(newCollection);
      }
    } else if (isCompleted && currentProgress.isCompleted) {
      // 既に完成している（継続中）
      completedAt = currentProgress.completedAt;
    } else {
      // 未完成
      completedAt = null;
    }

    // お祝いフラグの処理
    final celebrationShown = streak == 0
        ? false
        : currentProgress.celebrationShown;

    print('🌟 お祝いフラグ: $celebrationShown, 完成日時: $completedAt');

    final newProgress = ConstellationProgress(
      constellationId: constellation.id,
      currentStreak: streak,
      unlockedStars: unlockedStars,
      isCompleted: isCompleted,
      completedAt: completedAt,
      celebrationShown: celebrationShown,
    );

    await saveProgress(newProgress);
    return newProgress;
  }

  /// 新しく星が解放されたかチェック
  bool hasNewStarUnlocked(
    ConstellationProgress oldProgress,
    ConstellationProgress newProgress,
  ) {
    return newProgress.unlockedStars.length > oldProgress.unlockedStars.length;
  }

  /// 星座が完成したかチェック
  bool hasJustCompleted(
    ConstellationProgress oldProgress,
    ConstellationProgress newProgress,
  ) {
    return !oldProgress.isCompleted && newProgress.isCompleted;
  }

  /// お祝いを表示すべきかチェック（完成済みだがまだアニメーション未表示）
  bool shouldShowCelebration(ConstellationProgress progress) {
    return progress.isCompleted && !progress.celebrationShown;
  }

  /// お祝い表示済みとしてマーク
  Future<void> markCelebrationShown(ConstellationProgress progress) async {
    final updatedProgress = progress.copyWith(celebrationShown: true);
    await saveProgress(updatedProgress);
  }

  // ========== デバッグ用メソッド ==========

  /// [デバッグ専用] デバッグモードが有効かチェック
  Future<bool> isDebugModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_debugModeKey) ?? false;
  }

  /// [デバッグ専用] 連続日数を強制的に設定
  Future<void> debugSetStreak(int streak, {bool autoAdvance = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final currentProgress = await getCurrentProgress();
    final constellation = await getCurrentConstellation();

    // デバッグモードをONにして、設定値を保存
    await prefs.setBool(_debugModeKey, true);
    await prefs.setInt(_debugStreakKey, streak);

    // 解放済みの星を再計算
    final unlockedStars = <int>[];
    for (int i = 0; i < constellation.stars.length; i++) {
      if (streak >= constellation.stars[i].unlockDay) {
        unlockedStars.add(i);
      }
    }

    // 完成判定
    final isCompleted = streak >= constellation.requiredDays;
    final completedAt = isCompleted ? DateTime.now() : null;

    // 完成した場合、次の星座への移行処理（autoAdvanceがtrueの時のみ）
    if (isCompleted && !currentProgress.isCompleted && autoAdvance) {
      print('🎉 [DEBUG] 星座完成！${constellation.name}');

      // コレクションに追加
      final collection = await getCollection();
      final newCompletedList = List<CompletedConstellation>.from(
        collection.completedConstellations,
      )..add(CompletedConstellation(
          constellationId: constellation.id,
          completedAt: completedAt!,
        ));

      // 次の星座へ移行
      final nextConstellation = getNextConstellation(constellation.id);
      if (nextConstellation != null) {
        print('🌟 [DEBUG] 次の星座へ移行: ${nextConstellation.name}');
        final newCollection = collection.copyWith(
          currentConstellationId: nextConstellation.id,
          completedConstellations: newCompletedList,
        );
        await saveCollection(newCollection);

        // 新しい星座の進捗を作成
        final newProgress = ConstellationProgress(
          constellationId: nextConstellation.id,
          currentStreak: 0,
          unlockedStars: [],
          isCompleted: false,
          completedAt: null,
          celebrationShown: false,
        );
        await saveProgress(newProgress);

        // デバッグモードのstreak値もリセット
        await prefs.setInt(_debugStreakKey, 0);
        print('🐛 [DEBUG] 次の星座に移行完了');
        return;
      } else {
        print('🎊 [DEBUG] 全ての星座を完成しました！');
        final newCollection = collection.copyWith(
          completedConstellations: newCompletedList,
        );
        await saveCollection(newCollection);
      }
    }

    final newProgress = currentProgress.copyWith(
      currentStreak: streak,
      unlockedStars: unlockedStars,
      isCompleted: isCompleted,
      completedAt: completedAt,
      celebrationShown: false, // デバッグ時はアニメーション再表示可能に
    );

    await saveProgress(newProgress);
    print('🐛 [DEBUG] デバッグモードON: 連続日数を$streakに設定しました');
  }

  /// [デバッグ専用] デバッグモードを解除して通常モードに戻す
  Future<void> debugDisableDebugMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debugModeKey, false);
    await prefs.remove(_debugStreakKey);
    print('🐛 [DEBUG] デバッグモードOFF: 通常モードに戻しました');
  }

  /// [デバッグ専用] 全ての進捗をリセット
  Future<void> debugResetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_progressKey);
    await prefs.remove(_collectionKey);
    await prefs.remove(_debugModeKey);
    await prefs.remove(_debugStreakKey);
    print('🐛 [DEBUG] 全ての進捗をリセットしました');
  }

  /// [デバッグ専用] 現在の星座を強制的に完成させて次へ
  Future<void> debugCompleteCurrentConstellation() async {
    final constellation = await getCurrentConstellation();
    await debugSetStreak(constellation.requiredDays, autoAdvance: true);
    print('🐛 [DEBUG] ${constellation.name}を完成させて次の星座へ移行');
  }

  /// [デバッグ専用] 指定した星座にジャンプ
  Future<void> debugJumpToConstellation(String constellationId) async {
    final collection = await getCollection();
    final newCollection = collection.copyWith(
      currentConstellationId: constellationId,
    );
    await saveCollection(newCollection);

    // 進捗をリセット
    final newProgress = ConstellationProgress(
      constellationId: constellationId,
      currentStreak: 0,
      unlockedStars: [],
      isCompleted: false,
    );
    await saveProgress(newProgress);
    print('🐛 [DEBUG] $constellationIdにジャンプしました');
  }
}
