/// API configuration for Anubhav.
///
/// [useMockData] is false: the app talks to the real FastAPI hub instead of
/// MockDataService. Flip it back to true for an offline demo fallback if the
/// hub is ever unreachable at showtime.
///
/// [baseUrl] / [wsUrl] point at the deployed Render hub (anubhav-hub), so
/// this works from a physical device on any network, no LAN-IP juggling
/// needed. The Unity client's HubClient.hubBaseUrl points at the same host
/// (wss://anubhav-hub.onrender.com) so both clients share a session. Render's
/// free tier spins down when idle - the first request after a quiet period
/// can take 30-50s to wake it back up.
///
/// For local-backend development instead, swap these for
/// 'http://10.0.2.2:8000' / 'ws://10.0.2.2:8000' (Android emulator) or your
/// machine's LAN IP (physical device).
library;

// ─── Toggle ────────────────────────────────────────────────────────────────
const bool useMockData = false;

// ─── URLs ──────────────────────────────────────────────────────────────────
/// HTTP base — deployed Render hub.
const String baseUrl = 'https://anubhav-hub.onrender.com';

/// WebSocket base.
const String wsUrl = 'wss://anubhav-hub.onrender.com';

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
