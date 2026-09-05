import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/score_gauge.dart';

/// Home / Dashboard Screen matching the approved visual design system
class HomeScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();

    final latestSession = historyProvider.sessions.isNotEmpty
        ? historyProvider.sessions.first
        : null;
    final latestScore = latestSession?.overallScore ?? 78;

    return Container(
      decoration: const BoxDecoration(
        gradient: AnubhavGradients.warmBackground,
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header: Greeting + Avatar + Streak ──────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AnubhavColors.tealSurface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AnubhavColors.teal.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'VG',
                            style: TextStyle(
                              color: AnubhavColors.teal,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Namaste, Vaibhav 👋',
                            style: AnubhavTextStyles.titleLarge,
                          ),
                          Text(
                            'Ready for your practice today?',
                            style: AnubhavTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Streak Indicator (Flame + Count)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AnubhavColors.orangeSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AnubhavColors.orange.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          '5 Days',
                          style: AnubhavTextStyles.labelMedium.copyWith(
                            color: AnubhavColors.orange,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ─── Large Hero Card: Last Session Fluency Score ─────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AnubhavColors.cardBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0C1F5B5B),
                      blurRadius: 20,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AnubhavColors.bgWarmPeach,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'RECENT PERFORMANCE',
                                style: AnubhavTextStyles.bodySmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AnubhavColors.teal,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Job Interview Prep',
                              style: AnubhavTextStyles.headlineMedium,
                            ),
                            Text(
                              '🇮🇳 Hindi (हिन्दी) • 3m 45s',
                              style: AnubhavTextStyles.bodySmall,
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F8F0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.trending_up, color: AnubhavColors.positive, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '+6 pts',
                                style: AnubhavTextStyles.labelMedium.copyWith(
                                  color: AnubhavColors.positive,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Centered Gauge Display
                    Center(
                      child: ScoreGauge(
                        score: latestScore,
                        size: 155,
                        label: 'Overall Fluency Score',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick metric tags
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeroTag('⚡ 142 WPM Pace'),
                        const SizedBox(width: 10),
                        _buildHeroTag('🎯 94% Continuity'),
                        const SizedBox(width: 10),
                        _buildHeroTag('🙂 Confident Flow'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── Primary CTA: Start New Session ──────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/setup');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AnubhavColors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    shadowColor: AnubhavColors.orange.withValues(alpha: 0.35),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mic_rounded, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Start New Session',
                        style: AnubhavTextStyles.labelLarge.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // ─── Secondary Quick-Access Cards ────────────────────────────────
              Row(
                children: [
                  // View Progress (Twin)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (onNavigateTab != null) {
                          onNavigateTab!(2); // Go to Progress tab
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AnubhavColors.cardBorder),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x081F5B5B),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AnubhavColors.tealSurface,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.auto_graph_rounded,
                                color: AnubhavColors.teal,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Speaking Journey',
                              style: AnubhavTextStyles.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'View Digital Twin trend',
                              style: AnubhavTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Session History
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (onNavigateTab != null) {
                          onNavigateTab!(1); // Go to History tab
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AnubhavColors.cardBorder),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x081F5B5B),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AnubhavColors.orangeSurface,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.history_rounded,
                                color: AnubhavColors.orange,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Session History',
                              style: AnubhavTextStyles.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Past recordings & XAI',
                              style: AnubhavTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ─── Coaching Advice Callout ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AnubhavColors.tealSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AnubhavColors.teal.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coach Note (Sarvam AI)',
                            style: AnubhavTextStyles.labelMedium.copyWith(
                              color: AnubhavColors.teal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your flow is strong, but focus on reducing "um"s and "matlab" during transition slides.',
                            style: AnubhavTextStyles.bodyMedium.copyWith(
                              color: AnubhavColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AnubhavColors.bgWarmPeach,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AnubhavTextStyles.bodySmall.copyWith(
          color: AnubhavColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
