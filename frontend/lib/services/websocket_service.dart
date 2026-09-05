import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import '../config/api_config.dart';
import '../models/live_update.dart';
import 'mock_data_service.dart';

/// WebSocket connection states exposed for the UI banner.
enum WsConnectionState { connected, reconnecting, disconnected }

/// Manages the live session WebSocket.
///
/// Reconnect logic is internal — screens only see [updates] and
/// [connectionState]. In mock mode, a [Timer.periodic] replaces the socket.
class WebSocketService {
  final String sessionId;

  final _updateController = StreamController<LiveUpdate>.broadcast();
  final _stateController =
      StreamController<WsConnectionState>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSub;
  bool _disposed = false;
  int _retryCount = 0;

  Stream<LiveUpdate> get updates => _updateController.stream;
  Stream<WsConnectionState> get connectionState => _stateController.stream;

  WebSocketService(this.sessionId) {
    if (useMockData) {
      _startMock();
    } else {
      _connect();
    }
  }

  // ─── Mock mode ────────────────────────────────────────────────────────────

  StreamSubscription<LiveUpdate>? _mockSub;

  void _startMock() {
    _emit(WsConnectionState.connected);
    _mockSub = MockDataService.getLiveMockStream().listen(
      (update) => _updateController.add(update),
      onDone: () {
        if (!_disposed) _emit(WsConnectionState.disconnected);
      },
    );
  }

  // ─── Real WebSocket ───────────────────────────────────────────────────────

  void _connect() {
    if (_disposed) return;
    _emit(WsConnectionState.reconnecting);
    try {
      final uri = Uri.parse('$wsUrl$wsSessionEndpoint/$sessionId');
      _channel = WebSocketChannel.connect(uri);
      _channelSub = _channel!.stream.listen(
        _onData,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: false,
      );
      _emit(WsConnectionState.connected);
      _retryCount = 0;
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onData(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      _updateController.add(LiveUpdate.fromJson(json));
    } catch (_) {
      // Ignore malformed frames.
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _emit(WsConnectionState.reconnecting);
    _channelSub?.cancel();
    _channel?.sink.close(ws_status.goingAway);

    final delay = Duration(
      milliseconds: min(
        wsInitialBackoff.inMilliseconds * pow(2, _retryCount).toInt(),
        wsMaxBackoff.inMilliseconds,
      ),
    );
    _retryCount++;
    Timer(delay, _connect);
  }

  void _emit(WsConnectionState state) {
    if (!_stateController.isClosed) _stateController.add(state);
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  void dispose() {
    _disposed = true;
    _mockSub?.cancel();
    _channelSub?.cancel();
    _channel?.sink.close(ws_status.normalClosure);
    _updateController.close();
    _stateController.close();
  }
}
