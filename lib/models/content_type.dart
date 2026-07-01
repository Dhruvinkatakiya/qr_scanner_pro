import 'package:flutter/material.dart';

/// Semantic classification of a scanned / generated payload.
///
/// This drives the icon, colour and the set of quick actions shown on the
/// result screen, independent of the underlying barcode symbology.
enum ContentType {
  url,
  wifi,
  contact,
  email,
  phone,
  sms,
  geo,
  calendar,
  crypto,
  product,
  text;

  String get label {
    switch (this) {
      case ContentType.url:
        return 'Website';
      case ContentType.wifi:
        return 'Wi-Fi';
      case ContentType.contact:
        return 'Contact';
      case ContentType.email:
        return 'Email';
      case ContentType.phone:
        return 'Phone';
      case ContentType.sms:
        return 'SMS';
      case ContentType.geo:
        return 'Location';
      case ContentType.calendar:
        return 'Event';
      case ContentType.crypto:
        return 'Crypto';
      case ContentType.product:
        return 'Product';
      case ContentType.text:
        return 'Text';
    }
  }

  IconData get icon {
    switch (this) {
      case ContentType.url:
        return Icons.link_rounded;
      case ContentType.wifi:
        return Icons.wifi_rounded;
      case ContentType.contact:
        return Icons.person_rounded;
      case ContentType.email:
        return Icons.email_rounded;
      case ContentType.phone:
        return Icons.phone_rounded;
      case ContentType.sms:
        return Icons.sms_rounded;
      case ContentType.geo:
        return Icons.location_on_rounded;
      case ContentType.calendar:
        return Icons.event_rounded;
      case ContentType.crypto:
        return Icons.currency_bitcoin_rounded;
      case ContentType.product:
        return Icons.qr_code_2_rounded;
      case ContentType.text:
        return Icons.notes_rounded;
    }
  }

  /// A distinctive accent colour used on chips and result headers.
  Color get color {
    switch (this) {
      case ContentType.url:
        return const Color(0xFF2F6BFF);
      case ContentType.wifi:
        return const Color(0xFF00A88E);
      case ContentType.contact:
        return const Color(0xFF7A5CFF);
      case ContentType.email:
        return const Color(0xFFEA6A47);
      case ContentType.phone:
        return const Color(0xFF23A455);
      case ContentType.sms:
        return const Color(0xFF1FA2C4);
      case ContentType.geo:
        return const Color(0xFFE0553D);
      case ContentType.calendar:
        return const Color(0xFFB0468C);
      case ContentType.crypto:
        return const Color(0xFFF7931A);
      case ContentType.product:
        return const Color(0xFF5A6472);
      case ContentType.text:
        return const Color(0xFF6B7280);
    }
  }

  static ContentType fromName(String? name) {
    return ContentType.values.firstWhere(
      (t) => t.name == name,
      orElse: () => ContentType.text,
    );
  }
}

/// Whether a record originated from a live/gallery scan or was generated in-app.
enum RecordSource { scanned, generated }
