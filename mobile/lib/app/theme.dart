import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// LifeOS UI/UX Design System Tokens (`DESIGN.md`).
abstract final class AppColors {
  // Brand & Neutrals (Light Mode)
  static const Color primary = Color(0xFF5B5BF6);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color primarySoft = Color(0xFFECEBFF);
  static const Color background = Color(0xFFF4F5FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F2F8);
  static const Color navy = Color(0xFF1E2140);
  static const Color textPrimary = Color(0xFF151833);
  static const Color textSecondary = Color(0xFF8A8FA8);
  static const Color divider = Color(0xFFEEF0F6);

  // Dark Mode Neutrals
  static const Color darkBackground = Color(0xFF0F1124);
  static const Color darkSurface = Color(0xFF1A1D35);
  static const Color darkSurfaceMuted = Color(0xFF24284A);
  static const Color darkTextPrimary = Color(0xFFF4F5FC);
  static const Color darkTextSecondary = Color(0xFF9CA0BC);
  static const Color darkPrimary = Color(0xFF7C7CFF);

  // Semantic Colors (Solid + Pastel Background Pair)
  static const Color success = Color(0xFF22C55E);
  static const Color successPastel = Color(0xFFE8F8EE);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningPastel = Color(0xFFFEF3E2);
  static const Color error = Color(0xFFEF4444);
  static const Color errorPastel = Color(0xFFFDECEC);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoPastel = Color(0xFFE8F0FE);

  // Category / Accent Pastels
  static const Color violet = Color(0xFF8B5CF6);
  static const Color violetPastel = Color(0xFFF1ECFE);
  static const Color green = Color(0xFF10B981);
  static const Color greenPastel = Color(0xFFE6F7F1);
  static const Color orange = Color(0xFFF97316);
  static const Color orangePastel = Color(0xFFFEF0E6);
  static const Color pink = Color(0xFFEC4899);
  static const Color pinkPastel = Color(0xFFFDEBF4);
  static const Color sky = Color(0xFF0EA5E9);
  static const Color skyPastel = Color(0xFFE6F5FC);
}

abstract final class AppRadius {
  static const double cardLarge = 20.0;
  static const double cardSmall = 16.0;
  static const double iconTile = 14.0;
  static const double input = 14.0;
  static const double bottomNavTop = 24.0;
  static const double bottomSheetTop = 28.0;
  static const double pill = 999.0;
}

/// Elevation & Shadow tokens (`DESIGN.md` Section 4).
abstract final class AppShadows {
  /// Soft card shadow: 0 4px 16px rgba(91, 91, 246, 0.06)
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0F5B5BF6),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  /// Center FAB shadow: 0 6px 16px rgba(91, 91, 246, 0.35)
  static const List<BoxShadow> fab = [
    BoxShadow(
      color: Color(0x595B5BF6),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  /// Hero navy banner shadow
  static const List<BoxShadow> hero = [
    BoxShadow(
      color: Color(0x2E1E2140),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  /// Elevated pill / active chip shadow
  static const List<BoxShadow> activeChip = [
    BoxShadow(
      color: Color(0x405B5BF6),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}

/// Typography tokens (`DESIGN.md` Section 3).
/// Font Family: Plus Jakarta Sans for everything.
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
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.violet,
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
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
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
        secondary: AppColors.violet,
        onSecondary: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        surfaceContainerHighest: AppColors.darkSurfaceMuted,
        onSurfaceVariant: AppColors.darkTextSecondary,
        error: AppColors.error,
        onError: Colors.white,
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
        ),
      ),
    );
  }
}
