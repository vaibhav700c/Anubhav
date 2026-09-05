import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/twin_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/twin_trend_chart.dart';

/// Digital Twin Progress Screen ("Your Speaking Journey")
class DigitalTwinScreen extends StatefulWidget {
  const DigitalTwinScreen({super.key});

  @override
  State<DigitalTwinScreen> createState() => _DigitalTwinScreenState();
}

class _DigitalTwinScreenState extends State<DigitalTwinScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TwinProvider>().fetchTwin();
    });
  }

  @override
  Widget build(BuildContext context) {
    final twinProvider = context.watch<TwinProvider>();
    final twin = twinProvider.twin;
    final isLoading = twinProvider.isLoading;

    return Container(
      decoration: const BoxDecoration(
        gradient: AnubhavGradients.coolBackground,
      ),
      child: SafeArea(
        bottom: false,
        child: isLoading || twin == null
            ? const Center(child: CircularProgressIndicator(color: AnubhavColors.teal))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Speaking Journey',
                              style: AnubhavTextStyles.headlineLarge,
                            ),
                            Text(
                              'Longitudinal AI Digital Twin Modeling',
                              style: AnubhavTextStyles.bodySmall,
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AnubhavColors.tealSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: AnubhavColors.teal, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'AI Twin v1.0',
                                style: AnubhavTextStyles.labelMedium.copyWith(
                                  color: AnubhavColors.teal,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Main Trend Chart (Fluency, Fillers, Confidence + Dotted Projection)
                    TwinTrendChart(twin: twin),
                    const SizedBox(height: 24),

                    // Milestones Section
                    Text(
                      'Milestones & Badges',
                      style: AnubhavTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        _buildMilestoneCard('👑', '5-Day Streak', 'Consistent practice king'),
                        const SizedBox(width: 10),
                        _buildMilestoneCard('🥇', '80+ Score', 'Mastery band unlocked'),
                        const SizedBox(width: 10),
                        _buildMilestoneCard('✏️', 'Pitch Pro', 'Pacing under 145 WPM'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Condensed Emotion Distribution Ribbon across past sessions
                    Text(
                      'Overall Emotion Distribution',
                      style: AnubhavTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Aggregate emotional valence across your speech portfolio',
                      style: AnubhavTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AnubhavColors.cardBorder),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              height: 24,
                              child: Row(
                                children: [
                                  Expanded(flex: 55, child: Container(color: const Color(0xFF10B981))), // Confident
                                  Expanded(flex: 25, child: Container(color: const Color(0xFF0284C7))), // Calm
                                  Expanded(flex: 12, child: Container(color: const Color(0xFFF59E0B))), // Nervous
                                  Expanded(flex: 8, child: Container(color: const Color(0xFFEA580C))), // Excited
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildDistributionItem('🙂 Confident', '55%', const Color(0xFF10B981)),
                              _buildDistributionItem('😌 Calm', '25%', const Color(0xFF0284C7)),
                              _buildDistributionItem('😰 Nervous', '12%', const Color(0xFFF59E0B)),
                              _buildDistributionItem('🤩 Excited', '8%', const Color(0xFFEA580C)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Start New Session CTA
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
                            const SizedBox(width: 8),
                            Text(
                              'Start New Session',
                              style: AnubhavTextStyles.labelLarge.copyWith(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMilestoneCard(String icon, String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AnubhavColors.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x061F5B5B),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AnubhavTextStyles.titleMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AnubhavTextStyles.bodySmall.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionItem(String label, String percent, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: AnubhavTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          percent,
          style: AnubhavTextStyles.labelMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
