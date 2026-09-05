import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Emotion → Color & Emoji Map (Unified 6 fixed labels + client tokens) ───
class EmotionMeta {
  final String label;
  final String emoji;
  final Color color;
  final Color softBackground;

  const EmotionMeta({
    required this.label,
    required this.emoji,
    required this.color,
    required this.softBackground,
  });
}

const Map<String, EmotionMeta> emotionMetaMap = {
  'confident': EmotionMeta(
    label: 'Confident',
    emoji: '🙂',
    color: Color(0xFF10B981), // Emerald green
    softBackground: Color(0xFFE8F8F0),
  ),
  'nervous': EmotionMeta(
    label: 'Nervous',
    emoji: '😰',
    color: Color(0xFFF59E0B), // Amber
    softBackground: Color(0xFFFEF3C7),
  ),
  'bored': EmotionMeta(
    label: 'Bored',
    emoji: '😴',
    color: Color(0xFF64748B), // Slate
    softBackground: Color(0xFFF1F5F9),
  ),
  'excited': EmotionMeta(
    label: 'Excited',
    emoji: '🤩',
    color: Color(0xFFEA580C), // Orange
    softBackground: Color(0xFFFFEDD5),
  ),
  'monotone': EmotionMeta(
    label: 'Monotone',
    emoji: '😐',
    color: Color(0xFF8B5CF6), // Purple
    softBackground: Color(0xFFF5F3FF),
  ),
  'calm': EmotionMeta(
    label: 'Calm',
    emoji: '😌',
    color: Color(0xFF0284C7), // Light blue
    softBackground: Color(0xFFE0F2FE),
  ),
  'neutral': EmotionMeta(
    label: 'Neutral',
    emoji: '😐',
    color: Color(0xFF0D9488), // Teal
    softBackground: Color(0xFFCCFBF1),
  ),
};

EmotionMeta getEmotionMeta(String? emotion) {
  final key = (emotion ?? 'calm').toLowerCase();
  return emotionMetaMap[key] ?? emotionMetaMap['neutral']!;
}

Color emotionColor(String? emotion) => getEmotionMeta(emotion).color;

// ─── Score Color Coding ─────────────────────────────────────────────────────
Color scoreColor(num score) {
  if (score >= 80) return const Color(0xFF1F5B5B); // Brand Deep Teal for mastery
  if (score >= 65) return const Color(0xFF0284C7); // Solid Blue
  if (score >= 50) return const Color(0xFFE8703A); // Brand Orange
  return const Color(0xFFEF4444); // Red
}

// ─── Design System Colors ───────────────────────────────────────────────────
class AnubhavColors {
  AnubhavColors._();

  // Primary & Highlight Brand Accents
  static const Color teal = Color(0xFF1F5B5B); // Deep teal (Primary action / "Next")
  static const Color tealLight = Color(0xFF2C7A7A);
  static const Color tealSurface = Color(0xFFEBF4F4);
  static const Color orange = Color(0xFFE8703A); // Warm orange / coral (Hero CTA / "Get Started")
  static const Color orangeLight = Color(0xFFF28B59);
  static const Color orangeSurface = Color(0xFFFDF0E9);

  // Positive & Negative Data
  static const Color positive = Color(0xFF10B981); // Helped (Green)
  static const Color positiveBlue = Color(0xFF0284C7); // Helped metric (Blue)
  static const Color negative = Color(0xFFE85D3A); // Hurt (Orange-red)
  static const Color negativeRed = Color(0xFFEF4444);

  // Backgrounds & Gradients
  static const Color bgCream = Color(0xFFFDFBF7);
  static const Color bgWarmPeach = Color(0xFFFBF4ED);
  static const Color bgCoolBlue = Color(0xFFF1F6FC);
  static const Color cardBg = Colors.white;
  static const Color cardBorder = Color(0xFFEFE8DE);
  static const Color cardBorderSubtle = Color(0xFFF5EFE7);

  // Text Hierarchy
  static const Color textPrimary = Color(0xFF1E293B); // Slate-800
  static const Color textSecondary = Color(0xFF64748B); // Slate-500
  static const Color textTertiary = Color(0xFF94A3B8); // Slate-400
  static const Color textInverse = Colors.white;

  // Status & Utility
  static const Color divider = Color(0xFFF1ECE4);
}

// ─── Gradient Presets ───────────────────────────────────────────────────────
class AnubhavGradients {
  AnubhavGradients._();

  // Warmer tan/peach base (Setup / VR / History / Home)
  static const LinearGradient warmBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFF7F0),
      Color(0xFFFCF2EA),
      Color(0xFFF7EBE1),
    ],
  );

  // Cooler cream-to-blue gradient (Onboarding / Session / XAI / Twin)
  static const LinearGradient coolBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFDFBF7),
      Color(0xFFF3F7FC),
      Color(0xFFEBF2FA),
    ],
  );

  // Subtle card highlight
  static const LinearGradient cardTealHighlight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1F5B5B),
      Color(0xFF174747),
    ],
  );

  static const LinearGradient cardOrangeHighlight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF07E4A),
      Color(0xFFE8703A),
    ],
  );
}

// ─── Typography (Bold rounded sans-serif + clean body) ──────────────────────
class AnubhavTextStyles {
  AnubhavTextStyles._();

  static TextStyle displayScore = GoogleFonts.outfit(
    fontSize: 56,
    fontWeight: FontWeight.w800,
    color: AnubhavColors.textPrimary,
    letterSpacing: -1.5,
  );

  static TextStyle displayLarge = GoogleFonts.outfit(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: AnubhavColors.textPrimary,
    letterSpacing: -0.8,
  );

  static TextStyle headlineLarge = GoogleFonts.outfit(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AnubhavColors.textPrimary,
    letterSpacing: -0.4,
  );

  static TextStyle headlineMedium = GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AnubhavColors.textPrimary,
  );

  static TextStyle titleLarge = GoogleFonts.outfit(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AnubhavColors.textPrimary,
  );

  static TextStyle titleMedium = GoogleFonts.outfit(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AnubhavColors.textPrimary,
  );

  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AnubhavColors.textPrimary,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AnubhavColors.textSecondary,
    height: 1.4,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AnubhavColors.textTertiary,
  );

  static TextStyle labelLarge = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.2,
  );

  static TextStyle labelMedium = GoogleFonts.outfit(
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
        primary: AnubhavColors.teal,
        secondary: AnubhavColors.orange,
        surface: AnubhavColors.cardBg,
        error: AnubhavColors.negative,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme,
      ).copyWith(
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AnubhavTextStyles.headlineMedium,
        iconTheme: const IconThemeData(color: AnubhavColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AnubhavColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AnubhavColors.cardBorder, width: 1),
        ),
      ),
      useMaterial3: true,
    );
  }
}
