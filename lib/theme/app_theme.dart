import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_spacing.dart';

/// Selectable accent colours offered in Settings.
class AccentColors {
  AccentColors._();

  static const List<Color> options = [
    Color(0xFF0055FF), // Deep Blue (Logo Primary)
    Color(0xFF00E5FF), // Cyan Laser (Logo Accent)
    Color(0xFF7C5CFC), // Violet
    Color(0xFF00BFA5), // Teal
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Coral
    Color(0xFF22C55E), // Green
    Color(0xFFEC4899), // Pink
  ];

  static const Color defaultAccent = Color(0xFF0055FF);
}

/// Central Material 3 theme builder with premium typography and design tokens.
/// Both light and dark schemes are derived from the selected accent seed so the
/// whole app re-tints instantly on accent change.
class AppTheme {
  AppTheme._();

  static ThemeData light(Color seed) => _build(seed, Brightness.light);
  static ThemeData dark(Color seed) => _build(seed, Brightness.dark);

  static TextTheme _buildTextTheme(ColorScheme scheme) {
    // Manrope for display, headline, title — geometric and distinctive
    // Inter for body and label — optimised for readability at small sizes
    return TextTheme(
      // Display
      displayLarge: GoogleFonts.manrope(
          fontSize: 57, fontWeight: FontWeight.w800, letterSpacing: -1.5,
          color: scheme.onSurface),
      displayMedium: GoogleFonts.manrope(
          fontSize: 45, fontWeight: FontWeight.w700, letterSpacing: -1.0,
          color: scheme.onSurface),
      displaySmall: GoogleFonts.manrope(
          fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -0.5,
          color: scheme.onSurface),
      // Headline
      headlineLarge: GoogleFonts.manrope(
          fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5,
          color: scheme.onSurface),
      headlineMedium: GoogleFonts.manrope(
          fontSize: 28, fontWeight: FontWeight.w700,
          color: scheme.onSurface),
      headlineSmall: GoogleFonts.manrope(
          fontSize: 24, fontWeight: FontWeight.w700,
          color: scheme.onSurface),
      // Title
      titleLarge: GoogleFonts.manrope(
          fontSize: 22, fontWeight: FontWeight.w700,
          color: scheme.onSurface),
      titleMedium: GoogleFonts.manrope(
          fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.1,
          color: scheme.onSurface),
      titleSmall: GoogleFonts.manrope(
          fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1,
          color: scheme.onSurface),
      // Body — Inter
      bodyLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.15,
          color: scheme.onSurface),
      bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25,
          color: scheme.onSurface),
      bodySmall: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4,
          color: scheme.onSurfaceVariant),
      // Label — Inter
      labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1,
          color: scheme.onSurface),
      labelMedium: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5,
          color: scheme.onSurface),
      labelSmall: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5,
          color: scheme.onSurfaceVariant),
    );
  }

  static ThemeData _build(Color seed, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      // Override specific colours for a richer dark palette
      surface: isDark ? const Color(0xFF10141C) : const Color(0xFFF4F5F9),
    ).copyWith(
      // Richer card/surface hierarchy in dark mode
      surfaceContainerLowest: isDark
          ? const Color(0xFF090C12)
          : const Color(0xFFF8FAFC),
      surfaceContainer: isDark
          ? const Color(0xFF161B26)
          : const Color(0xFFFFFFFF),
      surfaceContainerHighest: isDark
          ? const Color(0xFF1C2232)
          : const Color(0xFFE8ECF4),
    );

    final textTheme = _buildTextTheme(scheme);

    final scaffoldBg =
        isDark ? const Color(0xFF090C12) : const Color(0xFFF4F5F9);
    final cardColor =
        isDark ? const Color(0xFF161B26) : const Color(0xFFFFFFFF);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBg,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
    );

    return base.copyWith(
      // -------------------------------------------------------------------------
      // AppBar
      // -------------------------------------------------------------------------
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffoldBg,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              ),
        titleTextStyle: GoogleFonts.manrope(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),

      // -------------------------------------------------------------------------
      // Cards — zero elevation, soft border in dark mode
      // -------------------------------------------------------------------------
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: isDark
              ? BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 1,
                )
              : BorderSide.none,
        ),
        margin: EdgeInsets.zero,
      ),

      // -------------------------------------------------------------------------
      // Buttons
      // -------------------------------------------------------------------------
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: GoogleFonts.manrope(
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.7)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.manrope(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // -------------------------------------------------------------------------
      // Chip
      // -------------------------------------------------------------------------
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        side: isDark
            ? BorderSide(
                color: Colors.white.withValues(alpha: 0.08), width: 1)
            : BorderSide(
                color: Colors.black.withValues(alpha: 0.06), width: 1),
        labelStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600),
      ),

      // -------------------------------------------------------------------------
      // Input
      // -------------------------------------------------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? const Color(0xFF161B26)
            : const Color(0xFFFFFFFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: scheme.primary, width: 1.8),
        ),
        hintStyle: GoogleFonts.inter(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: scheme.onSurfaceVariant,
          fontSize: 14,
        ),
      ),

      // -------------------------------------------------------------------------
      // Bottom sheet
      // -------------------------------------------------------------------------
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF10141C) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxl)),
        ),
        showDragHandle: true,
        dragHandleColor:
            scheme.onSurfaceVariant.withValues(alpha: 0.3),
      ),

      // -------------------------------------------------------------------------
      // Divider
      // -------------------------------------------------------------------------
      dividerTheme: DividerThemeData(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06),
        thickness: 1,
        space: 1,
      ),

      // -------------------------------------------------------------------------
      // ListTile
      // -------------------------------------------------------------------------
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 13,
          color: scheme.onSurfaceVariant,
        ),
      ),

      // -------------------------------------------------------------------------
      // Switch
      // -------------------------------------------------------------------------
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return isDark
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.12);
        }),
      ),

      // -------------------------------------------------------------------------
      // SnackBar
      // -------------------------------------------------------------------------
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF1C2232) : const Color(0xFF1E293B),
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      // -------------------------------------------------------------------------
      // SegmentedButton
      // -------------------------------------------------------------------------
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          textStyle: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }
}
