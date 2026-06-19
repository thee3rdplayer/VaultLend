import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// -------------------- Colour palette --------------------
class VaultColors {
  // Background layers
  static const voidBlack   = Color(0xFF080010);
  static const surface     = Color(0xFF110020);
  static const card        = Color(0xFF180030);
  static const divider     = Color(0xFF2A0050);

  // Neon primaries
  static const neonPurple  = Color(0xFFC44DFF);
  static const neonPink    = Color(0xFFFF2D78);
  static const neonTeal    = Color(0xFF00F5D4);

  // Glow variants (used for BoxShadow)
  static const glowPurple  = Color(0x55C44DFF);
  static const glowPink    = Color(0x55FF2D78);
  static const glowTeal    = Color(0x5500F5D4);

  // Text hierarchy
  static const textPrimary   = Color(0xFFF0E6FF);
  static const textSecondary = Color(0xFF9B7FBB);
  static const textDim       = Color(0xFF5A4070);

  // Semantic (credit = teal, debit = pink)
  static const credit = neonTeal;
  static const debit  = neonPink;
}

// -------------------- Glow helpers --------------------
List<BoxShadow> neonGlow(Color color,
        {double spread = 8, double blur = 20}) =>
    [
      BoxShadow(
          color: color.withValues(alpha: 0.6),
          blurRadius: blur * 0.4,
          spreadRadius: spread * 0.2),
      BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: blur,
          spreadRadius: spread * 0.1),
      BoxShadow(
          color: color.withValues(alpha: 0.15), blurRadius: blur * 2),
    ];

BoxDecoration neonCard(
        {Color borderColor = VaultColors.neonPurple,
        double borderWidth = 1}) =>
    BoxDecoration(
      color: VaultColors.card,
      borderRadius: BorderRadius.circular(12),
      border:
          Border.all(color: borderColor.withValues(alpha: 0.5), width: borderWidth),
      boxShadow: neonGlow(borderColor, spread: 0, blur: 12),
    );

// -------------------- Typography --------------------
class VaultFonts {
  // Display / headings: Exo 2, geometric sci‑fi
  static TextStyle exo(double size,
          {FontWeight weight = FontWeight.w600,
          Color color = VaultColors.textPrimary}) =>
      GoogleFonts.exo2(
          fontSize: size, fontWeight: weight, color: color, letterSpacing: 0.5);

  // Data labels / numbers: Rajdhani, monospace‑feel
  static TextStyle raj(double size,
          {FontWeight weight = FontWeight.w500,
          Color color = VaultColors.textPrimary}) =>
      GoogleFonts.rajdhani(
          fontSize: size,
          fontWeight: weight,
          color: color,
          letterSpacing: 1.2);

  // Body text
  static TextStyle body(double size,
          {Color color = VaultColors.textSecondary}) =>
      GoogleFonts.exo2(
          fontSize: size,
          fontWeight: FontWeight.w400,
          color: color,
          letterSpacing: 0.3);
}

// -------------------- Full ThemeData --------------------
ThemeData vaultLendTheme() {
  final base = ThemeData.dark();
  return base.copyWith(
    scaffoldBackgroundColor: VaultColors.voidBlack,
    colorScheme: const ColorScheme.dark(
      surface: VaultColors.surface,
      primary: VaultColors.neonPurple,
      secondary: VaultColors.neonPink,
      onSurface: VaultColors.textPrimary,
      onPrimary: VaultColors.voidBlack,
      error: VaultColors.neonPink,
    ),
    // Text theme built on Exo 2 with custom sizes
    textTheme: GoogleFonts.exo2TextTheme(base.textTheme).copyWith(
      displayLarge: VaultFonts.exo(32, weight: FontWeight.w700),
      displayMedium: VaultFonts.exo(26, weight: FontWeight.w700),
      titleLarge: VaultFonts.exo(20, weight: FontWeight.w600),
      titleMedium: VaultFonts.exo(16, weight: FontWeight.w600),
      bodyLarge: VaultFonts.body(15),
      bodyMedium: VaultFonts.body(13),
      labelLarge: VaultFonts.raj(14, weight: FontWeight.w600),
      labelMedium: VaultFonts.raj(12),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: VaultColors.voidBlack,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: VaultColors.neonPurple),
    ),
    cardTheme: CardThemeData(
      color: VaultColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: VaultColors.neonPurple.withValues(alpha: 0.2)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: VaultColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0x44C44DFF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0x33C44DFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: VaultColors.neonPurple, width: 1.5),
      ),
      labelStyle: VaultFonts.body(13, color: VaultColors.textSecondary),
      hintStyle: VaultFonts.body(13, color: VaultColors.textDim),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: VaultColors.neonPurple,
        foregroundColor: VaultColors.voidBlack,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: VaultFonts.exo(14,
            weight: FontWeight.w700, color: VaultColors.voidBlack),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: VaultColors.neonPurple,
        textStyle: VaultFonts.exo(13,
            weight: FontWeight.w600, color: VaultColors.neonPurple),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: VaultColors.surface,
      contentTextStyle: VaultFonts.body(13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0x44C44DFF)),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: VaultColors.surface,
      selectedItemColor: VaultColors.neonPurple,
      unselectedItemColor: VaultColors.textDim,
      selectedLabelStyle: VaultFonts.raj(11, weight: FontWeight.w700),
      unselectedLabelStyle: VaultFonts.raj(11),
      showUnselectedLabels: true,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(
        color: VaultColors.divider, thickness: 1),
  );
}