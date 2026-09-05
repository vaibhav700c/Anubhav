import 'dart:async';
import 'dart:math';

import '../models/digital_twin.dart';
import '../models/emotion_point.dart';
import '../models/live_update.dart';
import '../models/session_detail.dart';
import '../models/session_summary.dart';
import '../models/shap_feature.dart';

/// Provides realistic canned data for every screen.
///
/// All field names match the API contract exactly so flipping [useMockData]
/// to false and wiring real services requires zero model changes.
class MockDataService {
  static final _random = Random();

  // ─── Session History ──────────────────────────────────────────────────────

  static List<SessionSummary> getHistory() {
    return [
      SessionSummary(
        sessionId: 's005',
        date: DateTime.parse('2026-09-05T10:32:00Z'),
        overallScore: 74,
      ),
      SessionSummary(
        sessionId: 's004',
        date: DateTime.parse('2026-09-04T14:15:00Z'),
        overallScore: 68,
      ),
      SessionSummary(
        sessionId: 's003',
        date: DateTime.parse('2026-09-03T09:00:00Z'),
        overallScore: 82,
      ),
      SessionSummary(
        sessionId: 's002',
        date: DateTime.parse('2026-09-02T16:45:00Z'),
        overallScore: 55,
      ),
      SessionSummary(
        sessionId: 's001',
        date: DateTime.parse('2026-09-01T11:20:00Z'),
        overallScore: 61,
      ),
    ];
  }

  // ─── Session Detail ───────────────────────────────────────────────────────

  static SessionDetail getSessionDetail(String sessionId) {
    return SessionDetail(
      sessionId: sessionId,
      date: DateTime.parse('2026-09-05T10:32:00Z'),
      overallScore: 74,
      emotionTimeline: [
        const EmotionPoint(time: 0, emotion: 'neutral', intensity: 0.60),
        const EmotionPoint(time: 15, emotion: 'nervous', intensity: 0.72),
        const EmotionPoint(time: 30, emotion: 'nervous', intensity: 0.68),
        const EmotionPoint(time: 45, emotion: 'confident', intensity: 0.75),
        const EmotionPoint(time: 60, emotion: 'confident', intensity: 0.82),
        const EmotionPoint(time: 75, emotion: 'excited', intensity: 0.88),
        const EmotionPoint(time: 90, emotion: 'confident', intensity: 0.79),
        const EmotionPoint(time: 105, emotion: 'anxious', intensity: 0.65),
        const EmotionPoint(time: 120, emotion: 'neutral', intensity: 0.58),
        const EmotionPoint(time: 135, emotion: 'confident', intensity: 0.80),
        const EmotionPoint(time: 150, emotion: 'confident', intensity: 0.85),
        const EmotionPoint(time: 165, emotion: 'excited', intensity: 0.90),
        const EmotionPoint(time: 180, emotion: 'confident', intensity: 0.83),
      ],
      shapBreakdown: [
        const ShapFeature(
          feature: 'filler_words',
          contribution: -8.3,
          explanation:
              'Too many filler words (um, uh, like) lowered your score by 8 points.',
        ),
        const ShapFeature(
          feature: 'pace',
          contribution: 5.1,
          explanation:
              'Your speaking pace was well-controlled and easy to follow.',
        ),
        const ShapFeature(
          feature: 'pitch_variance',
          contribution: -4.7,
          explanation:
              'Monotone delivery in the second half reduced engagement.',
        ),
        const ShapFeature(
          feature: 'eye_contact',
          contribution: 6.2,
          explanation:
              'Strong eye contact with the audience boosted your presence.',
        ),
        const ShapFeature(
          feature: 'gesture_frequency',
          contribution: 3.5,
          explanation:
              'Natural hand gestures reinforced your key points effectively.',
        ),
      ],
      transcript:
          'Good morning everyone. Um, today I want to talk about, uh, the future of '
          'artificial intelligence in, like, healthcare. So, the first thing we need '
          'to understand is that AI isn\'t replacing doctors — it\'s augmenting them. '
          'In fact, studies show a 40% improvement in diagnostic accuracy when AI '
          'assists radiologists. The implications for patient outcomes are profound. '
          'Let me show you three key examples from our research...',
    );
  }

  // ─── Digital Twin ─────────────────────────────────────────────────────────

  static DigitalTwin getTwin(String userId) {
    return const DigitalTwin(
      historySummary: [
        TwinDataPoint(sessionIndex: 1, score: 61),
        TwinDataPoint(sessionIndex: 2, score: 55),
        TwinDataPoint(sessionIndex: 3, score: 82),
        TwinDataPoint(sessionIndex: 4, score: 68),
        TwinDataPoint(sessionIndex: 5, score: 74),
      ],
      nextSessionProjection: 81.0,
    );
  }

  // ─── Mock WebSocket stream ────────────────────────────────────────────────

  static final List<Map<String, dynamic>> _wsFrames = [
    {'score': 60, 'emotion_label': 'neutral', 'transcript_partial': 'Good morning everyone.'},
    {'score': 63, 'emotion_label': 'nervous', 'transcript_partial': 'Um, today I want to talk about'},
    {'score': 61, 'emotion_label': 'nervous', 'transcript_partial': 'the future of artificial intelligence.'},
    {'score': 65, 'emotion_label': 'neutral', 'transcript_partial': 'In healthcare specifically,'},
    {'score': 68, 'emotion_label': 'confident', 'transcript_partial': 'AI isn\'t replacing doctors —'},
    {'score': 71, 'emotion_label': 'confident', 'transcript_partial': 'it\'s augmenting them.'},
    {'score': 73, 'emotion_label': 'excited', 'transcript_partial': 'Studies show a 40% improvement'},
    {'score': 75, 'emotion_label': 'excited', 'transcript_partial': 'in diagnostic accuracy.'},
    {'score': 72, 'emotion_label': 'confident', 'transcript_partial': 'The implications for patients are profound.'},
    {'score': 74, 'emotion_label': 'confident', 'transcript_partial': 'Let me show you three key examples.'},
    {'score': 69, 'emotion_label': 'anxious', 'transcript_partial': 'Uh, from our research...'},
    {'score': 71, 'emotion_label': 'neutral', 'transcript_partial': 'First, radiology. AI models'},
    {'score': 74, 'emotion_label': 'confident', 'transcript_partial': 'now detect tumors with 94% accuracy.'},
    {'score': 76, 'emotion_label': 'confident', 'transcript_partial': 'Second, drug discovery timelines'},
    {'score': 74, 'emotion_label': 'confident', 'transcript_partial': 'have dropped from 12 years to 4.'},
  ];

  static Stream<LiveUpdate> getLiveMockStream() {
    final controller = StreamController<LiveUpdate>();
    int frameIndex = 0;

    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (frameIndex >= _wsFrames.length) {
        controller.close();
        timer.cancel();
        return;
      }
      // Add a little noise to score to look alive
      final frame = Map<String, dynamic>.from(_wsFrames[frameIndex]);
      final baseScore = (frame['score'] as int).toDouble();
      frame['score'] = baseScore + (_random.nextDouble() * 4 - 2);
      controller.add(LiveUpdate.fromJson(frame));
      frameIndex++;
    });

    return controller.stream;
  }
}
