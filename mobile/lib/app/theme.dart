import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// LifeOS UI/UX Design System Tokens (`design/THEME_PROMPT.md` & `planning/DESIGN.md`).
/// Nordic Slate & Deep Ocean Navy (Anti-AI-Slop: Solid, Flat, Tactile, High-Contrast).
abstract final class AppColors {
  /// Global state indicating whether Dark Mode is currently active.
  /// Synchronized automatically by [LifeOSApp], [themeModeProvider], and platform brightness.
  static bool isDark = false;

  // Raw Light Mode Constants (Color Hunt Anti-Slop Theme)
  static const Color lightCanvas = Color(0xFFF9F7F7);
  static const Color lightBackground = Color(0xFFF9F7F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceMuted = Color(0xFFDBE2EF);
  static const Color lightBorder = Color(0xFFDBE2EF);
  static const Color lightPrimary = Color(0xFF3F72AF);
  static const Color lightPrimaryDark = Color(0xFF356196);
  static const Color lightPrimarySoft = Color(0xFFDBE2EF);
  static const Color lightNavy = Color(0xFF112D4E);
  static const Color lightTextPrimary = Color(0xFF112D4E);
  static const Color lightTextSecondary = Color(0xFF526D82);
  static const Color lightDivider = Color(0xFFDBE2EF);

  // Raw Dark Mode Constants (`planning/DESIGN.md` Section 2 & `02-design-brief.md` Section 3.1)
  static const Color darkCanvas = Color(0xFF0B132B);
  static const Color darkBackground = Color(0xFF0B132B);
  static const Color darkSurface = Color(0xFF111D35);
  static const Color darkSurfaceMuted = Color(0xFF203354);
  static const Color darkBorder = Color(0xFF203354);
  static const Color darkPrimary = Color(0xFF5A8FD8);
  static const Color darkPrimaryDark = Color(0xFF7BA4E2);
  static const Color darkPrimarySoft = Color(0xFF203354);
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color darkTextPrimary = Color(0xFFF9F7F7);
  static const Color darkTextSecondary = Color(0xFF8FA2B8);
  static const Color darkDivider = Color(0xFF203354);

  // Raw Semantic Colors - Light
  static const Color lightSuccess = Color(0xFF16A34A);
  static const Color lightSuccessPastel = Color(0xFFE8F8EE);
  static const Color lightWarning = Color(0xFFD97706);
  static const Color lightWarningPastel = Color(0xFFFEF3E2);
  static const Color lightError = Color(0xFFDC2626);
  static const Color lightErrorPastel = Color(0xFFFDECEC);
  static const Color lightInfo = Color(0xFF3F72AF);
  static const Color lightInfoPastel = Color(0xFFDBE2EF);

  // Raw Semantic Colors - Dark (`02-design-brief.md` Section 3.1)
  static const Color darkSuccess = Color(0xFF22C55E);
  static const Color darkSuccessPastel = Color(0xFF132E22);
  static const Color darkWarning = Color(0xFFF59E0B);
  static const Color darkWarningPastel = Color(0xFF332414);
  static const Color darkError = Color(0xFFEF4444);
  static const Color darkErrorPastel = Color(0xFF381A1A);
  static const Color darkInfo = Color(0xFF5A8FD8);
  static const Color darkInfoPastel = Color(0xFF203354);

  // Dynamic Theme-Aware Tokens
  static Color get canvas => isDark ? darkCanvas : lightCanvas;
  static Color get background => isDark ? darkBackground : lightBackground;
  static Color get surface => isDark ? darkSurface : lightSurface;
  static Color get surfaceMuted => isDark ? darkSurfaceMuted : lightSurfaceMuted;
  static Color get border => isDark ? darkBorder : lightBorder;
  static Color get primary => isDark ? darkPrimary : lightPrimary;
  static Color get primaryDark => isDark ? darkPrimaryDark : lightPrimaryDark;
  static Color get primarySoft => isDark ? darkPrimarySoft : lightPrimarySoft;
  static Color get navy => isDark ? darkNavy : lightNavy;
  static Color get textPrimary => isDark ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary => isDark ? darkTextSecondary : lightTextSecondary;
  static Color get divider => isDark ? darkDivider : lightDivider;

  static Color get success => isDark ? darkSuccess : lightSuccess;
  static Color get successPastel => isDark ? darkSuccessPastel : lightSuccessPastel;
  static Color get warning => isDark ? darkWarning : lightWarning;
  static Color get warningPastel => isDark ? darkWarningPastel : lightWarningPastel;
  static Color get error => isDark ? darkError : lightError;
  static Color get errorPastel => isDark ? darkErrorPastel : lightErrorPastel;
  static Color get info => isDark ? darkInfo : lightInfo;
  static Color get infoPastel => isDark ? darkInfoPastel : lightInfoPastel;

  // Accents & Category Pastels
  static Color get violet => isDark ? darkPrimary : lightNavy;
  static Color get violetPastel => isDark ? darkSurfaceMuted : const Color(0xFFDBE2EF);
  static Color get green => isDark ? darkSuccess : lightSuccess;
  static Color get greenPastel => isDark ? darkSuccessPastel : lightSuccessPastel;
  static Color get orange => isDark ? darkWarning : lightWarning;
  static Color get orangePastel => isDark ? darkWarningPastel : lightWarningPastel;
  static Color get pink => isDark ? const Color(0xFFF472B6) : const Color(0xFFB83280);
  static Color get pinkPastel => isDark ? const Color(0xFF38182B) : const Color(0xFFFDF2F8);
  static Color get sky => isDark ? darkPrimary : lightPrimary;
  static Color get skyPastel => isDark ? darkSurfaceMuted : const Color(0xFFDBE2EF);
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
  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors.isDark
              ? const Color(0x33000000)
              : const Color(0x0D112D4E),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];

  /// Natural FAB shadow (non-neon)
  static List<BoxShadow> get fab => [
        BoxShadow(
          color: AppColors.isDark
              ? const Color(0x66000000)
              : const Color(0x33112D4E),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// Hero navy banner shadow
  static List<BoxShadow> get hero => [
        BoxShadow(
          color: AppColors.isDark
              ? const Color(0x4D000000)
              : const Color(0x1A112D4E),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// Active chip / pill subtle shadow
  static List<BoxShadow> get activeChip => [
        BoxShadow(
          color: AppColors.isDark
              ? const Color(0x33000000)
              : const Color(0x1F112D4E),
          blurRadius: 4,
          offset: const Offset(0, 1),
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
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.lightPrimarySoft,
        onPrimaryContainer: AppColors.lightNavy,
        secondary: AppColors.lightNavy,
        onSecondary: Colors.white,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        surfaceContainerHighest: AppColors.lightSurfaceMuted,
        onSurfaceVariant: AppColors.lightTextSecondary,
        error: AppColors.lightError,
        onError: Colors.white,
        outline: AppColors.lightDivider,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: AppColors.lightTextPrimary,
        displayColor: AppColors.lightTextPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          height: 28 / 22,
          fontWeight: FontWeight.w700,
          color: AppColors.lightTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.lightPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.lightError, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: AppColors.lightTextSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
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
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.bottomSheetTop),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
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
        error: AppColors.darkError,
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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.darkError, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: AppColors.darkTextSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
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
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.bottomSheetTop),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
