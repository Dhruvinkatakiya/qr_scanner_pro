import 'content_type.dart';

/// Severity of a URL safety heuristic result.
enum SafetyLevel { safe, caution, danger }

/// Outcome of the (pluggable) URL safety analysis.
///
/// The current implementation is a fully offline heuristic. The shape is
/// deliberately API-agnostic so a Google Safe Browsing / VirusTotal lookup can
/// be dropped in later without changing any UI code.
class UrlSafety {
  const UrlSafety({
    required this.level,
    required this.domain,
    this.reasons = const [],
  });

  final SafetyLevel level;
  final String domain;
  final List<String> reasons;

  bool get isSuspicious => level != SafetyLevel.safe;
}

/// Structured, human-friendly interpretation of a raw payload produced by
/// [QrParserService]. Consumed by the result screen to render the right fields
/// and quick actions.
class ParsedContent {
  const ParsedContent({
    required this.type,
    required this.raw,
    required this.title,
    this.subtitle,
    this.fields = const {},
    this.safety,
  });

  final ContentType type;

  /// The original decoded string.
  final String raw;

  /// Primary line shown to the user (e.g. the URL, the Wi-Fi SSID, a name).
  final String title;

  /// Optional secondary line (e.g. the URL host, a phone number).
  final String? subtitle;

  /// Ordered structured fields to display (label -> value), e.g. for a vCard.
  final Map<String, String> fields;

  /// Only populated when [type] == [ContentType.url].
  final UrlSafety? safety;
}
