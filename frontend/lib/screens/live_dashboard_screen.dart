import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../services/websocket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/connection_status_banner.dart';
import '../widgets/emotion_badge.dart';
import '../widgets/score_gauge.dart';
import '../widgets/transcript_feed.dart';

class LiveDashboardScreen extends StatefulWidget {
  const LiveDashboardScreen({super.key});

  @override
  State<LiveDashboardScreen> createState() => _LiveDashboardScreenState();
}

class _LiveDashboardScreenState extends State<LiveDashboardScreen>
    with SingleTickerProviderStateMixin {
  // Hardcoded session ID for demo; in production this would come from the
  // VR headset handshake or a session-start API call.
  static const _demoSessionId = 'live_001';

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  StreamSubscription<bool>? _endedSub;
  bool _hasNavigatedAway = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().startSession(_demoSessionId);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _endedSub?.cancel();
    super.dispose();
  }

  void _onSessionEnded(BuildContext context) {
    if (_hasNavigatedAway) return;
    _hasNavigatedAway = true;
    final navigator = Navigator.of(context);
    // Give a short delay so the API can finalize the report.
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        navigator.pushNamed('/detail', arguments: _demoSessionId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AnubhavColors.background,
      body: Consumer<SessionProvider>(
        builder: (context, provider, _) {
          // Watch for session end → navigate to detail
          if (provider.sessionEnded && !_hasNavigatedAway) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _onSessionEnded(context);
            });
          }

          return Column(
            children: [
              // Connection banner (non-blocking, slim)
              ConnectionStatusBanner(state: provider.connectionState),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),
                        _LiveHeader(pulseAnim: _pulseAnim),
                        const SizedBox(height: 32),

                        // ── Score gauge (most dominant element) ──────────────
                        ScoreGauge(score: provider.score, size: 240),
                        const SizedBox(height: 24),

                        // ── Emotion badge ────────────────────────────────────
                        EmotionBadge(
                            emotion: provider.emotionLabel, fontSize: 15),
                        const SizedBox(height: 32),

                        // ── Stats row ────────────────────────────────────────
                        _StatsRow(provider: provider),
                        const SizedBox(height: 28),

                        // ── Transcript feed ───────────────────────────────────
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Live Transcript',
                              style: AnubhavTextStyles.titleMedium),
                        ),
                        const SizedBox(height: 12),
                        TranscriptFeed(lines: provider.transcriptLines),
                        const SizedBox(height: 28),

                        // ── Session end button (for demo) ─────────────────────
                        if (!provider.sessionEnded)
                          _EndSessionButton(
                            onEnd: () {
                              provider.endSession();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _LiveHeader extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _LiveHeader({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live Session', style: AnubhavTextStyles.headlineLarge),
            Text('Real-time coaching analysis',
                style: AnubhavTextStyles.bodySmall),
          ],
        ),
        const Spacer(),
        ScaleTransition(
          scale: pulseAnim,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AnubhavColors.error.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AnubhavColors.error.withOpacity(0.5), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AnubhavColors.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AnubhavColors.error.withOpacity(0.6),
                          blurRadius: 6)
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Text('LIVE',
                    style: TextStyle(
                        color: AnubhavColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final SessionProvider provider;
  const _StatsRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    final lines = provider.transcriptLines.length;
    final words = provider.transcriptLines
        .join(' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .length;

    return Row(
      children: [
        _StatChip(
          icon: Icons.format_list_numbered,
          label: '$lines',
          sublabel: 'utterances',
          color: AnubhavColors.info,
        ),
        const SizedBox(width: 12),
        _StatChip(
          icon: Icons.text_fields,
          label: '$words',
          sublabel: 'words spoken',
          color: AnubhavColors.accent,
        ),
        const SizedBox(width: 12),
        _StatChip(
          icon: provider.connectionState == WsConnectionState.connected
              ? Icons.wifi
              : Icons.wifi_off,
          label: provider.connectionState == WsConnectionState.connected
              ? 'Online'
              : 'Offline',
          sublabel: 'connection',
          color: provider.connectionState == WsConnectionState.connected
              ? AnubhavColors.success
              : AnubhavColors.error,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AnubhavColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AnubhavColors.cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Outfit')),
            Text(sublabel, style: AnubhavTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _EndSessionButton extends StatelessWidget {
  final VoidCallback onEnd;
  const _EndSessionButton({required this.onEnd});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onEnd,
        icon: const Icon(Icons.stop_circle_outlined),
        label: const Text('End Session (Demo)'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AnubhavColors.error,
          side: BorderSide(color: AnubhavColors.error.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
