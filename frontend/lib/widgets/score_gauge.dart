import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Radial arc gauge — the most visually dominant element on the Live Dashboard.
///
/// Score animates smoothly via [TweenAnimationBuilder]. The arc fills
/// clockwise from the bottom-left, colored by score band.
class ScoreGauge extends StatelessWidget {
  final double score;
  final double size;

  const ScoreGauge({super.key, required this.score, this.size = 220});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score.clamp(0, 100)),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animatedScore, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _GaugePainter(animatedScore),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    animatedScore.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: size * 0.30,
                      fontWeight: FontWeight.w800,
                      color: scoreColor(animatedScore),
                      letterSpacing: -2,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  Text(
                    'SCORE',
                    style: TextStyle(
                      fontSize: size * 0.075,
                      fontWeight: FontWeight.w600,
                      color: AnubhavColors.textTertiary,
                      letterSpacing: 3,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  _GaugePainter(this.score);

  static const _startAngle = 140.0 * pi / 180;
  static const _sweepTotal = 260.0 * pi / 180;
  static const _strokeWidth = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - _strokeWidth * 2) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track arc (background)
    canvas.drawArc(
      rect,
      _startAngle,
      _sweepTotal,
      false,
      Paint()
        ..color = AnubhavColors.surfaceVariant
        ..strokeWidth = _strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Value arc
    final sweep = _sweepTotal * (score / 100);
    final gradient = SweepGradient(
      startAngle: _startAngle,
      endAngle: _startAngle + _sweepTotal,
      colors: [scoreColor(score).withOpacity(0.6), scoreColor(score)],
      tileMode: TileMode.clamp,
    );
    canvas.drawArc(
      rect,
      _startAngle,
      sweep,
      false,
      Paint()
        ..shader = gradient.createShader(rect)
        ..strokeWidth = _strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Glow dot at tip
    if (score > 0) {
      final tipAngle = _startAngle + sweep;
      final tipX = center.dx + radius * cos(tipAngle);
      final tipY = center.dy + radius * sin(tipAngle);
      canvas.drawCircle(
        Offset(tipX, tipY),
        _strokeWidth / 2 + 2,
        Paint()
          ..color = scoreColor(score)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        Offset(tipX, tipY),
        _strokeWidth / 2,
        Paint()..color = scoreColor(score),
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.score != score;
}
