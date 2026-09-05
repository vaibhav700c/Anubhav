import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Emotion → Color Map (Unified 6 fixed labels + client tokens) ───
class EmotionMeta {
  final String label;
  final Color color;
  final Color softBackground;

  const EmotionMeta({
    required this.label,
    required this.color,
    required this.softBackground,
  });
}

const Map<String, EmotionMeta> emotionMetaMap = {
  'confident': EmotionMeta(
    label: 'Confident',
    color: Color(0xFF10B981), // Emerald green
    softBackground: Color(0xFFE8F8F0),
  ),
  'nervous': EmotionMeta(
    label: 'Nervous',
    color: Color(0xFFF59E0B), // Amber
    softBackground: Color(0xFFFEF3C7),
  ),
  'bored': EmotionMeta(
    label: 'Bored',
    color: Color(0xFF64748B), // Slate
    softBackground: Color(0xFFF1F5F9),
  ),
  'excited': EmotionMeta(
    label: 'Excited',
    color: Color(0xFFEA580C), // Orange
    softBackground: Color(0xFFFFEDD5),
  ),
  'monotone': EmotionMeta(
    label: 'Monotone',
    color: Color(0xFF8B5CF6), // Purple
    softBackground: Color(0xFFF5F3FF),
  ),
  'calm': EmotionMeta(
    label: 'Calm',
    color: Color(0xFF0284C7), // Light blue
    softBackground: Color(0xFFE0F2FE),
  ),
  'neutral': EmotionMeta(
    label: 'Neutral',
    color: Color(0xFF0D9488), // Teal
    softBackground: Color(0xFFCCFBF1),
  ),
};

EmotionMeta getEmotionMeta(String? emotion) {
  final key = (emotion ?? 'calm').toLowerCase();
  return emotionMetaMap[key] ?? emotionMetaMap['neutral']!;
}

Color emotionColor(String? emotion) => getEmotionMeta(emotion).color;

/// Delivery-confidence score (0–100) per emotion, for graphing the timeline.
/// Higher = more composed delivery. Unknown labels fall back to neutral.
double emotionValence(String? emotion) {
  switch ((emotion ?? 'neutral').toLowerCase()) {
    case 'confident':
      return 90;
    case 'excited':
      return 80;
    case 'calm':
      return 70;
    case 'neutral':
      return 60;
    case 'monotone':
      return 45;
    case 'nervous':
      return 35;
    case 'anxious':
      return 30;
    case 'bored':
      return 25;
    default:
      return 60;
  }
}

// ─── Score Color Coding ─────────────────────────────────────────────────────
Color scoreColor(num score) {
  if (score >= 80) return const Color(0xFF7A1F1F); // Maroon for mastery (desi theme)
  if (score >= 65) return AnubhavColors.darkGreen; // Dark green status ring
  if (score >= 50) return const Color(0xFFE16533); // Burnt orange
  return const Color(0xFFEF4444); // Red
}

// ─── Desi Palette (exact deck colors) ───────────────────────────────────────
class DesiColors {
  DesiColors._();

  static const Color cream = Color(0xFFF5E6C8); // base background
  static const Color maroon = Color(0xFF7A1F1F); // headings, ANUBHAV, section titles
  static const Color burntOrange = Color(0xFFE16533); // accents / CTA
  static const Color maroonDark = Color(0xFF4A1212); // pressed states, deep text
  static const Color orangeLight = Color(0xFFF3A96B); // secondary accent / chips
  static const Color darkGreen = Color(0xFF1E5631); // status rings / positive mastery
  static const Color surface = Color(0xFFFFFDF8); // cards on top of cream bg
}

// ─── Design System Colors (remapped to desi palette) ────────────────────────
// Kept the AnubhavColors names so existing screens compile unchanged —
// teal slots now resolve to maroon, orange slots to burnt orange.
class AnubhavColors {
  AnubhavColors._();

  // Primary & Highlight Brand Accents
  static const Color teal = Color(0xFF7A1F1F); // → maroon (primary / headings)
  static const Color tealLight = Color(0xFF9A2B2B);
  static const Color tealSurface = Color(0xFFEADBC0); // maroon-tinted cream chip
  static const Color orange = Color(0xFFE16533); // → burnt orange (CTA / accents)
  static const Color orangeLight = Color(0xFFF3A96B);
  static const Color orangeSurface = Color(0xFFFBE9D9);
  static const Color darkGreen = Color(0xFF1E5631); // Status rings & positive indicators

  // Positive & Negative Data (unchanged — chart readability on cream)
  static const Color positive = Color(0xFF10B981); // Helped (Green)
  static const Color positiveBlue = Color(0xFF0284C7); // Helped metric (Blue)
  static const Color negative = Color(0xFFE85D3A); // Hurt (Orange-red)
  static const Color negativeRed = Color(0xFFEF4444);

