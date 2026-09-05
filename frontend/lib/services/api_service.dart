import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/digital_twin.dart';
import '../models/session_detail.dart';
import '../models/session_summary.dart';
import 'mock_data_service.dart';

/// REST client for all Anubhav API calls.
///
/// When [useMockData] is true (default for demo), all calls return instantly
/// from [MockDataService] without touching the network.
class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    // ─── Logging interceptor ──────────────────────────────────────────────
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => _log(obj.toString()),
    ));

    // ─── Error-normalising interceptor ────────────────────────────────────
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (err, handler) {
        _log('API error: ${err.message}');
        handler.next(err);
      },
    ));
  }

  void _log(String msg) {
    // In a real app you'd use a proper logger package.
    // ignore: avoid_print
    print('[ApiService] $msg');
  }

  // ─── History ──────────────────────────────────────────────────────────────

  Future<List<SessionSummary>> getHistory(String userId) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 600)); // simulate network
      return MockDataService.getHistory();
    }
    final res = await _dio.get('$historyEndpoint/$userId');
    return (res.data as List<dynamic>)
        .map((e) => SessionSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Session Detail ───────────────────────────────────────────────────────

  Future<SessionDetail> getSessionDetail(String sessionId) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return MockDataService.getSessionDetail(sessionId);
    }
    final res = await _dio.get('$sessionEndpoint/$sessionId');
    return SessionDetail.fromJson(res.data as Map<String, dynamic>);
  }

  // ─── Digital Twin ─────────────────────────────────────────────────────────

  Future<DigitalTwin> getTwin(String userId) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      return MockDataService.getTwin(userId);
    }
    final res = await _dio.get('$twinEndpoint/$userId');
    return DigitalTwin.fromJson(res.data as Map<String, dynamic>);
  }

  // ─── Session Complete ─────────────────────────────────────────────────────

  /// Finalizes a session: triggers metrics/SHAP/Digital-Twin computation and
  /// persistence on the hub. Safe to call even if the VR side already called
  /// this for the same session_id - the hub just recomputes and overwrites
  /// the same record, so whichever client ends the session first for the
  /// user (phone or headset) is enough to produce a real report instead of
  /// falling back to the hub's generic mock-data response.
  ///
  /// [topic] / [language] / [audienceSize] are the choices made on the
  /// Pre-Session Setup screen - the hub has no separate "start session"
  /// endpoint, so this is the only point where they can reach it.
  Future<void> completeSession({
    required String sessionId,
    required String userId,
    String? topic,
    String? language,
    String? audienceSize,
  }) async {
    if (useMockData) {
      return; // nothing to finalize against a mock hub
    }
    await _dio.post('$sessionEndpoint/complete', data: {
      'session_id': sessionId,
      'user_id': userId,
      if (topic != null) 'topic': topic,
      if (language != null) 'language': language,
      if (audienceSize != null) 'audience_size': audienceSize,
    });
  }
}
