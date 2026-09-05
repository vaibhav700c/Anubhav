/// Digital Twin data from GET /twin/{user_id}.
///
/// Contract field names (match exactly):
///   history_summary          – List of {session_index, score} objects
///   next_session_projection  – projected score for next session (double)
class DigitalTwin {
  /// List of past session scores for trend chart.
  final List<TwinDataPoint> historySummary;

  /// AI-projected score for the next session.
  final double nextSessionProjection;

  const DigitalTwin({
    required this.historySummary,
    required this.nextSessionProjection,
  });

  factory DigitalTwin.fromJson(Map<String, dynamic> json) => DigitalTwin(
        historySummary: (json['history_summary'] as List<dynamic>?)
                ?.map(
                    (e) => TwinDataPoint.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        nextSessionProjection:
            (json['next_session_projection'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'history_summary':
            historySummary.map((e) => e.toJson()).toList(),
        'next_session_projection': nextSessionProjection,
      };
}

/// Single data point in the history_summary list.
class TwinDataPoint {
  final int sessionIndex;
  final double score;

  const TwinDataPoint({required this.sessionIndex, required this.score});

  factory TwinDataPoint.fromJson(Map<String, dynamic> json) => TwinDataPoint(
        sessionIndex: (json['session_index'] as num?)?.toInt() ?? 0,
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'session_index': sessionIndex,
        'score': score,
      };
}
