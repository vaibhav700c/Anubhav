import 'package:flutter/material.dart';

/// A faint, tiled jali/lotus lattice pattern for use as a full-screen
/// background watermark (already baked to ~8% opacity so text stays
/// readable on top of it). Wrap your Scaffold body in this.
///
/// Usage:
///   Scaffold(
///     body: DesiPatternBackground(
///       child: YourScreenContent(),
///     ),
///   )
class DesiPatternBackground extends StatelessWidget {
  final Widget child;
  final Color baseColor;

  const DesiPatternBackground({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFF5E6C8),
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

/// The sunburst mandala motif, meant to peek in from a screen corner —
/// e.g. behind the header on a home/onboarding screen. Use sparingly,
/// once per screen at most, and keep it low-opacity or partially offscreen
/// so it reads as texture, not clutter.
///
/// Usage:
///   Stack(
///     children: [
///       Positioned(top: -60, right: -60, child: MandalaCorner(size: 220)),
///       YourContent(),
///     ],
///   )
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
      ),
    );
  }
}

/// The marigold-garland/kalash divider strip from the deck's slide
/// headers — drop it under a title or above a footer as an ornamental
/// rule instead of a plain Divider().
///
/// Usage:
///   Column(
///     children: [
///       Text('Your Speaking Journey', style: ...),
///       FlowerDivider(),
///       ...
///     ],
///   )
class FlowerDivider extends StatelessWidget {
  final double height;

  const FlowerDivider({super.key, this.height = 10});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Image.asset(
        'assets/decor/flower_divider.png',
        height: height,
        fit: BoxFit.fitWidth,
        width: double.infinity,
      ),
    );
  }
}
