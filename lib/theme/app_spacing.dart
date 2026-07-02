import 'package:flutter/material.dart';

/// Design token spacing scale. Use these everywhere instead of raw doubles.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Design token border-radius scale.
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double full = 100;
}

/// Semantic colour palette constants used across the app.
/// These are fixed colours, independent of the user-selected accent.
class AppColors {
  AppColors._();

  // Scan type & semantic
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  // Dark mode surface hierarchy
  static const Color darkBase     = Color(0xFF090C12);
  static const Color darkSurface  = Color(0xFF10141C);
  static const Color darkCard     = Color(0xFF161B26);
  static const Color darkElevated = Color(0xFF1C2232);

  // Light mode surfaces
  static const Color lightBase    = Color(0xFFF4F5F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard    = Color(0xFFFFFFFF);

  // Neutral grays
  static const Color gray50  = Color(0xFFF8FAFC);
  static const Color gray100 = Color(0xFFF1F5F9);
  static const Color gray200 = Color(0xFFE2E8F0);
  static const Color gray300 = Color(0xFFCBD5E1);
  static const Color gray400 = Color(0xFF94A3B8);
  static const Color gray500 = Color(0xFF64748B);
  static const Color gray600 = Color(0xFF475569);
  static const Color gray700 = Color(0xFF334155);
  static const Color gray800 = Color(0xFF1E293B);
  static const Color gray900 = Color(0xFF0F172A);
}
