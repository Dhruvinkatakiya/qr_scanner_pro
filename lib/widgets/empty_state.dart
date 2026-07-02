import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

/// An illustrated, animated empty/placeholder state used across History, Home
/// and search results.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustrated icon container
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: isDark
                    ? scheme.primary.withValues(alpha: 0.10)
                    : scheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.15),
                ),
                boxShadow: isDark ? null : AppShadows.sm(scheme.primary),
              ),
              child: Icon(icon, size: 42, color: scheme.primary),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(
                    begin: const Offset(0.7, 0.7),
                    end: const Offset(1.0, 1.0),
                    duration: 500.ms,
                    curve: Curves.elasticOut),

            const SizedBox(height: AppSpacing.lg),

            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 100.ms)
                .slideY(
                    begin: 0.05,
                    end: 0,
                    duration: 400.ms,
                    delay: 100.ms),

            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 180.ms),
            ],

            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 260.ms)
                  .slideY(
                      begin: 0.05,
                      end: 0,
                      duration: 400.ms,
                      delay: 260.ms),
            ],
          ],
        ),
      ),
    );
  }
}
