import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// VR Hand-off Screen matching the approved visual specifications
class VrHandoffScreen extends StatefulWidget {
  const VrHandoffScreen({super.key});

  @override
  State<VrHandoffScreen> createState() => _VrHandoffScreenState();
}

class _VrHandoffScreenState extends State<VrHandoffScreen> {
  int _countdown = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        _navigateToLive();
      }
    });
  }

  void _navigateToLive() {
    // Forward whatever Setup passed us (topic/language/audienceSize) so the
    // Live Dashboard can pass it on to the hub when the session ends.
    final args = ModalRoute.of(context)?.settings.arguments;
    Navigator.pushReplacementNamed(context, '/live', arguments: args);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AnubhavGradients.warmBackground,
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Pulsing concentric rings with teal glow around headset icon
              SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulsing wave
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AnubhavColors.teal.withValues(alpha: 0.06),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                          begin: const Offset(0.85, 0.85),
                          end: const Offset(1.15, 1.15),
                          duration: 2200.ms,
                          curve: Curves.easeInOut,
                        ),

                    // Middle ring
                    Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AnubhavColors.teal.withValues(alpha: 0.25),
                          width: 2,
                        ),
                        color: AnubhavColors.teal.withValues(alpha: 0.08),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                          begin: const Offset(0.92, 0.92),
                          end: const Offset(1.06, 1.06),
                          duration: 1600.ms,
                          curve: Curves.easeInOut,
                        ),

                    // Central Headset Icon Circle
                    GestureDetector(
                      onTap: _navigateToLive,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: AnubhavColors.teal,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AnubhavColors.teal.withValues(alpha: 0.4),
                              blurRadius: 26,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.view_in_ar_rounded,
                            color: Colors.white,
                            size: 54,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Headlines
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      'Put on your headset now',
                      textAlign: TextAlign.center,
                      style: AnubhavTextStyles.displayLarge.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Calibration complete. Your session is loading.',
                      textAlign: TextAlign.center,
                      style: AnubhavTextStyles.bodyMedium.copyWith(
                        color: AnubhavColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Countdown Display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AnubhavColors.cardBorder),
                      ),
                      child: Text(
                        'Session starts in... $_countdown',
                        style: AnubhavTextStyles.titleMedium.copyWith(
                          color: AnubhavColors.orange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Cancel Link
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel',
                    style: AnubhavTextStyles.bodyMedium.copyWith(
                      color: AnubhavColors.textTertiary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
