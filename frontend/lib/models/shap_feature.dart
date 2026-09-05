/// A single SHAP / XAI feature contribution entry.
///
/// Contract field names (match exactly):
///   feature       – feature name key (e.g. "filler_words")
///   contribution  – signed float; negative = hurts score, positive = helps
///   explanation   – plain-language string shown below the bar
class ShapFeature {
  final String feature;
  final double contribution;
  final String explanation;

  const ShapFeature({
    required this.feature,
    required this.contribution,
    required this.explanation,
  });

  factory ShapFeature.fromJson(Map<String, dynamic> json) => ShapFeature(
        feature: (json['feature'] as String?) ?? 'unknown',
        contribution: (json['contribution'] as num?)?.toDouble() ?? 0.0,
        explanation:
            (json['explanation'] as String?) ?? 'No explanation available.',
      );

  Map<String, dynamic> toJson() => {
        'feature': feature,
        'contribution': contribution,
        'explanation': explanation,
      };

  /// Display-friendly label: "filler_words" -> "Filler Words".
  String get displayName {
    return feature
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}
