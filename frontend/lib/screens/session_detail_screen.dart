import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/shap_feature.dart';
import '../providers/detail_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/emotion_timeline_chart.dart';
import '../widgets/shap_bar_chart.dart';
import '../widgets/twin_trend_chart.dart';

class SessionDetailScreen extends StatefulWidget {
  final String sessionId;
  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DetailProvider>().loadSession(widget.sessionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AnubhavColors.background,
      body: Consumer<DetailProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AnubhavColors.accent),
            );
          }
          if (provider.error != null || provider.detail == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: AnubhavColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text('Could not load session',
                      style: AnubhavTextStyles.titleMedium),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () =>
                        provider.loadSession(widget.sessionId),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AnubhavColors.accent),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final detail = provider.detail!;
          final twin = provider.twin;
          final dateStr = DateFormat('d MMM y, h:mm a')
              .format(detail.date.toLocal());
          final color = scoreColor(detail.overallScore);

          return CustomScrollView(
            slivers: [
              // ── SliverAppBar with score hero ──────────────────────────────
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AnubhavColors.background,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: AnubhavColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withOpacity(0.12),
                          AnubhavColors.background,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${detail.overallScore}',
                                style: TextStyle(
                                  fontSize: 72,
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                  fontFamily: 'Outfit',
                                  height: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text('/100',
                                    style: AnubhavTextStyles.headlineMedium
                                        .copyWith(
                                            color: AnubhavColors.textTertiary)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(dateStr, style: AnubhavTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Section 1: Emotion Timeline ──────────────────────────
                    const _SectionHeader(
                      icon: Icons.timeline,
                      title: 'Emotion Timeline',
                      subtitle:
                          'How your emotional state shifted during the session',
                    ),
                    const SizedBox(height: 12),
                    _Card(child: EmotionTimelineChart(points: detail.emotionTimeline)),
                    const SizedBox(height: 8),
                    _EmotionLegend(),
                    const SizedBox(height: 28),

                    // ── Section 2: XAI / SHAP Breakdown ─────────────────────
                    _SectionHeader(
                      icon: Icons.psychology_outlined,
                      title: 'AI Coaching Breakdown',
                      subtitle: 'Why you scored ${detail.overallScore} — the factors that matter most',
                      accentTitle: true,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AnubhavColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AnubhavColors.accent.withOpacity(0.4),
                          width: 1.5,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AnubhavColors.surface,
                            AnubhavColors.accent.withOpacity(0.05),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AnubhavColors.accent.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ShapBarChart(
                          features: detail.shapBreakdown
                              .cast<ShapFeature>()),
                    ),
                    const SizedBox(height: 28),

                    // ── Section 3: Digital Twin ───────────────────────────────
                    const _SectionHeader(
                      icon: Icons.auto_graph,
                      title: 'Digital Twin',
                      subtitle: 'Your progress across sessions and next-session projection',
                    ),
                    const SizedBox(height: 12),
                    if (twin != null)
                      _Card(child: TwinTrendChart(twin: twin))
                    else
                      Container(
                        height: 120,
                        alignment: Alignment.center,
                        child: Text('Twin data unavailable',
                            style: AnubhavTextStyles.bodyMedium),
                      ),
                    const SizedBox(height: 28),

                    // ── Transcript ─────────────────────────────────────────────
                    if (detail.transcript != null) ...[
                      const _SectionHeader(
                        icon: Icons.text_snippet_outlined,
                        title: 'Session Transcript',
                        subtitle: 'Full speech transcript',
                      ),
                      const SizedBox(height: 12),
                      _Card(
                        child: Text(detail.transcript!,
                            style: AnubhavTextStyles.bodyMedium
                                .copyWith(height: 1.7)),
                      ),
                    ],
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Helper widgets ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool accentTitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accentTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon,
                size: 18,
                color: accentTitle
                    ? AnubhavColors.accent
                    : AnubhavColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: accentTitle
                  ? AnubhavTextStyles.headlineMedium
                      .copyWith(color: AnubhavColors.accent)
                  : AnubhavTextStyles.headlineMedium,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Text(subtitle, style: AnubhavTextStyles.bodySmall),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AnubhavColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AnubhavColors.cardBorder),
      ),
      child: child,
    );
  }
}

class _EmotionLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final emotions = ['confident', 'nervous', 'anxious', 'neutral', 'excited'];
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: emotions.map((e) {
        final color = emotionColor(e);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(e[0].toUpperCase() + e.substring(1),
                style: AnubhavTextStyles.bodySmall),
          ],
        );
      }).toList(),
    );
  }
}
