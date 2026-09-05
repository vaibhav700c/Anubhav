import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/live_update.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/websocket_service.dart';

/// Manages live session state for the Live Dashboard screen.
class SessionProvider extends ChangeNotifier {
  final ApiService _api;
  // ignore: unused_field
  final CacheService _cache;
  static const _userId = 'user_001';

  WebSocketService? _ws;
  StreamSubscription<LiveUpdate>? _updateSub;
  StreamSubscription<WsConnectionState>? _stateSub;

  double _score = 0;
  String _emotionLabel = 'neutral';
  final List<String> _transcriptLines = [];
  WsConnectionState _connectionState = WsConnectionState.disconnected;
  bool _sessionEnded = false;
  bool _isEnding = false;
  String? _currentSessionId;
  String? _topic;
  String? _language;
  String? _audienceSize;

  double get score => _score;
  String get emotionLabel => _emotionLabel;
  List<String> get transcriptLines => List.unmodifiable(_transcriptLines);
  WsConnectionState get connectionState => _connectionState;
  bool get sessionEnded => _sessionEnded;
  String? get currentSessionId => _currentSessionId;
  bool get isConnected => _connectionState == WsConnectionState.connected;

  SessionProvider(this._api, this._cache);

  /// [topic] / [language] / [audienceSize] come from the Pre-Session Setup
  /// screen and are only actually sent to the hub when the session ends
  /// (there's no separate "start session" call in the hub's contract).
  Future<void> startSession(
    String sessionId, {
    String? topic,
    String? language,
    String? audienceSize,
  }) async {
    _currentSessionId = sessionId;
    _topic = topic;
    _language = language;
    _audienceSize = audienceSize;
    _sessionEnded = false;
    _isEnding = false;
    _transcriptLines.clear();

    // Restore last known state from cache so the screen is never blank.
    final cached = await _cache.loadLiveState();
    if (cached != null) {
      _score = cached.score;
      _emotionLabel = cached.emotion;
      _transcriptLines.addAll(cached.transcriptLines);
      notifyListeners();
    }

    _ws?.dispose();
    _ws = WebSocketService(sessionId);

    _stateSub = _ws!.connectionState.listen((state) {
      _connectionState = state;
      notifyListeners();
    });

    _updateSub = _ws!.updates.listen(
      _onUpdate,
      onDone: _onSessionEnded,
    );
  }

  void _onUpdate(LiveUpdate update) {
    _score = update.score;
    _emotionLabel = update.emotionLabel;
    if (update.transcriptPartial.isNotEmpty) {
      _transcriptLines.add(update.transcriptPartial);
    }
    _cache.saveLiveState(
      score: _score,
      emotion: _emotionLabel,
      transcriptLines: _transcriptLines,
    );
    notifyListeners();
  }

  void _onSessionEnded() {
    _sessionEnded = true;
    _connectionState = WsConnectionState.disconnected;
    notifyListeners();
  }

  /// Ends the session and finalizes it on the hub so the report screen shows
  /// this speaker's real score/SHAP breakdown instead of the hub's mock
  /// fallback. Harmless to call even if the VR headset already finalized the
  /// same session_id - the hub just recomputes over the same transcript.
  Future<void> endSession() async {
    if (_isEnding) return;
    _isEnding = true;

    if (_currentSessionId != null) {
      try {
        await _api.completeSession(
          sessionId: _currentSessionId!,
          userId: _userId,
          topic: _topic,
          language: _language,
          audienceSize: _audienceSize,
        );
      } catch (_) {
        // The report screen falls back to GET /session/{id}'s own mock
        // response if this failed to persist anything - never block the
        // user's flow on it.
      }
    }

    _sessionEnded = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _updateSub?.cancel();
    _stateSub?.cancel();
    _ws?.dispose();
    super.dispose();
  }
}
