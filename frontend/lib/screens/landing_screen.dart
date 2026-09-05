import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LandingScreen:
/// Displays the landing_page.png hero visual on app launch/cold restart for 5 seconds,
/// then automatically navigates to the home page ('/home').
class LandingScreen extends StatefulWidget {
  /// If true, checks SharedPreferences to only show once.
  /// Defaults to false so it reliably displays on cold restart / startup.
  final bool checkFirstTime;

  const LandingScreen({
    super.key,
    this.checkFirstTime = false,
  });

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  Timer? _timer;
  bool _isLoading = false;
  double _progress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    if (widget.checkFirstTime) {
      _isLoading = true;
      _handleFirstLaunchFlow();
    } else {
      _startLandingCountdown();
    }
  }

  void _startLandingCountdown() {
    // Animate progress bar over 5 seconds
    const totalMs = 5000;
    const intervalMs = 50;
    const steps = totalMs ~/ intervalMs;
    int currentStep = 0;

    _progressTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      currentStep++;
      if (mounted) {
        setState(() {
          _progress = (currentStep / steps).clamp(0.0, 1.0);
        });
      }
      if (currentStep >= steps) {
        timer.cancel();
      }
    });

    // 5-second automatic redirect to home
    _timer = Timer(const Duration(milliseconds: totalMs), () {
      if (mounted) {
        _navigateToHome();
      }
    });
  }

  Future<void> _handleFirstLaunchFlow() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('has_seen_landing') ?? false;

    if (hasSeen) {
      // User has already opened the app previously; skip straight to home
      if (mounted) {
        _navigateToHome(immediate: true);
      }
      return;
    }

    // First time opening the app! Mark as seen
    await prefs.setBool('has_seen_landing', true);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    _startLandingCountdown();
  }

  void _navigateToHome({bool immediate = false}) {
    _timer?.cancel();
    _progressTimer?.cancel();
    if (!mounted) return;

    if (immediate) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFAC5C31),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFFE9CF),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFAC5C31),
      body: GestureDetector(
        onTap: () => _navigateToHome(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient matching landing_page.png terracotta to cream
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFAB5C31), // Terracotta top
                    Color(0xFFE59866),
                    Color(0xFFFFE8D6), // Soft cream bottom
                  ],
                ),
              ),
            ),

            // Landing Image
            Center(
              child: Image.asset(
                'assets/decor/landing_page.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if decor subfolder path has any issue
                  return Image.asset(
                    'assets/landing_page.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  );
                },
              )
                  .animate()
                  .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                  .scale(
                    begin: const Offset(1.02, 1.02),
                    end: const Offset(1.0, 1.0),
                    duration: 500.ms,
                  ),
            ),

            // Bottom Progress Bar & Tap to Skip indicator
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Smooth loading bar for 3 seconds
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.black.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF7A1F1F),
                          ),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Entering Anubhav...',
                            style: TextStyle(
                              color: Color(0xFF7A1F1F),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _navigateToHome(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Skip ›',
                                style: TextStyle(
                                  color: Color(0xFF7A1F1F),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
