import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/badge.dart';

/// 流れ星アニメーションを表示するオーバーレイ
class ShootingStarAnimation extends StatefulWidget {
  final VoidCallback onComplete;
  final AchievementBadge badge;

  const ShootingStarAnimation({
    super.key,
    required this.onComplete,
    required this.badge,
  });

  @override
  State<ShootingStarAnimation> createState() => _ShootingStarAnimationState();

  /// 流れ星アニメーションを表示
  static void show(BuildContext context, AchievementBadge badge) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54, // 半透明の黒背景で見やすくする
      builder: (context) => ShootingStarAnimation(
        onComplete: () => Navigator.of(context).pop(),
        badge: badge,
      ),
    );
  }
}

class _ShootingStarAnimationState extends State<ShootingStarAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late int _starCount;
  late int _duration;
  late int _waveCount; // 流れ星が流れる回数
  int _currentWave = 0;

  @override
  void initState() {
    super.initState();

    // 全バッジで統一（ダイヤモンドの演出）
    // TODO: 将来的にバッジごとに差をつけた演出を検討
    // 課題: 複数回繰り返す演出はもっさりしてスピード感がなく豪華に感じない
    // 検討事項: 同時に複数の流れ星を流す、色を変える、サイズを変えるなど
    _starCount = 15;
    _duration = 1800;
    _waveCount = 1;

    _controller = AnimationController(
      duration: Duration(milliseconds: _duration),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn, // より速く流れる感じに
    );

    _startNextWave();
  }

  /// 次のウェーブを開始
  void _startNextWave() {
    if (_currentWave < _waveCount) {
      _currentWave++;
      _controller.forward(from: 0).then((_) {
        if (_currentWave < _waveCount) {
          // まだ次のウェーブがある場合は少し待ってから次へ
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              setState(() {
                // 次のウェーブの準備
              });
              _startNextWave();
            }
          });
        } else {
          // 全てのウェーブが完了したら閉じる
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              widget.onComplete();
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // フラッシュエフェクト（画面全体）
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final flashOpacity = _animation.value > 0.3 && _animation.value < 0.5
                  ? (0.5 - _animation.value) * 5 // 0.3-0.5の間で点滅
                  : 0.0;
              return Container(
                color: Colors.white.withOpacity(flashOpacity * 0.3),
              );
            },
          ),
          // バッジの価値に応じた数の流れ星を配置
          ..._buildShootingStars(),
          // キラキラパーティクル
          ..._buildSparkles(),
          // 光の波紋エフェクト
          Center(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                if (_animation.value < 0.4) return const SizedBox.shrink();

                final rippleProgress = (_animation.value - 0.4) / 0.6;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // 外側の波紋
                    Container(
                      width: 300 * rippleProgress,
                      height: 300 * rippleProgress,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.badge.color.withOpacity((1 - rippleProgress) * 0.5),
                          width: 4,
                        ),
                      ),
                    ),
                    // 中間の波紋
                    Container(
                      width: 200 * rippleProgress,
                      height: 200 * rippleProgress,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.badge.color.withOpacity((1 - rippleProgress) * 0.7),
                          width: 3,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // バッジアイコン表示（回転と拡大）
          Center(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final badgeProgress = _animation.value < 0.4 ? 0.0 : (_animation.value - 0.4) / 0.6;
                final scale = badgeProgress < 0.5
                    ? badgeProgress * 2.4  // 0→1.2に拡大
                    : 1.2 - (badgeProgress - 0.5) * 0.4; // 1.2→1.0に縮小
                final rotation = badgeProgress * math.pi * 2; // 2回転

                return Opacity(
                  opacity: badgeProgress,
                  child: Transform.rotate(
                    angle: rotation,
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              widget.badge.color.withOpacity(1.0),
                              widget.badge.color.withOpacity(0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.badge.color.withOpacity(0.9),
                              blurRadius: 40,
                              spreadRadius: 15,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Transform.rotate(
                          angle: -rotation, // アイコンは回転させない
                          child: Icon(
                            widget.badge.icon,
                            color: Colors.white,
                            size: 70,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// キラキラパーティクルを生成
  List<Widget> _buildSparkles() {
    final sparkles = <Widget>[];
    final random = math.Random(42); // 固定シードで再現性を持たせる

    for (int i = 0; i < 20; i++) {
      sparkles.add(
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final startDelay = i * 0.05;
            final progress = math.max(0.0, (_animation.value - startDelay) / (1.0 - startDelay));

            if (progress == 0) return const SizedBox.shrink();

            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;

            // 画面中央から放射状に広がる
            final angle = (i / 20) * 2 * math.pi;
            final distance = progress * (screenWidth * 0.5);
            final left = screenWidth / 2 + math.cos(angle) * distance - 10;
            final top = screenHeight / 2 + math.sin(angle) * distance - 10;

            final opacity = progress < 0.5 ? progress * 2 : (1 - progress) * 2;
            final size = 20 * (1 - progress);

            return Positioned(
              left: left,
              top: top,
              child: Opacity(
                opacity: opacity,
                child: Transform.rotate(
                  angle: progress * math.pi * 4,
                  child: Icon(
                    Icons.star,
                    color: widget.badge.color,
                    size: size,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return sparkles;
  }

  /// バッジの価値に応じた流れ星のリストを生成
  List<Widget> _buildShootingStars() {
    final stars = <Widget>[];
    final delayInterval = _duration ~/ (_starCount + 1);

    for (int i = 0; i < _starCount; i++) {
      stars.add(
        _buildShootingStar(
          startOffset: i * 0.05, // 開始位置を少しずつずらす
          delay: i * delayInterval,
        ),
      );
    }

    return stars;
  }

  Widget _buildShootingStar({
    required double startOffset,
    required int delay,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // 遅延を考慮したアニメーション進行度
        final delayedProgress = math.max(
          0.0,
          math.min(1.0, (_animation.value * _duration - delay) / (_duration - delay)),
        );

        if (delayedProgress == 0) return const SizedBox.shrink();

        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        // 左上（天空）から右下へ斜めに流れる
        final startX = -200.0; // 画面左端より外側からスタート
        final endX = screenWidth + 100; // 画面右端より外側まで
        final startY = screenHeight * (-0.05 + startOffset); // 画面外上部から開始
        final endY = screenHeight * (0.4 + startOffset * 0.4); // 画面中央付近へ移動

        final left = startX + (endX - startX) * delayedProgress;
        final top = startY + (endY - startY) * delayedProgress;

        // フェードイン・フェードアウト（高速で）
        final opacity = delayedProgress < 0.15
            ? delayedProgress * 6.67 // 最初の15%でフェードイン
            : delayedProgress > 0.85
                ? (1.0 - delayedProgress) * 6.67 // 最後の15%でフェードアウト
                : 1.0;

        return Positioned(
          left: left,
          top: top,
          child: Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: math.pi / 6, // 右下向きに30度傾ける
              child: CustomPaint(
                size: const Size(200, 40), // 横長サイズで長い尾を表現
                painter: _ShootingStarPainter(),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 流れ星を描画するカスタムペインター
class _ShootingStarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 星の頭は右側、尾は左側に伸びる（水平方向）
    final starCenter = Offset(size.width * 0.9, size.height * 0.5);

    // 外側の尾（淡い青白）- 最も長い
    final outerTailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          Colors.white.withOpacity(0.8),
          Colors.blue[100]!.withOpacity(0.6),
          Colors.blue[200]!.withOpacity(0.3),
          Colors.blue[300]!.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // 外側の尾の形状（流線型で横に長い）
    final outerTailPath = Path()
      ..moveTo(starCenter.dx, starCenter.dy - 8)
      ..quadraticBezierTo(
        size.width * 0.5, starCenter.dy - 12,
        size.width * 0.1, starCenter.dy - 10,
      )
      ..lineTo(0, starCenter.dy)
      ..lineTo(size.width * 0.1, starCenter.dy + 10)
      ..quadraticBezierTo(
        size.width * 0.5, starCenter.dy + 12,
        starCenter.dx, starCenter.dy + 8,
      )
      ..close();

    canvas.drawPath(outerTailPath, outerTailPaint);

    // 中間の尾（明るい白）
    final midTailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          Colors.white.withOpacity(1.0),
          Colors.white.withOpacity(0.9),
          Colors.white.withOpacity(0.5),
          Colors.white.withOpacity(0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.15, 0.4, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final midTailPath = Path()
      ..moveTo(starCenter.dx, starCenter.dy - 5)
      ..quadraticBezierTo(
        size.width * 0.55, starCenter.dy - 7,
        size.width * 0.2, starCenter.dy - 5,
      )
      ..lineTo(size.width * 0.05, starCenter.dy)
      ..lineTo(size.width * 0.2, starCenter.dy + 5)
      ..quadraticBezierTo(
        size.width * 0.55, starCenter.dy + 7,
        starCenter.dx, starCenter.dy + 5,
      )
      ..close();

    canvas.drawPath(midTailPath, midTailPaint);

    // 内側の最も明るいコア部分
    final coreTailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          Colors.white,
          Colors.white.withOpacity(0.95),
          Colors.white.withOpacity(0.7),
          Colors.white.withOpacity(0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.1, 0.3, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final coreTailPath = Path()
      ..moveTo(starCenter.dx, starCenter.dy - 2.5)
      ..quadraticBezierTo(
        size.width * 0.6, starCenter.dy - 3,
        size.width * 0.3, starCenter.dy - 2,
      )
      ..lineTo(size.width * 0.15, starCenter.dy)
      ..lineTo(size.width * 0.3, starCenter.dy + 2)
      ..quadraticBezierTo(
        size.width * 0.6, starCenter.dy + 3,
        starCenter.dx, starCenter.dy + 2.5,
      )
      ..close();

    canvas.drawPath(coreTailPath, coreTailPaint);

    // 星の頭部分のグロー（大きい外側）
    final outerGlowPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(starCenter, 15, outerGlowPaint);

    // 中間のグロー
    final midGlowPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(starCenter, 10, midGlowPaint);

    // 星の本体（明るい白）
    final starPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(starCenter, 6, starPaint);

    // 内側の極めて明るい部分
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(starCenter, 4, innerPaint);

    // 中心の最も明るい点（ほんのり黄色がかった白）
    final corePaint = Paint()
      ..color = Colors.yellow[50]!
      ..style = PaintingStyle.fill;
    canvas.drawCircle(starCenter, 2, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
