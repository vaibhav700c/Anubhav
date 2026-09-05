import 'package:flutter/material.dart';

import '../models/shap_feature.dart';
import '../theme/app_theme.dart';

/// Horizontal bar chart of SHAP feature contributions — the XAI card.
///
/// Positive contributions are teal/green; negative contributions are red.
/// Each bar has the explanation text below it (not a tooltip — always visible).
class ShapBarChart extends StatelessWidget {
  final List<ShapFeature> features;

  const ShapBarChart({super.key, required this.features});

  @override
  Widget build(BuildContext context) {
    if (features.isEmpty) {
      return const Center(child: Text('No XAI data available.'));
    }

    // Sort by absolute contribution magnitude descending
    final sorted = [...features]
      ..sort((a, b) => b.contribution.abs().compareTo(a.contribution.abs()));
    final top = sorted.take(5).toList();
    final maxAbs = top.map((f) => f.contribution.abs()).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: top.map((f) => _FeatureBar(feature: f, maxAbs: maxAbs)).toList(),
    );
  }
}

class _FeatureBar extends StatelessWidget {
  final ShapFeature feature;
  final double maxAbs;

  const _FeatureBar({required this.feature, required this.maxAbs});

  @override
  Widget build(BuildContext context) {
    final isPositive = feature.contribution >= 0;
    final color = isPositive ? AnubhavColors.success : AnubhavColors.error;
    final fraction = (feature.contribution.abs() / maxAbs).clamp(0.0, 1.0);
    final sign = isPositive ? '+' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(feature.displayName, style: AnubhavTextStyles.titleMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$sign${feature.contribution.toStringAsFixed(1)} pts',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (ctx, value, _) => Stack(
                children: [
                  Container(
                    height: 10,
                    width: double.infinity,
                    color: AnubhavColors.surfaceVariant,
                  ),
                  FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.6), color],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Plain-language explanation
          Text(
            feature.explanation,
            style: AnubhavTextStyles.bodySmall
                .copyWith(color: AnubhavColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
