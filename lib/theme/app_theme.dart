import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warm, organic palette inspired by garden-to-table aesthetics.
/// Privacy-first design: muted, trustworthy, grounded.
class AppTheme {
  // ── Core palette ──────────────────────────────────────────────
  static const Color seedGreen    = Color(0xFF4A6741);  // deep sage
  static const Color warmCream    = Color(0xFFF7F2E8);  // parchment
  static const Color terracotta   = Color(0xFFCB6843);  // warm accent
  static const Color honeyGold    = Color(0xFFD4A84B);  // highlight
  static const Color deepBrown    = Color(0xFF3B2F24);  // text / dark bg
  static const Color softSage     = Color(0xFFB8C9A3);  // secondary
  static const Color paleOlive    = Color(0xFFDDE5D0);  // surface tint
  static const Color dustyRose    = Color(0xFFC48B7A);  // "want" accent
  static const Color cloudWhite   = Color(0xFFFDFBF7);  // background

  // ── Functional colors ─────────────────────────────────────────
  static const Color wasteNotColor = seedGreen;
  static const Color wantNotColor  = terracotta;

  // ── Theme data ────────────────────────────────────────────────
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: cloudWhite,
      colorScheme: ColorScheme.light(
        primary: seedGreen,
        secondary: terracotta,
        tertiary: honeyGold,
        surface: warmCream,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: deepBrown,
        outline: softSage,
      ),
      textTheme: _textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: deepBrown,
        ),
        iconTheme: const IconThemeData(color: deepBrown),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: warmCream,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: seedGreen, width: 2),
        ),
        hintStyle: GoogleFonts.dmSans(
          color: deepBrown.withOpacity(0.4),
          fontSize: 15,
        ),
      ),
      cardTheme: CardThemeData(
        color: warmCream,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: paleOlive,
        selectedColor: seedGreen,
        labelStyle: GoogleFonts.dmSans(fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  static TextTheme get _textTheme {
    return TextTheme(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 42,
        fontWeight: FontWeight.w800,
        color: deepBrown,
        letterSpacing: -1,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: deepBrown,
      ),
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: deepBrown,
      ),
      headlineMedium: GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: deepBrown,
      ),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: deepBrown,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: deepBrown,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: deepBrown,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: deepBrown,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: deepBrown,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: deepBrown.withOpacity(0.6),
        letterSpacing: 0.5,
      ),
    );
  }
}
