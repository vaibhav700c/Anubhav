/// A single data point on the emotion timeline.
///
/// Contract field names (match exactly):
///   time        – seconds from session start (double)
///   emotion     – emotion label string (e.g. "confident")
///   intensity   – 0.0–1.0 confidence/intensity score
class EmotionPoint {
  final double time;
  final String emotion;
  final double intensity;

  const EmotionPoint({
    required this.time,
    required this.emotion,
    required this.intensity,
  });

  factory EmotionPoint.fromJson(Map<String, dynamic> json) => EmotionPoint(
        time: (json['time'] as num?)?.toDouble() ?? 0.0,
        emotion: (json['emotion'] as String?) ?? 'neutral',
        intensity: (json['intensity'] as num?)?.toDouble() ?? 0.5,
      );

  Map<String, dynamic> toJson() => {
        'time': time,
        'emotion': emotion,
        'intensity': intensity,
      };
}
