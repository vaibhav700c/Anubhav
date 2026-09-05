import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Emotion badge pill displaying the unified label
class EmotionBadge extends StatelessWidget {
  final String emotion;
  final double fontSize;

  const EmotionBadge({
    super.key,
    required this.emotion,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    final meta = getEmotionMeta(emotion);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: meta.softBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: meta.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            meta.label,
            style: AnubhavTextStyles.labelMedium.copyWith(
              color: meta.color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
