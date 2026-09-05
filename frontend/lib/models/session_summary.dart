/// Summary entry shown in the Session History list.
///
/// Contract field names (match exactly):
///   session_id     – unique session identifier
///   date           – ISO 8601 datetime string
///   overall_score  – 0–100 integer
class SessionSummary {
  final String sessionId;
  final DateTime date;
  final int overallScore;

  const SessionSummary({
    required this.sessionId,
    required this.date,
    required this.overallScore,
  });

  factory SessionSummary.fromJson(Map<String, dynamic> json) => SessionSummary(
        sessionId: (json['session_id'] as String?) ?? '',
        date: json['date'] != null
            ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
            : DateTime.now(),
        overallScore: (json['overall_score'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'date': date.toIso8601String(),
        'overall_score': overallScore,
      };
}
