import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/session_summary.dart';
import '../providers/history_provider.dart';
import '../theme/app_theme.dart';

class SessionHistoryScreen extends StatelessWidget {
  const SessionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AnubhavColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Anubhav', style: AnubhavTextStyles.headlineMedium),
            Text('Your coaching sessions',
                style: AnubhavTextStyles.bodySmall
                    .copyWith(color: AnubhavColors.textTertiary)),
          ],
        ),
        toolbarHeight: 70,
        actions: [
          _ProfileAvatar(),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.sessions.isEmpty) {
            return const _LoadingSkeleton();
          }
          if (provider.error != null && provider.sessions.isEmpty) {
            return _ErrorState(onRetry: provider.fetchHistory);
          }
          return RefreshIndicator(
            color: AnubhavColors.accent,
            backgroundColor: AnubhavColors.surface,
            onRefresh: provider.fetchHistory,
            child: CustomScrollView(
              slivers: [
                if (provider.isOffline)
                  const SliverToBoxAdapter(child: _OfflineBanner()),
                if (provider.sessions.isEmpty)
                  const SliverFillRemaining(child: _EmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _SessionCard(
                          session: provider.sessions[i],
                          index: i,
                        ),
                        childCount: provider.sessions.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Profile avatar ──────────────────────────────────────────────────────────

class _ProfileAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AnubhavColors.accent, AnubhavColors.accentLight],
        ),
        border: Border.all(color: AnubhavColors.cardBorder, width: 2),
      ),
      child: const Center(
        child: Text('KT',
            style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ─── Session card ─────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final SessionSummary session;
  final int index;

  const _SessionCard({required this.session, required this.index});

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(session.overallScore);
    final dateStr = DateFormat('d MMM, h:mm a').format(session.date.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(
          context,
          '/detail',
          arguments: session.sessionId,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AnubhavColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AnubhavColors.cardBorder),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AnubhavColors.surface,
                color.withOpacity(0.04),
              ],
            ),
          ),
          child: Row(
            children: [
              // Score circle
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.12),
                  border: Border.all(color: color.withOpacity(0.4), width: 2),
                ),
                child: Center(
                  child: Text(
                    '${session.overallScore}',
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session #${index + 1}',
                      style: AnubhavTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 12, color: AnubhavColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(dateStr, style: AnubhavTextStyles.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _ScoreBand(score: session.overallScore),
                  ],
                ),
              ),
              // Chevron
              const Icon(Icons.chevron_right,
                  color: AnubhavColors.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBand extends StatelessWidget {
  final int score;
  const _ScoreBand({required this.score});

  @override
  Widget build(BuildContext context) {
    final String label;
    if (score >= 80) {
      label = '🔥 Excellent';
    } else if (score >= 60) {
      label = '⚡ Good';
    } else {
      label = '📈 Needs Work';
    }
    final color = scoreColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── States ──────────────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AnubhavColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AnubhavColors.warning.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off, size: 16, color: AnubhavColors.warning),
          SizedBox(width: 8),
          Text('Showing offline data',
              style: TextStyle(
                  color: AnubhavColors.warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AnubhavColors.accent.withOpacity(0.1),
              border: Border.all(
                  color: AnubhavColors.accent.withOpacity(0.3), width: 2),
            ),
            child: const Icon(Icons.view_in_ar_outlined,
                size: 44, color: AnubhavColors.accent),
          ),
          const SizedBox(height: 24),
          Text('No sessions yet',
              style: AnubhavTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text('Put on the headset to start your first\npublic speaking session.',
              textAlign: TextAlign.center,
              style: AnubhavTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline,
              color: AnubhavColors.error, size: 48),
          const SizedBox(height: 16),
          Text('Couldn\'t load sessions',
              style: AnubhavTextStyles.titleMedium),
          const SizedBox(height: 8),
          Text('Check your connection and try again.',
              style: AnubhavTextStyles.bodyMedium),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AnubhavColors.accent,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingSkeleton extends StatefulWidget {
  const _LoadingSkeleton();
  @override
  State<_LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<_LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _shimmer = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (ctx, _) {
        final opacity = 0.3 + _shimmer.value * 0.3;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (_, i) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 104,
            decoration: BoxDecoration(
              color: AnubhavColors.surface.withOpacity(opacity),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AnubhavColors.cardBorder),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
