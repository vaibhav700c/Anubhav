import 'package:flutter/material.dart';
import '../models/shap_feature.dart';
import '../theme/app_theme.dart';

/// Renders SHAP factor rows matching the approved mockup design:
/// Floating card with factor name + signed delta, horizontal colored bar (green = helped, orange-red = hurt),
/// and plain-language explanation with expand/collapse capability.
class ShapBarChart extends StatefulWidget {
  final List<ShapFeature> features;

  const ShapBarChart({super.key, required this.features});

  @override
  State<ShapBarChart> createState() => _ShapBarChartState();
}

class _ShapBarChartState extends State<ShapBarChart> {
  final Set<int> _expandedIndices = {};

  @override
  Widget build(BuildContext context) {
    if (widget.features.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AnubhavColors.cardBorder),
        ),
        child: Center(
          child: Text(
            'No explanation factors available yet.',
            style: AnubhavTextStyles.bodyMedium,
          ),
        ),
      );
    }

    return Column(
      children: widget.features.asMap().entries.map((entry) {
        final idx = entry.key;
        final feat = entry.value;
        final isPositive = feat.contribution >= 0;
        final isExpanded = _expandedIndices.contains(idx);

        // Normalize bar width relative to max contribution (capped at 15 pts)
        final barRatio = (feat.contribution.abs() / 15.0).clamp(0.1, 1.0);
        // Positive = dark green (same as status ring), Negative = dark orange (same as font)
        final barColor = isPositive ? AnubhavColors.darkGreen : AnubhavColors.orange;

        final signedDelta = isPositive
            ? '+${feat.contribution.toStringAsFixed(1)}'
            : feat.contribution.toStringAsFixed(1);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AnubhavColors.cardBorder,
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x081F5B5B),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedIndices.remove(idx);
                  } else {
                    _expandedIndices.add(idx);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Factor title + Signed delta + Expand Chevron
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            feat.displayName,
                            style: AnubhavTextStyles.titleMedium.copyWith(
                              color: AnubhavColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPositive
                                ? AnubhavColors.darkGreen.withValues(alpha: 0.12)
                                : AnubhavColors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            signedDelta,
                            style: AnubhavTextStyles.labelMedium.copyWith(
                              color: barColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: AnubhavColors.textTertiary,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Horizontal colored progress bar (green = helped, orange-red = hurt)
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AnubhavColors.teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: barRatio,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // One-line plain-language explanation
                    Text(
                      feat.explanation,
                      style: AnubhavTextStyles.bodyMedium.copyWith(
                        color: AnubhavColors.textSecondary,
                        height: 1.35,
                      ),
                      maxLines: isExpanded ? 5 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
