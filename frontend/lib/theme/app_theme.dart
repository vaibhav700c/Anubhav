import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Emotion → Color map (single source of truth used app-wide) ────────────
const Map<String, Color> emotionColors = {
  'confident': Color(0xFF22C55E),  // green-500
  'nervous': Color(0xFFF59E0B),    // amber-500
  'anxious': Color(0xFFEF4444),    // red-500
  'neutral': Color(0xFF6366F1),    // indigo-500
  'excited': Color(0xFF3B82F6),    // blue-500
  'calm': Color(0xFF14B8A6),       // teal-500
  'confused': Color(0xFFEC4899),   // pink-500
};

Color emotionColor(String? emotion) =>
    emotionColors[emotion?.toLowerCase()] ?? const Color(0xFF6366F1);

// ─── Score band colors ─────────────────────────────────────────────────────
Color scoreColor(num score) {
  if (score >= 80) return const Color(0xFF22C55E);
  if (score >= 60) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}

// ─── Palette ───────────────────────────────────────────────────────────────
class AnubhavColors {
  AnubhavColors._();

  // Backgrounds
  static const Color background = Color(0xFF0D0F1A);
  static const Color surface = Color(0xFF161929);
  static const Color surfaceVariant = Color(0xFF1E2235);
  static const Color cardBorder = Color(0xFF2A2F4A);

  // Accent
  static const Color accent = Color(0xFF7C3AED);       // electric violet
  static const Color accentLight = Color(0xFF9D5BF5);
  static const Color accentDim = Color(0xFF3D1F7A);

  // Text
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF475569);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Chart grid
  static const Color chartGrid = Color(0xFF1E2235);
}

// ─── Text styles ───────────────────────────────────────────────────────────
class AnubhavTextStyles {
  AnubhavTextStyles._();

  static TextStyle displayLarge = GoogleFonts.outfit(
    fontSize: 72, fontWeight: FontWeight.w800,
    color: AnubhavColors.textPrimary, letterSpacing: -2,
  );

  static TextStyle displayMedium = GoogleFonts.outfit(
    fontSize: 48, fontWeight: FontWeight.w700,
    color: AnubhavColors.textPrimary, letterSpacing: -1.5,
  );

  static TextStyle headlineLarge = GoogleFonts.outfit(
    fontSize: 28, fontWeight: FontWeight.w700,
    color: AnubhavColors.textPrimary,
  );

  static TextStyle headlineMedium = GoogleFonts.outfit(
    fontSize: 22, fontWeight: FontWeight.w600,
    color: AnubhavColors.textPrimary,
  );

  static TextStyle titleMedium = GoogleFonts.outfit(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: AnubhavColors.textPrimary,
  );

  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w400,
    color: AnubhavColors.textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AnubhavColors.textSecondary,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AnubhavColors.textTertiary,
  );

  static TextStyle labelLarge = GoogleFonts.outfit(
    fontSize: 13, fontWeight: FontWeight.w600,
    color: AnubhavColors.textPrimary, letterSpacing: 0.5,
  );
}

// ─── ThemeData ─────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AnubhavColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AnubhavColors.accent,
        secondary: AnubhavColors.accentLight,
        surface: AnubhavColors.surface,
        error: AnubhavColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: AnubhavTextStyles.displayLarge,
        displayMedium: AnubhavTextStyles.displayMedium,
        headlineLarge: AnubhavTextStyles.headlineLarge,
        headlineMedium: AnubhavTextStyles.headlineMedium,
        titleMedium: AnubhavTextStyles.titleMedium,
        bodyLarge: AnubhavTextStyles.bodyLarge,
        bodyMedium: AnubhavTextStyles.bodyMedium,
        bodySmall: AnubhavTextStyles.bodySmall,
        labelLarge: AnubhavTextStyles.labelLarge,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AnubhavColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AnubhavTextStyles.headlineMedium,
        iconTheme: const IconThemeData(color: AnubhavColors.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AnubhavColors.surface,
        selectedItemColor: AnubhavColors.accent,
        unselectedItemColor: AnubhavColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AnubhavColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AnubhavColors.cardBorder, width: 1),
        ),
      ),
      dividerColor: AnubhavColors.cardBorder,
      useMaterial3: true,
    );
  }
}
