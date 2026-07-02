import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/qr_style_config.dart';
import '../../theme/app_spacing.dart';

/// The styling panel for the generator. All features are fully unlocked — no
/// paywall or Pro restrictions.
class QrStyleEditor extends StatelessWidget {
  const QrStyleEditor({
    super.key,
    required this.style,
    required this.onChanged,
    required this.onPickLogo,
  });

  final QrStyleConfig style;
  final ValueChanged<QrStyleConfig> onChanged;
  final VoidCallback onPickLogo;

  Future<void> _pickColor(
      BuildContext context, Color current, ValueChanged<Color> apply) async {
    Color temp = current;
    final result = await showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pick a colour',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: current,
            onColorChanged: (c) => temp = c,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('common.cancel'.tr())),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, temp),
              child: Text('common.done'.tr())),
        ],
      ),
    );
    if (result != null) apply(result);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Section title ────────────────────────────────────────────────
        Text(
          'generate.style'.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),

        // ─── Color row ────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _ColorSwatch(
                label: 'generate.foreground'.tr(),
                color: style.foregroundColor,
                onTap: () => _pickColor(
                  context,
                  style.foregroundColor,
                  (c) => onChanged(style.copyWith(foreground: c.toARGB32())),
                ),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ColorSwatch(
                label: 'generate.background'.tr(),
                color: style.backgroundColor,
                onTap: () => _pickColor(
                  context,
                  style.backgroundColor,
                  (c) => onChanged(style.copyWith(background: c.toARGB32())),
                ),
                isDark: isDark,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // ─── Gradient toggle ──────────────────────────────────────────────
        _ToggleRow(
          icon: Icons.gradient_rounded,
          title: 'generate.gradient'.tr(),
          value: style.useGradient,
          onChanged: (v) => onChanged(style.copyWith(useGradient: v)),
          isDark: isDark,
        ),

        if (style.useGradient) ...[
          const SizedBox(height: AppSpacing.sm),
          // Live gradient preview
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  style.foregroundColor,
                  style.gradientColorValue,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ColorSwatch(
            label: 'generate.gradient'.tr(),
            color: style.gradientColorValue,
            onTap: () => _pickColor(
              context,
              style.gradientColorValue,
              (c) => onChanged(style.copyWith(gradientColor: c.toARGB32())),
            ),
            isDark: isDark,
          ),
        ],

        const SizedBox(height: AppSpacing.md),

        // ─── Dot style picker ─────────────────────────────────────────────
        Text(
          'generate.dot_style'.tr(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _DotStyleOption(
                label: 'generate.square'.tr(),
                dotStyle: QrDotStyle.square,
                selected: style.dotStyle == QrDotStyle.square,
                onTap: () =>
                    onChanged(style.copyWith(dotStyle: QrDotStyle.square)),
                accentColor: scheme.primary,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _DotStyleOption(
                label: 'generate.dots'.tr(),
                dotStyle: QrDotStyle.dots,
                selected: style.dotStyle == QrDotStyle.dots,
                onTap: () =>
                    onChanged(style.copyWith(dotStyle: QrDotStyle.dots)),
                accentColor: scheme.primary,
                isDark: isDark,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // ─── Rounded eyes toggle ──────────────────────────────────────────
        _ToggleRow(
          icon: Icons.rounded_corner_rounded,
          title: 'generate.rounded'.tr(),
          value: style.roundedEyes,
          onChanged: (v) => onChanged(style.copyWith(roundedEyes: v)),
          isDark: isDark,
        ),

        const SizedBox(height: AppSpacing.md),

        // ─── Logo embed ───────────────────────────────────────────────────
        _LogoRow(
          hasLogo: style.embeddedLogoPath != null,
          onAdd: onPickLogo,
          onRemove: () => onChanged(style.copyWith(clearLogo: true)),
          isDark: isDark,
        ),
      ],
    );
  }
}

// ─── Color Swatch ─────────────────────────────────────────────────────────────

class _ColorSwatch extends StatefulWidget {
  const _ColorSwatch({
    required this.label,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  @override
  State<_ColorSwatch> createState() => _ColorSwatchState();
}

class _ColorSwatchState extends State<_ColorSwatch> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF161B26) : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              // Colour preview circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.35),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '#${widget.color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.colorize_rounded,
                size: 16,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Toggle Row ───────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B26) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 0),
          secondary: Icon(icon, color: value ? scheme.primary : scheme.onSurfaceVariant),
          title: Text(title),
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Dot Style Option ─────────────────────────────────────────────────────────

class _DotStyleOption extends StatefulWidget {
  const _DotStyleOption({
    required this.label,
    required this.dotStyle,
    required this.selected,
    required this.onTap,
    required this.accentColor,
    required this.isDark,
  });

  final String label;
  final QrDotStyle dotStyle;
  final bool selected;
  final VoidCallback onTap;
  final Color accentColor;
  final bool isDark;

  @override
  State<_DotStyleOption> createState() => _DotStyleOptionState();
}

class _DotStyleOptionState extends State<_DotStyleOption> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md, horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: widget.selected
                ? widget.accentColor.withValues(alpha: 0.12)
                : widget.isDark
                    ? const Color(0xFF161B26)
                    : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: widget.selected
                  ? widget.accentColor.withValues(alpha: 0.5)
                  : widget.isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08),
              width: widget.selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              // Mini dot preview
              SizedBox(
                width: 36,
                height: 36,
                child: CustomPaint(
                  painter: _DotPreviewPainter(
                    dotStyle: widget.dotStyle,
                    color: widget.selected
                        ? widget.accentColor
                        : widget.isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight:
                      widget.selected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.selected
                      ? widget.accentColor
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotPreviewPainter extends CustomPainter {
  const _DotPreviewPainter({required this.dotStyle, required this.color});
  final QrDotStyle dotStyle;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    const cols = 4;
    const rows = 4;
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final dotW = cellW * 0.65;
    final dotH = cellH * 0.65;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final cx = c * cellW + cellW / 2;
        final cy = r * cellH + cellH / 2;
        final rect = Rect.fromCenter(
            center: Offset(cx, cy), width: dotW, height: dotH);
        if (dotStyle == QrDotStyle.dots) {
          canvas.drawOval(rect, paint);
        } else {
          canvas.drawRRect(
              RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
              paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_DotPreviewPainter old) =>
      old.dotStyle != dotStyle || old.color != color;
}

// ─── Logo Row ─────────────────────────────────────────────────────────────────

class _LogoRow extends StatefulWidget {
  const _LogoRow({
    required this.hasLogo,
    required this.onAdd,
    required this.onRemove,
    required this.isDark,
  });

  final bool hasLogo;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final bool isDark;

  @override
  State<_LogoRow> createState() => _LogoRowState();
}

class _LogoRowState extends State<_LogoRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.hasLogo ? widget.onRemove() : widget.onAdd();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF161B26) : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.hasLogo
                      ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                      : scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  widget.hasLogo ? Icons.check_circle_rounded : Icons.image_rounded,
                  color: widget.hasLogo ? const Color(0xFF22C55E) : scheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'generate.logo'.tr(),
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      widget.hasLogo
                          ? 'Tap to remove logo'
                          : 'generate.add_logo'.tr(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                widget.hasLogo ? Icons.delete_outline_rounded : Icons.add_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
