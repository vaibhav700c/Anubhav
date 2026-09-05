import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/live_update.dart';
import '../services/cache_service.dart';
import '../services/websocket_service.dart';

/// Manages live session state for the Live Dashboard screen.
class SessionProvider extends ChangeNotifier {
  // ignore: unused_field
  final CacheService _cache;

  WebSocketService? _ws;
  StreamSubscription<LiveUpdate>? _updateSub;
  StreamSubscription<WsConnectionState>? _stateSub;

  double _score = 0;
  String _emotionLabel = 'neutral';
  final List<String> _transcriptLines = [];
  WsConnectionState _connectionState = WsConnectionState.disconnected;
  bool _sessionEnded = false;
  String? _currentSessionId;

  double get score => _score;
  String get emotionLabel => _emotionLabel;
  List<String> get transcriptLines => List.unmodifiable(_transcriptLines);
  WsConnectionState get connectionState => _connectionState;
  bool get sessionEnded => _sessionEnded;
  String? get currentSessionId => _currentSessionId;
  bool get isConnected => _connectionState == WsConnectionState.connected;

  SessionProvider(_, this._cache);

  Future<void> startSession(String sessionId) async {
    _currentSessionId = sessionId;
    _sessionEnded = false;
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

  void endSession() {
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
