import 'dart:math';
import 'package:flutter/material.dart';
import '../models/constellation.dart';

/// 星座を表示するウィジェット
class ConstellationWidget extends StatefulWidget {
  final Constellation constellation;
  final ConstellationProgress progress;
  final double width;
  final double height;

  const ConstellationWidget({
    super.key,
    required this.constellation,
    required this.progress,
    this.width = 200,
    this.height = 150,
  });

  @override
  State<ConstellationWidget> createState() => _ConstellationWidgetState();
}

class _ConstellationWidgetState extends State<ConstellationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _twinkleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _twinkleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A1128),
            Color(0xFF1A2040),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // 星座名
          Positioned(
            top: 8,
            left: 8,
            child: Text(
              widget.constellation.name,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // 進捗表示
          Positioned(
            top: 8,
            right: 8,
            child: Text(
              '${widget.progress.currentStreak}/${widget.constellation.requiredDays}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // 星座の描画
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              child: AnimatedBuilder(
                animation: _twinkleAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ConstellationPainter(
                      constellation: widget.constellation,
                      progress: widget.progress,
                      twinkleOpacity: _twinkleAnimation.value,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 星座を描画するCustomPainter
class ConstellationPainter extends CustomPainter {
  final Constellation constellation;
  final ConstellationProgress progress;
  final double twinkleOpacity;

  ConstellationPainter({
    required this.constellation,
    required this.progress,
    required this.twinkleOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 線を描画（星座が完成している場合のみ）
    if (progress.isCompleted) {
      _drawLines(canvas, size);
    }

    // 星を描画
    _drawStars(canvas, size);
  }

  void _drawLines(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final line in constellation.lines) {
      final fromStar = constellation.stars[line.fromIndex];
      final toStar = constellation.stars[line.toIndex];

      final from = Offset(fromStar.x * size.width, fromStar.y * size.height);
      final to = Offset(toStar.x * size.width, toStar.y * size.height);

      canvas.drawLine(from, to, linePaint);
    }
  }

  void _drawStars(Canvas canvas, Size size) {
    for (int i = 0; i < constellation.stars.length; i++) {
      final star = constellation.stars[i];
      final isUnlocked = progress.unlockedStars.contains(i);

      if (!isUnlocked) {
        // 未解放の星は薄く表示
        _drawStar(
          canvas,
          Offset(star.x * size.width, star.y * size.height),
          isUnlocked: false,
        );
      } else {
        // 解放済みの星は明るく表示
        _drawStar(
          canvas,
          Offset(star.x * size.width, star.y * size.height),
          isUnlocked: true,
        );
      }
    }
  }

  void _drawStar(Canvas canvas, Offset position, {required bool isUnlocked}) {
    if (isUnlocked) {
      // グロー効果
      final glowPaint = Paint()
        ..color = Colors.yellow.withOpacity(0.3 * twinkleOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      final glowPath = _createStarPath(position, 15, 7);
      canvas.drawPath(glowPath, glowPaint);

      // 星本体
      final starPaint = Paint()
        ..color = Colors.white.withOpacity(twinkleOpacity)
        ..style = PaintingStyle.fill;
      final starPath = _createStarPath(position, 9, 3.5);
      canvas.drawPath(starPath, starPaint);

      // 内側の明るい部分
      final innerPaint = Paint()
        ..color = Colors.yellow.withOpacity(0.8 * twinkleOpacity)
        ..style = PaintingStyle.fill;
      final innerPath = _createStarPath(position, 4.5, 1.8);
      canvas.drawPath(innerPath, innerPaint);
    } else {
      // 未解放の星（薄いグレー）
      final lockPaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      final lockPath = _createStarPath(position, 6, 2.4);
      canvas.drawPath(lockPath, lockPaint);
    }
  }

  /// 5角星のパスを生成
  Path _createStarPath(Offset center, double outerRadius, double innerRadius) {
    final path = Path();
    const points = 5;
    const angle = 3.14159 * 2 / points;
    const startAngle = -3.14159 / 2; // 上から開始

    for (int i = 0; i < points * 2; i++) {
      final currentAngle = startAngle + angle * i / 2;
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = center.dx + radius * cos(currentAngle);
      final y = center.dy + radius * sin(currentAngle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(ConstellationPainter oldDelegate) {
    return oldDelegate.progress.unlockedStars.length !=
            progress.unlockedStars.length ||
        oldDelegate.progress.isCompleted != progress.isCompleted ||
        oldDelegate.twinkleOpacity != twinkleOpacity;
  }
}
