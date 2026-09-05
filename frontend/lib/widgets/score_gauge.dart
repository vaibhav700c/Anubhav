import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Circular score gauge displaying large numeral and "Overall Fluency Score"
class ScoreGauge extends StatelessWidget {
  final num score;
  final double size;
  final String label;
  final bool animate;
  final Color? ringColor;

  const ScoreGauge({
    super.key,
    required this.score,
    this.size = 180,
    this.label = 'Overall Fluency Score',
    this.animate = true,
    this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: score.toDouble()),
      duration: Duration(milliseconds: animate ? 900 : 0),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final progress = (value / 100.0).clamp(0.0, 1.0);
        final color = ringColor ?? (value >= 65 ? AnubhavColors.darkGreen : scoreColor(value));

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
                  trackColor: AnubhavColors.darkGreen.withValues(alpha: 0.12),
                ),
              ),
              // Large numeral + label sitting comfortably inside the ring
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size * 0.16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${value.round()}',
                      style: AnubhavTextStyles.displayScore.copyWith(
                        fontSize: size * 0.25,
                        height: 1.0,
                        color: AnubhavColors.textPrimary,
                      ),
                    ),
                    if (label.isNotEmpty) ...[
                      SizedBox(height: size * 0.02),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        softWrap: true,
                        style: AnubhavTextStyles.bodySmall.copyWith(
                          fontSize: (size * 0.058).clamp(8.5, 11.5),
                          fontWeight: FontWeight.w700,
                          color: AnubhavColors.textSecondary,
                          height: 1.15,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ],
                ),
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
