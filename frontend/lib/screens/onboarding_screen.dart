import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/desi_decorations.dart';

/// 3-Screen Onboarding Experience matching the approved mockups
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _onNext() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AnubhavColors.bgCream,
      body: DesiPatternBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar: Brand Logo & Skip Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AnubhavColors.tealSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.graphic_eq_rounded,
                            color: AnubhavColors.teal,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'ANUBHAV',
                          style: AnubhavTextStyles.headlineMedium.copyWith(
                            color: AnubhavColors.teal,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ],
                    ),
                    if (_currentPage < 2)
                      TextButton(
                        onPressed: _finishOnboarding,
                        child: Text(
                          'Skip',
                          style: AnubhavTextStyles.labelMedium.copyWith(
                            color: AnubhavColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // PageView Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    _buildScreen1(),
                    _buildScreen2(),
                    _buildScreen3(),
                  ],
                ),
              ),

              // Bottom Navigation Area: Page Dots + Action Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  children: [
                    // Page Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final isSelected = _currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isSelected ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (_currentPage == 2 ? AnubhavColors.orange : AnubhavColors.teal)
                                : AnubhavColors.cardBorder,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

                    // Next / Get Started Pill Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentPage == 2
                              ? AnubhavColors.orange
                              : AnubhavColors.teal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          shadowColor: (_currentPage == 2
                                  ? AnubhavColors.orange
                                  : AnubhavColors.teal)
                              .withValues(alpha: 0.3),
                        ),
                        child: Text(
                          _currentPage == 2 ? 'Get Started' : 'Next',
                          style: AnubhavTextStyles.labelLarge.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

  // ─── Screen 1: VR Audience Coaching ───────────────────────────────────────
  Widget _buildScreen1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration Card
          Container(
            width: double.infinity,
            height: 260,
            decoration: BoxDecoration(
              color: AnubhavColors.cardBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AnubhavColors.cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x147A1F1F),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft background radial aura
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AnubhavColors.tealSurface.withValues(alpha: 0.6),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        color: AnubhavColors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.view_in_ar_rounded,
                        color: Colors.white,
                        size: 46,
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                          begin: const Offset(0.96, 0.96),
                          end: const Offset(1.04, 1.04),
                          duration: 1800.ms,
                          curve: Curves.easeInOut,
                        ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAudienceBadge('Reactive Crowd'),
                        const SizedBox(width: 8),
                        _buildAudienceBadge('Real-time Coaching'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Headlines
          Text(
            'Practice speaking, in your language, with real feedback',
            textAlign: TextAlign.center,
            style: AnubhavTextStyles.headlineLarge.copyWith(height: 1.25),
          ),
          const SizedBox(height: 12),
          Text(
            'Step onto a virtual stage with a responsive audience and AI that listens to your voice dynamics.',
            textAlign: TextAlign.center,
            style: AnubhavTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AnubhavColors.bgWarmPeach,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AnubhavTextStyles.bodySmall.copyWith(
          color: AnubhavColors.teal,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── Screen 2: Concentric Orbit with Indic Scripts ────────────────────────
  Widget _buildScreen2() {
    final scripts = ['अ', 'அ', 'ర', 'తె', 'বাং', 'ਪੰ', 'म', 'ગુ'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Orbit Illustration Card
          Container(
            width: double.infinity,
            height: 260,
            decoration: BoxDecoration(
              color: AnubhavColors.cardBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AnubhavColors.cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x147A1F1F),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Concentric circles
                Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AnubhavColors.teal.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                ),
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AnubhavColors.orange.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                ),
                // Central glowing microphone
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AnubhavColors.orange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AnubhavColors.orange.withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                // Circling Indic Scripts
                ...List.generate(scripts.length, (i) {
                  final angle = (i * 2 * 3.14159) / scripts.length;
                  const radius = 85.0;
                  return Transform.translate(
                    offset: Offset(
                      radius * 1.05 * (angle == 0 ? 1 : (angle > 0 ? (i % 2 == 0 ? 0.9 : -0.9) : 0)),
                      radius * (i % 2 == 0 ? -0.85 : 0.85),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AnubhavColors.tealSurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AnubhavColors.cardBorder),
                      ),
                      child: Text(
                        scripts[i],
                        style: AnubhavTextStyles.titleMedium.copyWith(
                          color: AnubhavColors.teal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Headlines
          Text(
            'Your language, your voice',
            textAlign: TextAlign.center,
            style: AnubhavTextStyles.headlineLarge.copyWith(height: 1.25),
          ),
          const SizedBox(height: 12),
          Text(
            'Support for 22+ Indian languages powered by Sarvam AI. Practice naturally in the tongue you speak with best.',
            textAlign: TextAlign.center,
            style: AnubhavTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  // ─── Screen 3: Actionable Insights Bar Chart Preview ──────────────────────
  Widget _buildScreen3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Chart Preview Card
          Container(
            width: double.infinity,
            height: 260,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AnubhavColors.cardBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AnubhavColors.cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x147A1F1F),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Score Impact (SHAP)',
                      style: AnubhavTextStyles.titleMedium,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AnubhavColors.tealSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Score: 78',
                        style: AnubhavTextStyles.labelMedium.copyWith(
                          color: AnubhavColors.teal,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Visual Bars (Good Pace = Blue up, Filler Words = Orange down)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Good Pace (Positive +8)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+8 pts',
                          style: AnubhavTextStyles.labelMedium.copyWith(
                            color: AnubhavColors.positiveBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 48,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AnubhavColors.positiveBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Good Pace',
                          style: AnubhavTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // Divider axis
                    Container(
                      width: 1,
                      height: 100,
                      color: AnubhavColors.divider,
                    ),

                    // Filler Words (Negative -6)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '-6 pts',
                          style: AnubhavTextStyles.labelMedium.copyWith(
                            color: AnubhavColors.orange,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 48,
                          height: 55,
                          decoration: BoxDecoration(
                            color: AnubhavColors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Filler Words',
                          style: AnubhavTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Headlines
          Text(
            'Actionable Insights',
            textAlign: TextAlign.center,
            style: AnubhavTextStyles.headlineLarge.copyWith(height: 1.25),
          ),
          const SizedBox(height: 12),
          Text(
            'Know exactly why you scored what you did. Transparent SHAP breakdowns reveal what helped and what to improve.',
            textAlign: TextAlign.center,
            style: AnubhavTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
