import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/detail_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/desi_decorations.dart';
import '../widgets/emotion_graph.dart';
import '../widgets/score_gauge.dart';
import '../widgets/shap_bar_chart.dart';

/// Comprehensive Session Detail Screen with 3 integrated tabs:
/// 1. Transcript (with highlighted fillers & self-corrections)
/// 2. Why This Score (XAI factor cards + Sarvam coaching bubble)
/// 3. Emotion Timeline (scrubbable ribbon + 6-label emoji key)
class SessionDetailScreen extends StatefulWidget {
  final String sessionId;

  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _compareToLastSession = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DetailProvider>().loadSession(widget.sessionId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailProvider = context.watch<DetailProvider>();
    final session = detailProvider.detail;
    final isLoading = detailProvider.isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AnubhavGradients.coolBackground,
        ),
        child: SafeArea(
          child: isLoading || session == null
              ? const Center(child: MandalaLoadingScreen(message: 'Loading session details...'))
              : Column(
                  children: [
                    // ─── Header ────────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Session Detail',
                                  style: AnubhavTextStyles.headlineMedium,
                                ),
                                Text(
                                  'Job Interview Prep • हिन्दी',
                                  style: AnubhavTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AnubhavColors.tealSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'ID: ${session.sessionId}',
                              style: AnubhavTextStyles.bodySmall.copyWith(
                                color: AnubhavColors.teal,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ─── Score Gauge Hero Card ─────────────────────────────────
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AnubhavColors.cardBorder),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A1F5B5B),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ScoreGauge(
                            score: session.overallScore,
                            size: 110,
                            label: '',
                            ringColor: AnubhavColors.darkGreen,
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AnubhavColors.bgWarmPeach,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'OVERALL FLUENCY',
                                    style: AnubhavTextStyles.bodySmall.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AnubhavColors.teal,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${session.overallScore} / 100',
                                  style: AnubhavTextStyles.displayScore.copyWith(fontSize: 28),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Great pacing with natural conversational flow.',
                                  style: AnubhavTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ─── 3-Tab Segmented Switcher ──────────────────────────────
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: AnubhavColors.bgWarmPeach,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0C000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        labelColor: AnubhavColors.teal,
                        unselectedLabelColor: AnubhavColors.textSecondary,
                        labelStyle: AnubhavTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
                        unselectedLabelStyle: AnubhavTextStyles.labelMedium,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'Transcript'),
                          Tab(text: 'Why This Score'),
                          Tab(text: 'Graph'),
                        ],
                      ),
                    ),

                    // ─── Tab Content Views ─────────────────────────────────────
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTranscriptTab(session.transcript ?? ''),
                          _buildXaiTab(session.shapBreakdown, session.overallScore, session.coachingText),
                          _buildEmotionTab(session.emotionTimeline),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ─── Tab 1: Transcript View with Inline Highlights ────────────────────────
  Widget _buildTranscriptTab(String transcriptText) {
    final text = transcriptText.isNotEmpty
        ? transcriptText
        : 'Good morning everyone. Today I want to demonstrate our speech coaching platform. '
            'Basically, um, we connect the VR simulation directly with our mobile app. '
            'Notice how, matlab, our explainability models reveal exactly why your score improved.';

    // Words to highlight as fillers/self-corrections
    final fillers = {'um', 'uh', 'matlab', 'basically', 'you know', 'like'};

    final spans = <TextSpan>[];
    final words = text.split(' ');
    for (int i = 0; i < words.length; i++) {
      final clean = words[i].replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
      final isFiller = fillers.contains(clean);

      if (isFiller) {
        spans.add(
          TextSpan(
            text: '${words[i]} ',
            style: AnubhavTextStyles.bodyLarge.copyWith(
              backgroundColor: const Color(0xFFFDE68A), // Soft yellow/orange pill highlight
              color: const Color(0xFF92400E),
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: '${words[i]} ',
            style: AnubhavTextStyles.bodyLarge.copyWith(color: AnubhavColors.textPrimary),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AnubhavColors.cardBorder),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x061F5B5B),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Verbatim Speech Feed', style: AnubhavTextStyles.titleMedium),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Fillers Highlighted',
                            style: AnubhavTextStyles.bodySmall.copyWith(
                              color: const Color(0xFF92400E),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    RichText(
                      text: TextSpan(children: spans),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Compare to last session toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Compare to last session',
                style: AnubhavTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              Switch.adaptive(
                value: _compareToLastSession,
                activeTrackColor: AnubhavColors.teal,
                onChanged: (v) {
                  setState(() {
                    _compareToLastSession = v;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // "Next" Pill Button to move to XAI
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                _tabController.animateTo(1);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AnubhavColors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              ),
              child: Text(
                'Next: Why This Score',
                style: AnubhavTextStyles.labelLarge,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ─── Tab 2: Why This Score (XAI Breakdown) ────────────────────────────────
  Widget _buildXaiTab(List<dynamic> features, int score, String? coaching) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aligned dual numerals
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AnubhavColors.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('$score', style: AnubhavTextStyles.displayScore.copyWith(fontSize: 36, color: AnubhavColors.teal)),
                    Text('Current Score', style: AnubhavTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                Container(width: 1, height: 40, color: AnubhavColors.divider),
                Column(
                  children: [
                    Text('72', style: AnubhavTextStyles.displayScore.copyWith(fontSize: 36, color: AnubhavColors.textSecondary)),
                    Text('Baseline Avg', style: AnubhavTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Score Impact Factors (SHAP)',
            style: AnubhavTextStyles.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Mathematical attributions of your delivery parameters to the final score',
            style: AnubhavTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),

          // Factor Cards
          ShapBarChart(features: features.cast()),
          const SizedBox(height: 16),

          // Sarvam Coaching Bubble
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AnubhavColors.tealSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AnubhavColors.teal.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AnubhavColors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '(Sarvam LLM Coaching)',
                        style: AnubhavTextStyles.labelMedium.copyWith(
                          color: AnubhavColors.teal,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        coaching?.isNotEmpty == true
                            ? coaching!
                            : 'Notice how "matlab" and "um" clustered in your explanation. Hold a silent 1-second pause instead.',
                        style: AnubhavTextStyles.bodyMedium.copyWith(
                          color: AnubhavColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Next Pill Button to move to Timeline
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                _tabController.animateTo(2);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AnubhavColors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              ),
              child: Text(
                'Next: Emotion Timeline',
                style: AnubhavTextStyles.labelLarge,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── Tab 3: Emotion Graph ─────────────────────────────────────────────────
  Widget _buildEmotionTab(List<dynamic> timeline) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmotionGraph(timeline: timeline.cast()),
          const SizedBox(height: 20),

          // Coaching breakdown of emotion
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AnubhavColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Audience Engagement Summary', style: AnubhavTextStyles.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Your audience responded most actively during your confident pitch opening. '
                  'Slight nervous pitch variance was detected at minute 1:45, after which you regained calm composure.',
                  style: AnubhavTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
