import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/desi_decorations.dart';

/// Pre-Session Setup Screen ("Setup Your Practice")
class PreSessionSetupScreen extends StatefulWidget {
  const PreSessionSetupScreen({super.key});

  @override
  State<PreSessionSetupScreen> createState() => _PreSessionSetupScreenState();
}

class _PreSessionSetupScreenState extends State<PreSessionSetupScreen> {
  String _selectedLanguage = 'Hindi (हिन्दी)';
  final TextEditingController _topicController = TextEditingController(text: 'Job Interview');
  int _selectedAudienceSize = 1; // 0: Small, 1: Medium, 2: Large

  final List<String> _languages = [
    'Hindi (हिन्दी)',
    'Tamil (தமிழ்)',
    'Telugu (తెలుగు)',
    'Bengali (বাংলা)',
    'English',
  ];

  /// NPC counts shown next to each size option - also what's sent to the hub
  /// as audience_size, since it's more meaningful there than "Small/Medium/Large".
  static const List<String> _audienceSizeCounts = ['10', '25', '50'];

  final List<String> _topicSuggestions = [
    'Job Interview',
    'Wedding Speech',
    'Pitch Deck',
    'Keynote Address',
  ];

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AnubhavColors.bgCream,
      body: DesiPatternBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ─── Header ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Setup Your Practice',
                      style: AnubhavTextStyles.headlineMedium,
                    ),
                    const Spacer(),
                    Container(
                      width: 38,
                      height: 38,
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
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Scrollable Form ─────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Practice Language Section
                      Text(
                        'Practice Language',
                        style: AnubhavTextStyles.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select the language you want to speak and receive coaching in',
                        style: AnubhavTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 14),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _languages.map((lang) {
                          final isSelected = _selectedLanguage == lang;
                          return ChoiceChip(
                            label: Text(lang),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                _selectedLanguage = lang;
                              });
                            },
                            labelStyle: AnubhavTextStyles.labelMedium.copyWith(
                              color: isSelected ? Colors.white : AnubhavColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                            backgroundColor: AnubhavColors.cardBg,
                            selectedColor: AnubhavColors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: isSelected ? 2 : 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      // 2. Choose a Topic Section
                      Text(
                        'Choose a Topic',
                        style: AnubhavTextStyles.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Set the scenario to simulate the appropriate audience vibe',
                        style: AnubhavTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 14),

                      Container(
                        decoration: BoxDecoration(
                          color: AnubhavColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AnubhavColors.cardBorder),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _topicController,
                          style: AnubhavTextStyles.bodyLarge,
                          decoration: InputDecoration(
                            hintText: 'Enter topic e.g., Job Interview',
                            hintStyle: AnubhavTextStyles.bodyMedium.copyWith(color: AnubhavColors.textTertiary),
                            border: InputBorder.none,
                            icon: const Icon(Icons.edit_note_rounded, color: AnubhavColors.teal),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Topic suggestion chips
                      Wrap(
                        spacing: 8,
                        children: _topicSuggestions.map((topic) {
                          return ActionChip(
                            label: Text(topic),
                            labelStyle: AnubhavTextStyles.bodySmall.copyWith(
                              color: AnubhavColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                            backgroundColor: AnubhavColors.bgWarmPeach,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide.none,
                            ),
                            onPressed: () {
                              setState(() {
                                _topicController.text = topic;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      // 3. Audience Size Section
                      Text(
                        'Audience Size',
                        style: AnubhavTextStyles.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Controls the number and distribution of responsive VR avatars',
                        style: AnubhavTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AnubhavColors.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AnubhavColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            _buildAudienceSizeOption(0, 'Small', '10 NPCs', Icons.group_outlined),
                            _buildAudienceSizeOption(1, 'Medium', '25 NPCs', Icons.groups_outlined),
                            _buildAudienceSizeOption(2, 'Large', '50 NPCs', Icons.diversity_3_outlined),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // ─── Bottom CTA ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/vr-handoff',
                            arguments: {
                              'topic': _topicController.text.trim().isEmpty
                                  ? 'Practice Session'
                                  : _topicController.text.trim(),
                              'language': _selectedLanguage,
                              'audienceSize': _audienceSizeCounts[_selectedAudienceSize],
                            },
                          );
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
                        child: Text(
                          'Put on your headset',
                          style: AnubhavTextStyles.labelLarge.copyWith(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Calibrating VR connection...',
                      style: AnubhavTextStyles.bodySmall.copyWith(
                        color: AnubhavColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudienceSizeOption(int index, String title, String count, IconData icon) {
    final isSelected = _selectedAudienceSize == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedAudienceSize = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AnubhavColors.tealSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: AnubhavColors.teal, width: 1.5)
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AnubhavColors.teal : AnubhavColors.textTertiary,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: AnubhavTextStyles.titleMedium.copyWith(
                  color: isSelected ? AnubhavColors.teal : AnubhavColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              Text(
                count,
                style: AnubhavTextStyles.bodySmall.copyWith(
                  color: isSelected ? AnubhavColors.teal : AnubhavColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
