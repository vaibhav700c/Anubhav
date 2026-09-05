import 'package:flutter/foundation.dart';

import '../models/digital_twin.dart';
import '../services/api_service.dart';

/// Standalone twin provider — used if you need the twin independently
/// (e.g. a future dedicated "Progress" tab). Detail screen uses
/// DetailProvider which fetches twin inline.
class TwinProvider extends ChangeNotifier {
  final ApiService _api;
  static const _userId = 'user_001';

  DigitalTwin? _twin;
  bool _isLoading = false;
  String? _error;

  DigitalTwin? get twin => _twin;
  bool get isLoading => _isLoading;
  String? get error => _error;

  TwinProvider(this._api);

  Future<void> fetchTwin() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _twin = await _api.getTwin(_userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
