/// API configuration for Anubhav.
///
/// Flip [useMockData] to false before connecting to the real FastAPI hub.
/// Change [baseUrl] / [wsUrl] to match your host's LAN IP if running on a
/// physical device (e.g. http://192.168.x.x:8000).
library;

// ─── Toggle ────────────────────────────────────────────────────────────────
const bool useMockData = true;

// ─── URLs ──────────────────────────────────────────────────────────────────
/// HTTP base — Android emulator loopback to host machine.
const String baseUrl = 'http://10.0.2.2:8000';

/// WebSocket base.
const String wsUrl = 'ws://10.0.2.2:8000';

// ─── Endpoints ─────────────────────────────────────────────────────────────
const String historyEndpoint = '/history';
const String sessionEndpoint = '/session';
const String twinEndpoint = '/twin';
const String wsSessionEndpoint = '/session';

// ─── Timeouts ──────────────────────────────────────────────────────────────
const Duration connectTimeout = Duration(seconds: 10);
const Duration receiveTimeout = Duration(seconds: 15);

// ─── Reconnect backoff ─────────────────────────────────────────────────────
const Duration wsInitialBackoff = Duration(seconds: 1);
const Duration wsMaxBackoff = Duration(seconds: 30);
