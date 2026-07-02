import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/scan_record.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../utils/formatters.dart';

/// A premium elevated card row for a scan/generated record.
/// Used on Home and History screens.
class RecordTile extends StatefulWidget {
  const RecordTile({
    super.key,
    required this.record,
    this.onTap,
    this.trailing,
  });

  final ScanRecord record;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  State<RecordTile> createState() => _RecordTileState();
}

class _RecordTileState extends State<RecordTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final type = widget.record.contentType;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B26) : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: isDark
                ? Border.all(color: Colors.white.withValues(alpha: 0.06))
                : Border.all(color: Colors.black.withValues(alpha: 0.04)),
            boxShadow: isDark ? null : AppShadows.sm(Colors.black),
          ),
          child: Row(
            children: [
              // Coloured left-accent bar
              Container(
                width: 3,
                height: 64,
                decoration: BoxDecoration(
                  color: type.color,
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(AppRadius.xl)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Type icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(type.icon, color: type.color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.record.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            type.label,
                            style: GoogleFonts.inter(
                              color: type.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '  ·  ',
                            style: TextStyle(
                                color: scheme.onSurfaceVariant
                                    .withValues(alpha: 0.4)),
                          ),
                          Flexible(
                            child: Text(
                              Formatters.relative(widget.record.createdAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: scheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          if (widget.record.isGenerated) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.auto_awesome_rounded,
                                size: 11, color: scheme.tertiary),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Trailing
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: widget.trailing ??
                    (widget.record.isFavorite
                        ? const Icon(Icons.star_rounded,
                            color: Color(0xFFF59E0B), size: 18)
                        : null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
