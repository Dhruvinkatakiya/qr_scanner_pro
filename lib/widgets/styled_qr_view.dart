import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/qr_style_config.dart';

/// Renders a QR code honouring a [QrStyleConfig]: colours, dot/eye shape,
/// optional centre logo and an optional foreground gradient (applied with a
/// [ShaderMask] since qr_flutter paints a single flat colour).
class StyledQrView extends StatelessWidget {
  const StyledQrView({
    super.key,
    required this.data,
    required this.style,
    this.size = 240,
    this.padding = 16,
  });

  final String data;
  final QrStyleConfig style;
  final double size;
  final double padding;

  QrEyeShape get _eyeShape =>
      style.roundedEyes ? QrEyeShape.circle : QrEyeShape.square;

  QrDataModuleShape get _dotShape => style.dotStyle == QrDotStyle.square
      ? QrDataModuleShape.square
      : QrDataModuleShape.circle;

  @override
  Widget build(BuildContext context) {
    // When using a gradient we paint modules opaque black then recolour with a
    // ShaderMask; the solid-colour path just uses the chosen foreground.
    final moduleColor =
        style.useGradient ? const Color(0xFF000000) : style.foregroundColor;

    Widget qr = QrImageView(
      data: data.isEmpty ? ' ' : data,
      version: QrVersions.auto,
      size: size,
      gapless: true,
      backgroundColor: Colors.transparent,
      errorCorrectionLevel: style.embeddedLogoPath != null
          ? QrErrorCorrectLevel.H
          : QrErrorCorrectLevel.M,
      eyeStyle: QrEyeStyle(eyeShape: _eyeShape, color: moduleColor),
      dataModuleStyle:
          QrDataModuleStyle(dataModuleShape: _dotShape, color: moduleColor),
      embeddedImage: style.embeddedLogoPath != null
          ? FileImage(File(style.embeddedLogoPath!))
          : null,
      embeddedImageStyle: style.embeddedLogoPath != null
          ? QrEmbeddedImageStyle(
              size: Size(size * style.logoScale, size * style.logoScale),
            )
          : null,
    );

    if (style.useGradient) {
      qr = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [style.foregroundColor, style.gradientColorValue],
        ).createShader(bounds),
        child: qr,
      );
    }

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: qr,
    );
  }
}