  // Backgrounds
  static const Color bgCream = Color(0xFFF5E6C8);
  static const Color bgWarmPeach = Color(0xFFF0D9B5);
  static const Color bgCoolBlue = Color(0xFFF5E6C8); // no blue tint in desi theme
  static const Color cardBg = Color(0xFFFFFDF8);
  // Borders removed — cards sit borderless on cream, separated by shadow.
  static const Color cardBorder = Colors.transparent;
  static const Color cardBorderSubtle = Colors.transparent;

  // Text Hierarchy (maroon headings, warm-brown body for cream readability)
  static const Color textPrimary = Color(0xFF3A2E2E);
  static const Color textSecondary = Color(0xFF7A6E6E);
  static const Color textTertiary = Color(0xFFA89880);
  static const Color textInverse = Colors.white;

  // Headings always maroon
  static const Color heading = Color(0xFF7A1F1F);
  static const Color headingDeep = Color(0xFF4A1212);

  // Status & Utility (no visible rules — spacing separates content)
  static const Color divider = Colors.transparent;
}

// ─── Gradient Presets (all cream-based — no blue/grey washes) ───────────────
class AnubhavGradients {
  AnubhavGradients._();

  // Warm cream base (Setup / VR / History / Home)
  static const LinearGradient warmBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF5E6C8),
      Color(0xFFF8ECD4),
      Color(0xFFF3DFBC),
    ],
  );

  // Same cream family (Onboarding / Session / XAI / Twin) — kept as separate
  // name so call sites don't change, but no cool-blue tint in desi theme.
  static const LinearGradient coolBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF5E6C8),
      Color(0xFFFBF1DC),
      Color(0xFFF6E3C2),
    ],
  );

  // Maroon card highlight (was teal)
  static const LinearGradient cardTealHighlight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF7A1F1F),
      Color(0xFF4A1212),
    ],
  );

  static const LinearGradient cardOrangeHighlight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE8834F),
      Color(0xFFE16533),
    ],
  );
}

// ─── Typography (Fraunces serif headings + Manrope body) ────────────────────
// "Le Jour Serif" from the deck is paid — Fraunces is the closest free match.
class AnubhavTextStyles {
  AnubhavTextStyles._();

  static TextStyle displayScore = GoogleFonts.fraunces(
    fontSize: 56,
    fontWeight: FontWeight.w600,
    color: AnubhavColors.heading,
    letterSpacing: -1.0,
  );

  static TextStyle displayLarge = GoogleFonts.fraunces(
    fontSize: 34,
    fontWeight: FontWeight.w600,
    color: AnubhavColors.heading,
    letterSpacing: -0.5,
  );

  static TextStyle headlineLarge = GoogleFonts.fraunces(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    color: AnubhavColors.heading,
    letterSpacing: -0.2,
  );

  static TextStyle headlineMedium = GoogleFonts.fraunces(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AnubhavColors.heading,
  );

  static TextStyle titleLarge = GoogleFonts.fraunces(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AnubhavColors.heading,
  );

  static TextStyle titleMedium = GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AnubhavColors.headingDeep,
  );

  static TextStyle bodyLarge = GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AnubhavColors.textPrimary,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AnubhavColors.textSecondary,
    height: 1.4,
  );

  static TextStyle bodySmall = GoogleFonts.manrope(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AnubhavColors.textSecondary,
  );

  static TextStyle labelLarge = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.2,
  );

  static TextStyle labelMedium = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AnubhavColors.textSecondary,
  );
}

// ─── App Theme ──────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AnubhavColors.bgCream,
      colorScheme: const ColorScheme.light(
        primary: AnubhavColors.orange,
        secondary: AnubhavColors.teal,
        surface: AnubhavColors.cardBg,
        error: AnubhavColors.negative,
      ),
      textTheme: TextTheme(
        displayLarge: AnubhavTextStyles.displayLarge,
        headlineLarge: AnubhavTextStyles.headlineLarge,
        headlineMedium: AnubhavTextStyles.headlineMedium,
        titleLarge: AnubhavTextStyles.titleLarge,
        titleMedium: AnubhavTextStyles.titleMedium,
        bodyLarge: AnubhavTextStyles.bodyLarge,
        bodyMedium: AnubhavTextStyles.bodyMedium,
        bodySmall: AnubhavTextStyles.bodySmall,
        labelLarge: AnubhavTextStyles.labelLarge,
        labelMedium: AnubhavTextStyles.labelMedium,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AnubhavColors.bgCream,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AnubhavTextStyles.headlineMedium,
        iconTheme: const IconThemeData(color: AnubhavColors.heading),
      ),
      cardTheme: const CardThemeData(
        color: AnubhavColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AnubhavColors.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AnubhavColors.cardBg,
        selectedColor: AnubhavColors.orange,
        side: BorderSide.none,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AnubhavColors.orange : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AnubhavColors.orange.withValues(alpha: 0.4)
              : null,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AnubhavColors.teal,
      ),
      useMaterial3: true,
    );
  }
}
