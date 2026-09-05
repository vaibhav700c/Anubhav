import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/session_summary.dart';

/// Thin shared_preferences wrapper.
///
/// Stores:
///   - Last known session list (for offline history)
///   - Last live score / emotion / transcript (so Live Dashboard never blanks)
class CacheService {
  static const _keyHistory = 'cached_history';
  static const _keyLiveScore = 'cached_live_score';
  static const _keyLiveEmotion = 'cached_live_emotion';
  static const _keyLiveTranscript = 'cached_live_transcript';

  // ─── History ──────────────────────────────────────────────────────────────

  Future<void> saveHistory(List<SessionSummary> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = sessions.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_keyHistory, jsonList);
  }

  Future<List<SessionSummary>?> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_keyHistory);
    if (jsonList == null) return null;
    return jsonList
        .map((s) => SessionSummary.fromJson(
            jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  // ─── Live session ─────────────────────────────────────────────────────────

  Future<void> saveLiveState({
    required double score,
    required String emotion,
    required List<String> transcriptLines,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLiveScore, score);
    await prefs.setString(_keyLiveEmotion, emotion);
    await prefs.setString(_keyLiveTranscript, jsonEncode(transcriptLines));
  }

  Future<({double score, String emotion, List<String> transcriptLines})?>
      loadLiveState() async {
    final prefs = await SharedPreferences.getInstance();
    final score = prefs.getDouble(_keyLiveScore);
    final emotion = prefs.getString(_keyLiveEmotion);
    final transcriptJson = prefs.getString(_keyLiveTranscript);
    if (score == null || emotion == null) return null;
    final lines = transcriptJson != null
        ? List<String>.from(jsonDecode(transcriptJson) as List)
        : <String>[];
    return (score: score, emotion: emotion, transcriptLines: lines);
  }
}
