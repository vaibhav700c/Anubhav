import 'package:flutter/material.dart';
import '../services/websocket_service.dart';
import '../theme/app_theme.dart';
import 'desi_decorations.dart';

/// Slim non-blocking connection status banner shown at the top of the
/// Live Dashboard when the WebSocket is reconnecting or disconnected.
class ConnectionStatusBanner extends StatelessWidget {
  final WsConnectionState state;

  const ConnectionStatusBanner({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state == WsConnectionState.connected) {
      return const SizedBox.shrink();
    }

    final isReconnecting = state == WsConnectionState.reconnecting;
    final color = isReconnecting ? AnubhavColors.orange : AnubhavColors.negative;
    final icon = isReconnecting ? Icons.wifi_find_rounded : Icons.wifi_off_rounded;
    final label = isReconnecting
        ? 'Reconnecting to session…'
        : 'Connection lost — showing last known data';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Material(
        key: ValueKey(state),
        color: color.withValues(alpha: 0.12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color.withValues(alpha: 0.35), width: 1),
            ),
          ),
          child: Row(
            children: [
              if (isReconnecting)
                MandalaSpinner(
                  size: 16,
                  color: color,
                  duration: const Duration(seconds: 3),
                )
              else
                Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
