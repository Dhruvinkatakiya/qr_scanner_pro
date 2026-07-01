import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../models/qr_style_config.dart';
import '../../widgets/pro_badge.dart';

/// The styling panel for the generator. Colours are free; gradient, dot shape
/// and centre-logo embedding are Pro and prompt an upgrade when locked.
class QrStyleEditor extends StatelessWidget {
  const QrStyleEditor({
    super.key,
    required this.style,
    required this.isPro,
    required this.onChanged,
    required this.onPickLogo,
    required this.onUpgrade,
  });

  final QrStyleConfig style;
  final bool isPro;
  final ValueChanged<QrStyleConfig> onChanged;
  final VoidCallback onPickLogo;
  final VoidCallback onUpgrade;

  void _proGuard(VoidCallback action) => isPro ? action() : onUpgrade();

  Future<void> _pickColor(
      BuildContext context, Color current, ValueChanged<Color> apply) async {
    Color temp = current;
    final result = await showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('generate.style'.tr(),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            if (!isPro) const ProBadge(),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ColorField(
                label: 'generate.foreground'.tr(),
                color: style.foregroundColor,
                onTap: () => _pickColor(context, style.foregroundColor,
                    (c) => onChanged(style.copyWith(foreground: c.toARGB32()))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ColorField(
                label: 'generate.background'.tr(),
                color: style.backgroundColor,
                onTap: () => _pickColor(context, style.backgroundColor,
                    (c) => onChanged(style.copyWith(background: c.toARGB32()))),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('generate.gradient'.tr()),
          secondary: const Icon(Icons.gradient_rounded),
          value: style.useGradient,
          onChanged: (v) =>
              _proGuard(() => onChanged(style.copyWith(useGradient: v))),
        ),
        if (style.useGradient)
          _ColorField(
            label: 'generate.gradient'.tr(),
            color: style.gradientColorValue,
            onTap: () => _proGuard(() => _pickColor(
                context,
                style.gradientColorValue,
                (c) => onChanged(style.copyWith(gradientColor: c.toARGB32())))),
          ),
        const SizedBox(height: 12),
        Text('generate.dot_style'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SegmentedButton<QrDotStyle>(
          segments: [
            ButtonSegment(
                value: QrDotStyle.square, label: Text('generate.square'.tr())),
            ButtonSegment(
                value: QrDotStyle.dots, label: Text('generate.dots'.tr())),
          ],
          selected: {
            style.dotStyle == QrDotStyle.square
                ? QrDotStyle.square
                : QrDotStyle.dots
          },
          onSelectionChanged: (s) =>
              _proGuard(() => onChanged(style.copyWith(dotStyle: s.first))),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('generate.rounded'.tr()),
          secondary: const Icon(Icons.rounded_corner_rounded),
          value: style.roundedEyes,
          onChanged: (v) =>
              _proGuard(() => onChanged(style.copyWith(roundedEyes: v))),
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.image_rounded),
          title: Text('generate.logo'.tr()),
          trailing: style.embeddedLogoPath == null
              ? TextButton(
                  onPressed: () => _proGuard(onPickLogo),
                  child: Text('generate.add_logo'.tr()))
              : TextButton(
                  onPressed: () =>
                      onChanged(style.copyWith(clearLogo: true)),
                  child: Text('generate.remove_logo'.tr())),
        ),
      ],
    );
  }
}

class _ColorField extends StatelessWidget {
  const _ColorField(
      {required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
