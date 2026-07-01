import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Dimmed overlay with a centered, rounded scan window, corner brackets and an
/// animated sweeping line — the familiar "aim here" affordance.
class ScannerFrameOverlay extends StatefulWidget {
  const ScannerFrameOverlay({super.key});

  @override
  State<ScannerFrameOverlay> createState() => _ScannerFrameOverlayState();
}

class _ScannerFrameOverlayState extends State<ScannerFrameOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth * 0.72;
        final rect = Rect.fromCenter(
          center: Offset(constraints.maxWidth / 2, constraints.maxHeight * 0.42),
          width: side,
          height: side,
        );
        return Stack(
          children: [
            // Dim mask with a transparent window cut out.
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _MaskPainter(rect: rect, accent: accent),
            ),
            // Animated sweep line inside the window.
            AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                return Positioned(
                  left: rect.left + 12,
                  width: rect.width - 24,
                  top: rect.top + 12 + (rect.height - 24) * _anim.value,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        accent.withValues(alpha: 0),
                        accent,
                        accent.withValues(alpha: 0),
                      ]),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: rect.bottom + 24,
              left: 24,
              right: 24,
              child: Text(
                'scan.align'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MaskPainter extends CustomPainter {
  _MaskPainter({required this.rect, required this.accent});
  final Rect rect;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = Radius.circular(24);
    final rrect = RRect.fromRectAndRadius(rect, radius);

    // Dim everything, then punch out the window.
    final overlay = Path()..addRect(Offset.zero & size);
    final hole = Path()..addRRect(rrect);
    final masked = Path.combine(PathOperation.difference, overlay, hole);
    canvas.drawPath(masked, Paint()..color = Colors.black.withValues(alpha: 0.6));

    // Corner brackets.
    final bracket = Paint()
      ..color = accent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const len = 28.0;
    void corner(Offset o, Offset hDir, Offset vDir) {
      canvas.drawLine(o, o + hDir * len, bracket);
      canvas.drawLine(o, o + vDir * len, bracket);
    }

    corner(rect.topLeft + const Offset(6, 6),
        const Offset(1, 0), const Offset(0, 1));
    corner(rect.topRight + const Offset(-6, 6),
        const Offset(-1, 0), const Offset(0, 1));
    corner(rect.bottomLeft + const Offset(6, -6),
        const Offset(1, 0), const Offset(0, -1));
    corner(rect.bottomRight + const Offset(-6, -6),
        const Offset(-1, 0), const Offset(0, -1));
  }

  @override
  bool shouldRepaint(covariant _MaskPainter oldDelegate) =>
      oldDelegate.rect != rect || oldDelegate.accent != accent;
}
