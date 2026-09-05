import 'emotion_point.dart';
import 'shap_feature.dart';

/// Full session report fetched from GET /session/{id}.
///
/// Contract field names (match exactly):
///   session_id       – unique identifier
///   date             – ISO 8601 datetime
///   overall_score    – 0–100
///   emotion_timeline – List of emotion data points
///   shap_breakdown   – List of SHAP feature contributions
///   transcript       – full transcript string (may be null mid-session)
class SessionDetail {
  final String sessionId;
  final DateTime date;
  final int overallScore;
  final List<EmotionPoint> emotionTimeline;
  final List<ShapFeature> shapBreakdown;
  final String? transcript;
  final String? coachingText;

  const SessionDetail({
    required this.sessionId,
    required this.date,
    required this.overallScore,
    required this.emotionTimeline,
    required this.shapBreakdown,
    this.transcript,
    this.coachingText,
  });

  factory SessionDetail.fromJson(Map<String, dynamic> json) => SessionDetail(
        sessionId: (json['session_id'] as String?) ?? '',
        date: json['date'] != null
            ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
            : DateTime.now(),
        overallScore: (json['overall_score'] as num?)?.toInt() ?? 0,
        emotionTimeline: (json['emotion_timeline'] as List<dynamic>?)
                ?.map((e) => EmotionPoint.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        shapBreakdown: (json['shap_breakdown'] as List<dynamic>?)
                ?.map((e) => ShapFeature.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        transcript: json['transcript'] as String?,
        coachingText: json['coaching_text'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'date': date.toIso8601String(),
        'overall_score': overallScore,
        'emotion_timeline': emotionTimeline.map((e) => e.toJson()).toList(),
        'shap_breakdown': shapBreakdown.map((e) => e.toJson()).toList(),
        'transcript': transcript,
      };
}
