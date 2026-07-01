import 'package:flutter/material.dart';

/// Shape of the individual data modules of a generated QR code.
enum QrDotStyle { square, rounded, dots }

/// Serializable description of how a generated QR code should be painted.
///
/// Held both by the live generator editor and persisted alongside generated
/// [ScanRecord]s so a code can be re-opened and re-exported later.
class QrStyleConfig {
  const QrStyleConfig({
    this.foreground = 0xFF101827,
    this.background = 0xFFFFFFFF,
    this.useGradient = false,
    this.gradientColor = 0xFF2F6BFF,
    this.dotStyle = QrDotStyle.square,
    this.roundedEyes = false,
    this.embeddedLogoPath,
    this.logoScale = 0.2,
  });

  /// ARGB int for the code's dark modules.
  final int foreground;

  /// ARGB int for the quiet-zone / background.
  final int background;

  /// When true the foreground is painted with a [foreground] -> [gradientColor]
  /// linear gradient (a Pro-only styling option).
  final bool useGradient;
  final int gradientColor;

  final QrDotStyle dotStyle;
  final bool roundedEyes;

  /// Absolute path to a logo image embedded in the centre (Pro-only).
  final String? embeddedLogoPath;

  /// Logo size as a fraction of the QR width (0.1 – 0.3 is sensible).
  final double logoScale;

  Color get foregroundColor => Color(foreground);
  Color get backgroundColor => Color(background);
  Color get gradientColorValue => Color(gradientColor);

  QrStyleConfig copyWith({
    int? foreground,
    int? background,
    bool? useGradient,
    int? gradientColor,
    QrDotStyle? dotStyle,
    bool? roundedEyes,
    String? embeddedLogoPath,
    bool clearLogo = false,
    double? logoScale,
  }) {
    return QrStyleConfig(
      foreground: foreground ?? this.foreground,
      background: background ?? this.background,
      useGradient: useGradient ?? this.useGradient,
      gradientColor: gradientColor ?? this.gradientColor,
      dotStyle: dotStyle ?? this.dotStyle,
      roundedEyes: roundedEyes ?? this.roundedEyes,
      embeddedLogoPath:
          clearLogo ? null : (embeddedLogoPath ?? this.embeddedLogoPath),
      logoScale: logoScale ?? this.logoScale,
    );
  }

  Map<String, dynamic> toJson() => {
        'foreground': foreground,
        'background': background,
        'useGradient': useGradient,
        'gradientColor': gradientColor,
        'dotStyle': dotStyle.name,
        'roundedEyes': roundedEyes,
        'embeddedLogoPath': embeddedLogoPath,
        'logoScale': logoScale,
      };

  factory QrStyleConfig.fromJson(Map<String, dynamic> json) {
    return QrStyleConfig(
      foreground: (json['foreground'] as num?)?.toInt() ?? 0xFF101827,
      background: (json['background'] as num?)?.toInt() ?? 0xFFFFFFFF,
      useGradient: json['useGradient'] as bool? ?? false,
      gradientColor: (json['gradientColor'] as num?)?.toInt() ?? 0xFF2F6BFF,
      dotStyle: QrDotStyle.values.firstWhere(
        (s) => s.name == json['dotStyle'],
        orElse: () => QrDotStyle.square,
      ),
      roundedEyes: json['roundedEyes'] as bool? ?? false,
      embeddedLogoPath: json['embeddedLogoPath'] as String?,
      logoScale: (json['logoScale'] as num?)?.toDouble() ?? 0.2,
    );
  }
}
