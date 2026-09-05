/// API configuration for Anubhav.
///
/// [useMockData] is now false: the app talks to the real FastAPI hub
/// (backend/app/main.py) instead of MockDataService. Flip it back to true
/// for an offline demo fallback if the hub is ever unreachable at showtime.
///
/// [baseUrl] / [wsUrl] currently point at the Android emulator's loopback
/// alias for the host machine (10.0.2.2) - that only resolves from an
/// emulator. Before running on a physical phone (including alongside the
/// Quest at a demo), change both to the LAN IP of whatever machine is
/// running `uvicorn app.main:app --host 0.0.0.0 --port 8000`, e.g.
/// 'http://192.168.1.20:8000' / 'ws://192.168.1.20:8000' - the same host
/// the Unity client's HubClient.hubBaseUrl needs to point at for both
/// clients to reach the same session.
library;

// ─── Toggle ────────────────────────────────────────────────────────────────
const bool useMockData = false;

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
