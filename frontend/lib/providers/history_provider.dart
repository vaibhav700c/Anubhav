import 'package:flutter/foundation.dart';

import '../models/session_summary.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class HistoryProvider extends ChangeNotifier {
  final ApiService _api;
  final CacheService _cache;

  // Hard-coded for the demo; swap for an auth-resolved ID in production.
  static const _userId = 'user_001';

  List<SessionSummary> _sessions = [];
  bool _isLoading = false;
  String? _error;
  bool _isOffline = false;

  List<SessionSummary> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOffline => _isOffline;

  HistoryProvider(this._api, this._cache) {
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    _isLoading = true;
    _error = null;
    _isOffline = false;
    notifyListeners();

    try {
      final result = await _api.getHistory(_userId);
      _sessions = result;
      _isOffline = false;
      await _cache.saveHistory(result);
    } catch (e) {
      _error = e.toString();
      // Fall back to cache
      final cached = await _cache.loadHistory();
      if (cached != null && cached.isNotEmpty) {
        _sessions = cached;
        _isOffline = true;
        _error = null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
