import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
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

class _LiveDashboardScreenState extends State<LiveDashboardScreen> with SingleTickerProviderStateMixin {
  static const _demoSessionId = 'live_001';

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  bool _hasNavigatedAway = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().startSession(_demoSessionId);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onSessionEnded(BuildContext context) {
    if (_hasNavigatedAway) return;
    _hasNavigatedAway = true;
    final navigator = Navigator.of(context);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        navigator.pushReplacementNamed('/detail', arguments: _demoSessionId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AnubhavGradients.coolBackground,
        ),
        child: Consumer<SessionProvider>(
          builder: (context, provider, _) {
            if (provider.sessionEnded && !_hasNavigatedAway) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _onSessionEnded(context);
              });
            }

            return Column(
              children: [
                ConnectionStatusBanner(state: provider.connectionState),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    child: SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _LiveHeader(pulseAnim: _pulseAnim),
                          const SizedBox(height: 24),

                          // Score Gauge card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AnubhavColors.cardBorder),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0A1F5B5B),
                                  blurRadius: 18,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                ScoreGauge(score: provider.score, size: 180),
                                const SizedBox(height: 16),
                                EmotionBadge(emotion: provider.emotionLabel, fontSize: 14),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Live Metrics Stats row
                          _StatsRow(provider: provider),
                          const SizedBox(height: 24),

                          // Live Transcript feed card
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Live Transcript Feed',
                              style: AnubhavTextStyles.titleMedium,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AnubhavColors.cardBorder),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: TranscriptFeed(lines: provider.transcriptLines),
                          ),
                          const SizedBox(height: 24),

                          // End session button
                          if (!provider.sessionEnded)
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: () {
                                  provider.endSession();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AnubhavColors.teal,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(27),
                                  ),
                                ),
                                child: Text(
                                  'Finish Practice Session',
                                  style: AnubhavTextStyles.labelLarge.copyWith(fontSize: 15),
                                ),
                              ),
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
      ),
    );
  }
}

class _LiveHeader extends StatelessWidget {
  final Animation<double> pulseAnim;

  const _LiveHeader({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('VR Live Companion', style: AnubhavTextStyles.headlineMedium),
            Text('Streaming speech & emotion telemetry', style: AnubhavTextStyles.bodySmall),
          ],
        ),
        ScaleTransition(
          scale: pulseAnim,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFDEEE9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AnubhavColors.orange, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AnubhavColors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: AnubhavColors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
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
    return Row(
      children: [
        _buildStatCard('Speaking Pace', '142 WPM', Icons.speed_rounded, AnubhavColors.teal),
        const SizedBox(width: 12),
        _buildStatCard('Continuity', '94%', Icons.timeline_rounded, AnubhavColors.positive),
        const SizedBox(width: 12),
        _buildStatCard('Audience', '25 NPCs', Icons.groups_rounded, AnubhavColors.orange),
      ],
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AnubhavColors.cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: accent),
            const SizedBox(height: 6),
            Text(
              val,
              style: AnubhavTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              title,
              style: AnubhavTextStyles.bodySmall.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
