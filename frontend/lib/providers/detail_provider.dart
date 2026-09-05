import 'package:flutter/foundation.dart';

import '../models/digital_twin.dart';
import '../models/session_detail.dart';
import '../services/api_service.dart';

class DetailProvider extends ChangeNotifier {
  final ApiService _api;
  static const _userId = 'user_001';

  SessionDetail? _detail;
  DigitalTwin? _twin;
  bool _isLoading = false;
  String? _error;

  SessionDetail? get detail => _detail;
  DigitalTwin? get twin => _twin;
  bool get isLoading => _isLoading;
  String? get error => _error;

  DetailProvider(this._api);

  Future<void> loadSession(String sessionId) async {
    _isLoading = true;
    _error = null;
    _detail = null;
    _twin = null;
    notifyListeners();

    try {
      // Fetch detail and twin concurrently.
      final results = await Future.wait([
        _api.getSessionDetail(sessionId),
        _api.getTwin(_userId),
      ]);
      _detail = results[0] as SessionDetail;
      _twin = results[1] as DigitalTwin;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
