import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// LifeOS UI/UX Design System Tokens (`design/THEME_PROMPT.md` & `planning/DESIGN.md`).
/// Nordic Slate & Deep Ocean Navy (Anti-AI-Slop: Solid, Flat, Tactile, High-Contrast).
abstract final class AppColors {
  // Brand & Neutrals (Light Mode - Color Hunt Anti-Slop Theme)
  static const Color canvas = Color(0xFFF9F7F7);
  static const Color background = Color(0xFFF9F7F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFDBE2EF);
  static const Color border = Color(0xFFDBE2EF);
  static const Color primary = Color(0xFF3F72AF);
  static const Color primaryDark = Color(0xFF356196);
  static const Color primarySoft = Color(0xFFDBE2EF);
  static const Color navy = Color(0xFF112D4E);
  static const Color textPrimary = Color(0xFF112D4E);
  static const Color textSecondary = Color(0xFF526D82);
  static const Color divider = Color(0xFFDBE2EF);

  // Dark Mode Neutrals
  static const Color darkBackground = Color(0xFF0B132B);
  static const Color darkSurface = Color(0xFF111D35);
  static const Color darkSurfaceMuted = Color(0xFF203354);
  static const Color darkBorder = Color(0xFF203354);
  static const Color darkTextPrimary = Color(0xFFF9F7F7);
  static const Color darkTextSecondary = Color(0xFF8FA2B8);
  static const Color darkPrimary = Color(0xFF5A8FD8);

  // Semantic Colors (Solid + Muted Background Pair)
  static const Color success = Color(0xFF16A34A);
  static const Color successPastel = Color(0xFFE8F8EE);
  static const Color warning = Color(0xFFD97706);
  static const Color warningPastel = Color(0xFFFEF3E2);
  static const Color error = Color(0xFFDC2626);
  static const Color errorPastel = Color(0xFFFDECEC);
  static const Color info = Color(0xFF3F72AF);
  static const Color infoPastel = Color(0xFFDBE2EF);

  // Category / Accent Pastels (Flat Solid + Tint)
  static const Color violet = Color(0xFF112D4E);
  static const Color violetPastel = Color(0xFFDBE2EF);
  static const Color green = Color(0xFF16A34A);
  static const Color greenPastel = Color(0xFFE8F8EE);
  static const Color orange = Color(0xFFD97706);
  static const Color orangePastel = Color(0xFFFEF3E2);
  static const Color pink = Color(0xFFB83280);
  static const Color pinkPastel = Color(0xFFFDF2F8);
  static const Color sky = Color(0xFF3F72AF);
  static const Color skyPastel = Color(0xFFDBE2EF);
}

abstract final class AppRadius {
  static const double cardLarge = 16.0;
  static const double cardSmall = 16.0;
  static const double iconTile = 12.0;
  static const double input = 12.0;
  static const double bottomNavTop = 20.0;
  static const double bottomSheetTop = 24.0;
  static const double pill = 999.0;
}

/// Elevation & Shadow tokens (`design/THEME_PROMPT.md` Section 5).
/// Minimal, natural, ambient shadows (Zero neon / glow).
abstract final class AppShadows {
  /// Subtle natural card ambient shadow
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0D112D4E),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  /// Natural FAB shadow (non-neon)
  static const List<BoxShadow> fab = [
    BoxShadow(
      color: Color(0x33112D4E),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Hero navy banner shadow
  static const List<BoxShadow> hero = [
    BoxShadow(
      color: Color(0x1A112D4E),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Active chip / pill subtle shadow
  static const List<BoxShadow> activeChip = [
    BoxShadow(
      color: Color(0x1F112D4E),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];
}

/// Typography tokens (`planning/DESIGN.md` Section 3).
/// Font Family: Plus Jakarta Sans for high-contrast scannability.
abstract final class AppTypography {
  /// display.hero: 32 / 38, Weight 800
  static TextStyle get displayHero => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        height: 38 / 32,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      );

  /// display.metric: 28 / 34, Weight 700
  static TextStyle get displayMetric => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        height: 34 / 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  /// headline.screen: 22 / 28, Weight 700
  static TextStyle get headlineScreen => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  /// title.section: 16 / 22, Weight 700
  static TextStyle get titleSection => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        height: 22 / 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  /// title.card: 14 / 20, Weight 600
  static TextStyle get titleCard => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// body: 13 / 18, Weight 400
  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  /// label: 12 / 16, Weight 600
  static TextStyle get label => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      );

  /// caption: 11 / 14, Weight 500
  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        height: 14 / 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );
}

abstract final class AppTheme {
  static ThemeData get light {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primarySoft,
        onPrimaryContainer: AppColors.navy,
        secondary: AppColors.navy,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceMuted,
        onSurfaceVariant: AppColors.textSecondary,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.divider,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          height: 28 / 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.bottomSheetTop),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get dark {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.dark().textTheme,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.darkSurfaceMuted,
        onPrimaryContainer: AppColors.darkTextPrimary,
        secondary: AppColors.darkPrimary,
        onSecondary: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        surfaceContainerHighest: AppColors.darkSurfaceMuted,
        onSurfaceVariant: AppColors.darkTextSecondary,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.darkBorder,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          height: 28 / 22,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
    );
  }
}
