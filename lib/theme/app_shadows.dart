import 'package:flutter/material.dart';

/// Layered shadow presets used throughout the premium UI.
/// Shadows are soft and diffuse, not harsh drops.
class AppShadows {
  AppShadows._();

  /// A whisper-level shadow — cards at rest.
  static List<BoxShadow> sm(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.06),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.04),
          blurRadius: 2,
          spreadRadius: 0,
          offset: const Offset(0, 1),
        ),
      ];

  /// Standard interactive card shadow.
  static List<BoxShadow> md(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.12),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.06),
          blurRadius: 6,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ];

  /// Elevated FAB / modal shadow.
  static List<BoxShadow> lg(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.22),
          blurRadius: 40,
          spreadRadius: -4,
          offset: const Offset(0, 16),
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.10),
          blurRadius: 12,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];

  /// Coloured glow ring used for the scan FAB.
  static List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.40),
          blurRadius: 32,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.20),
          blurRadius: 64,
          spreadRadius: 8,
        ),
      ];
}
