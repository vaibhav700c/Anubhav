import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Circular score gauge displaying large numeral and "Overall Fluency Score"
class ScoreGauge extends StatelessWidget {
  final num score;
  final double size;
  final String label;
  final bool animate;

  const ScoreGauge({
    super.key,
    required this.score,
    this.size = 180,
    this.label = 'Overall Fluency Score',
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: score.toDouble()),
      duration: Duration(milliseconds: animate ? 900 : 0),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final progress = (value / 100.0).clamp(0.0, 1.0);
        final color = scoreColor(value);

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Circular progress track
              CustomPaint(
                size: Size(size, size),
                painter: _GaugePainter(
                  progress: progress,
                  accentColor: color,
                  trackColor: AnubhavColors.cardBorderSubtle,
                ),
              ),
              // Large numeral + label
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${value.round()}',
                    style: AnubhavTextStyles.displayScore.copyWith(
                      fontSize: size * 0.32,
                      color: AnubhavColors.textPrimary,
                    ),
                  ),
                  if (label.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: AnubhavTextStyles.bodySmall.copyWith(
                          fontSize: size * 0.075,
                          fontWeight: FontWeight.w600,
                          color: AnubhavColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final Color trackColor;

  _GaugePainter({
    required this.progress,
    required this.accentColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.085;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track (full circle or 270 arc)
    final bgPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2,
      false,
      bgPaint,
    );

    // Active progress arc
    final fgPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.accentColor != accentColor;
  }
}
