import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/desi_decorations.dart';
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

    return DesiPatternBackground(
      child: Stack(
        children: [
          // Single mandala for the whole screen — peeks from behind the
          // header, never repeated per-card.
          const Positioned(
            top: -70,
            right: -70,
            child: MandalaCorner(size: 220),
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Brand wordmark ──────────────────────────────────────
                  Text(
                    'ANUBHAV',
                    style: AnubhavTextStyles.bodySmall.copyWith(
                      color: AnubhavColors.teal,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ─── Header: Greeting + Avatar + Streak ──────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AnubhavColors.tealSurface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      AnubhavColors.teal.withValues(alpha: 0.3),
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Namaste, Vaibhav',
                                    style: AnubhavTextStyles.titleLarge,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Ready for your practice today?',
                                    style: AnubhavTextStyles.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Streak Indicator (Count pill, no border)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AnubhavColors.orangeSurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              size: 16,
                              color: AnubhavColors.orange,
                            ),
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
                      color: AnubhavColors.cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AnubhavColors.cardBorder),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x147A1F1F),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AnubhavColors.bgWarmPeach,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'RECENT PERFORMANCE',
                                      style:
                                          AnubhavTextStyles.bodySmall.copyWith(
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Hindi (हिन्दी) • 3m 45s',
                                    style: AnubhavTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F8F0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.trending_up,
                                      color: AnubhavColors.positive, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+6 pts',
                                    style:
                                        AnubhavTextStyles.labelMedium.copyWith(
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
                            size: 165,
                            label: 'Overall Fluency Score',
                            ringColor: AnubhavColors.darkGreen,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Quick metric tags (Aligned in 1 row without disorientation)
                        Row(
                          children: [
                            Expanded(child: _buildHeroTag('142 WPM Pace')),
                            const SizedBox(width: 8),
                            Expanded(child: _buildHeroTag('94% Continuity')),
                            const SizedBox(width: 8),
                            Expanded(child: _buildHeroTag('Confident Flow')),
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
                        shadowColor:
                            AnubhavColors.orange.withValues(alpha: 0.35),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.mic_rounded, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Start New Session',
                            style: AnubhavTextStyles.labelLarge
                                .copyWith(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ─── Secondary Quick-Access Cards ────────────────────────────────
                  Text(
                    'Continue your journey',
                    style: AnubhavTextStyles.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                color: AnubhavColors.cardBg,
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: AnubhavColors.cardBorder),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x147A1F1F),
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'View Digital Twin trend',
                                    style: AnubhavTextStyles.bodySmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
                                color: AnubhavColors.cardBg,
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: AnubhavColors.cardBorder),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x147A1F1F),
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Past recordings & XAI',
                                    style: AnubhavTextStyles.bodySmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
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
        ],
      ),
    );
  }

  Widget _buildHeroTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      decoration: BoxDecoration(
        color: AnubhavColors.bgWarmPeach,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color.fromARGB(0, 56, 55, 55).withValues(alpha: 0.5)),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: AnubhavTextStyles.bodySmall.copyWith(
            color: AnubhavColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
