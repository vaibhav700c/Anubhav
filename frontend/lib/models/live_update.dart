/// A single frame pushed over the WebSocket during a live session.
///
/// Contract field names (match exactly):
///   score              – current 0–100 score (int or double)
///   emotion_label      – current dominant emotion string
///   transcript_partial – latest chunk of transcript text
class LiveUpdate {
  final double score;
  final String emotionLabel;
  final String transcriptPartial;

  const LiveUpdate({
    required this.score,
    required this.emotionLabel,
    required this.transcriptPartial,
  });

  factory LiveUpdate.fromJson(Map<String, dynamic> json) => LiveUpdate(
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        emotionLabel: (json['emotion_label'] as String?) ?? 'neutral',
        transcriptPartial: (json['transcript_partial'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'score': score,
        'emotion_label': emotionLabel,
        'transcript_partial': transcriptPartial,
      };
}
