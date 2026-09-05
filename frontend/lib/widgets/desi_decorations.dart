import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Faint tiled jali/lotus lattice behind FULL screens only (home, setup,
/// onboarding). The asset is pre-baked to ~8% opacity so text stays readable.
///
/// Do NOT use behind data-dense screens (live dashboard, session detail,
/// twin) — those stay flat cream for readability.
class DesiPatternBackground extends StatelessWidget {
  final Widget child;
  final Color baseColor;

  const DesiPatternBackground({
    super.key,
    required this.child,
    this.baseColor = AnubhavColors.bgCream,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: baseColor,
        image: const DecorationImage(
          image: AssetImage('assets/decor/jali_tile_watermark.png'),
          repeat: ImageRepeat.repeat,
        ),
      ),
      child: child,
    );
  }
}

/// Sunburst mandala peeking from a screen corner — ONCE per screen at most
/// (e.g. behind the home header), partially offscreen, low opacity.
/// Never repeat per-card.
class MandalaCorner extends StatelessWidget {
  final double size;
  final double opacity;

  const MandalaCorner({super.key, this.size = 200, this.opacity = 0.15});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Image.asset(
        'assets/decor/mandala_motif.png',
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}

/// Deprecated divider strip — replaced with clean spacing.
/// Always returns SizedBox.shrink() so the orange border photo is removed from everywhere.
class FlowerDivider extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry padding;

  const FlowerDivider({
    super.key,
    this.height = 10,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Rotating sunburst mandala loader from desi_theme_kit.
/// Replaces standard spinners/circular progress indicators across the application.
class MandalaSpinner extends StatefulWidget {
  final double size;
  final Duration duration;
  final Color? color;

  const MandalaSpinner({
    super.key,
    this.size = 48,
    this.duration = const Duration(seconds: 4),
    this.color,
  });

  @override
  State<MandalaSpinner> createState() => _MandalaSpinnerState();
}

class _MandalaSpinnerState extends State<MandalaSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      'assets/decor/mandala_motif.png',
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: widget.color ?? AnubhavColors.orange,
        ),
      ),
    );

    if (widget.color != null) {
      image = ColorFiltered(
        colorFilter: ColorFilter.mode(widget.color!, BlendMode.srcIn),
        child: image,
      );
    }

    return RotationTransition(
      turns: _controller,
      child: image,
    );
  }
}

/// Full-screen or centered card loading state with rotating mandala and optional text
class MandalaLoadingScreen extends StatelessWidget {
  final String? message;
  final double size;

  const MandalaLoadingScreen({
    super.key,
    this.message,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MandalaSpinner(size: size),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: AnubhavTextStyles.bodyMedium.copyWith(
                color: AnubhavColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
