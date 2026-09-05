import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Colored pill badge showing the current emotion label.
///
/// Uses the shared [emotionColors] map so color coding is identical
/// across the Live Dashboard, Session Detail timeline, and history cards.
class EmotionBadge extends StatelessWidget {
  final String emotion;
  final double fontSize;

  const EmotionBadge({super.key, required this.emotion, this.fontSize = 13});

  @override
  Widget build(BuildContext context) {
    final color = emotionColor(emotion);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
      child: Container(
        key: ValueKey(emotion),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.6), blurRadius: 6)
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              emotion[0].toUpperCase() + emotion.substring(1),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: color,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
