import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colors pulled directly from the Kaala Teeka deck's XML (not eyeballed —
/// these are the exact srgbClr values used across its slides).
class DesiColors {
  static const cream = Color(0xFFF5E6C8); // base background
  static const maroon = Color(0xFF7A1F1F); // headings, primary text, icons
  static const burntOrange = Color(0xFFE16533); // accent / CTA
  // Supporting tones (not in the deck's flat palette, but needed for a UI):
  static const maroonDark = Color(0xFF4A1212); // pressed states, deep text
  static const orangeLight = Color(0xFFF3A96B); // secondary accent / chips
  static const surface = Color(0xFFFFFDF8); // cards on top of cream bg
}

/// "Le Jour Serif" (used for ANUBHAV / headings in the deck) is a paid
/// font not on Google Fonts. Fraunces is the closest free match: a
/// high-contrast serif with the same editorial/Didone feel.
class AppTheme {
  static TextTheme get _textTheme => TextTheme(
        displayLarge: GoogleFonts.fraunces(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: DesiColors.maroon,
          letterSpacing: 0.5,
        ),
        headlineMedium: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: DesiColors.maroon,
        ),
        titleMedium: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: DesiColors.maroonDark,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF3A2E2E),
        ),
        bodySmall: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF7A6E6E),
        ),
      );

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: DesiColors.cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: DesiColors.burntOrange,
          primary: DesiColors.burntOrange,
          secondary: DesiColors.maroon,
          surface: DesiColors.surface,
        ),
        textTheme: _textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: DesiColors.cream,
          elevation: 0,
          titleTextStyle: _textTheme.headlineMedium,
          iconTheme: const IconThemeData(color: DesiColors.maroon),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: DesiColors.burntOrange,
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
        cardTheme: CardThemeData(
          color: DesiColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
}
