import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/session_summary.dart';
import '../providers/history_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/desi_decorations.dart';

/// Session History Screen matching the approved visual mockups
class SessionHistoryScreen extends StatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final sessions = historyProvider.sessions;

    final filtered = sessions.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.sessionId.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      decoration: const BoxDecoration(
        gradient: AnubhavGradients.warmBackground,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ─── Header: Avatar + Title ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Session History',
                    style: AnubhavTextStyles.headlineLarge,
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AnubhavColors.tealSurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'VG',
                        style: TextStyle(
                          color: AnubhavColors.teal,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Search Bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AnubhavColors.cardBorder),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: AnubhavTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    icon: const Icon(Icons.search_rounded, color: AnubhavColors.textTertiary),
                    hintText: 'Search past sessions or topics...',
                    hintStyle: AnubhavTextStyles.bodyMedium.copyWith(color: AnubhavColors.textTertiary),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            // ─── Filter Chips Row ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Date ▾'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Language ▾'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Topic ▾'),
                  ],
                ),
              ),
            ),

            // ─── Sessions List ───────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AnubhavColors.teal,
                onRefresh: () => historyProvider.fetchHistory(),
                child: historyProvider.isLoading && sessions.isEmpty
                    ? const MandalaLoadingScreen(message: 'Loading session history...')
                    : filtered.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final session = filtered[index];
                              return _buildSessionCard(context, session, index);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AnubhavColors.teal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AnubhavColors.teal : AnubhavColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: AnubhavTextStyles.bodySmall.copyWith(
            color: isSelected ? Colors.white : AnubhavColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, SessionSummary session, int index) {
    final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(session.date);

    // Realistic demo topics mapped by index
    final topics = [
      'Job Interview Preparation',
      'Tech Architecture Pitch',
      'Conference Keynote Speech',
      'Team Standup & Showcase',
    ];
    final topicTitle = topics[index % topics.length];

    final languages = ['हिन्दी', 'English', 'தமிழ்', 'తెలుగు'];
    final langTag = languages[index % languages.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AnubhavColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x081F5B5B),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.pushNamed(context, '/detail', arguments: session.sessionId);
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Date & Language Tag + Circular Fluency Score Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AnubhavColors.bgWarmPeach,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                langTag,
                                style: AnubhavTextStyles.bodySmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AnubhavColors.teal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formattedDate,
                              style: AnubhavTextStyles.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          topicTitle,
                          style: AnubhavTextStyles.titleLarge,
                        ),
                      ],
                    ),

                    // Circular Fluency Score Badge in Deep Teal
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AnubhavColors.tealSurface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AnubhavColors.teal.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${session.overallScore}',
                            style: AnubhavTextStyles.titleLarge.copyWith(
                              color: AnubhavColors.teal,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'FLUENCY',
                            style: AnubhavTextStyles.bodySmall.copyWith(
                              color: AnubhavColors.teal,
                              fontWeight: FontWeight.w800,
                              fontSize: 8,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Inline sparkline trend icons + Summary line
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Score: ${session.overallScore} • Fluency • Good Pace',
                      style: AnubhavTextStyles.bodySmall.copyWith(
                        color: AnubhavColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.insights_rounded, size: 16, color: AnubhavColors.teal),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AnubhavColors.textTertiary),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_edu_rounded, size: 60, color: AnubhavColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'No practice sessions yet',
            style: AnubhavTextStyles.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your first speech practice to see analytics here.',
            style: AnubhavTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
