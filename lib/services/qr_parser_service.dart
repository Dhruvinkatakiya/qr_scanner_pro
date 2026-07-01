import '../models/content_type.dart';
import '../models/parsed_content.dart';

/// Detects the semantic type of a raw payload and extracts structured fields,
/// plus a pluggable URL safety check.
///
/// The safety analysis is a self-contained offline heuristic. To upgrade to a
/// network service (e.g. Google Safe Browsing) implement [UrlSafetyAnalyzer]
/// and pass it to the constructor — no UI changes required.
class QrParserService {
  QrParserService({UrlSafetyAnalyzer? safetyAnalyzer})
      : _safety = safetyAnalyzer ?? const HeuristicUrlSafetyAnalyzer();

  final UrlSafetyAnalyzer _safety;

  ParsedContent parse(String raw) {
    final value = raw.trim();
    final lower = value.toLowerCase();

    if (lower.startsWith('wifi:')) return _parseWifi(value);
    if (lower.startsWith('begin:vcard')) return _parseVCard(value);
    if (lower.startsWith('mecard:')) return _parseMeCard(value);
    if (lower.startsWith('begin:vevent') || lower.startsWith('begin:vcalendar')) {
      return _parseEvent(value);
    }
    if (lower.startsWith('mailto:') || lower.startsWith('matmsg:')) {
      return _parseEmail(value);
    }
    if (lower.startsWith('smsto:') || lower.startsWith('sms:')) {
      return _parseSms(value);
    }
    if (lower.startsWith('tel:')) {
      final number = value.substring(4);
      return ParsedContent(
        type: ContentType.phone,
        raw: value,
        title: number,
        subtitle: 'Phone number',
        fields: {'Number': number},
      );
    }
    if (lower.startsWith('geo:')) return _parseGeo(value);
    if (_isCrypto(lower)) return _parseCrypto(value);
    if (_looksLikeUrl(value)) return _parseUrl(value);
    if (_looksLikeEmail(value)) {
      return ParsedContent(
        type: ContentType.email,
        raw: value,
        title: value,
        subtitle: 'Email address',
        fields: {'Address': value},
      );
    }

    return ParsedContent(
      type: ContentType.text,
      raw: value,
      title: value,
      subtitle: '${value.length} characters',
    );
  }

  // ---------------------------------------------------------------------------
  // URL
  // ---------------------------------------------------------------------------
  bool _looksLikeUrl(String value) {
    final lower = value.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) return true;
    // Bare domain like "example.com/path" with no spaces.
    final domainRe = RegExp(
        r'^([a-z0-9-]+\.)+[a-z]{2,}(\/[^\s]*)?$', caseSensitive: false);
    return !value.contains(' ') && domainRe.hasMatch(value);
  }

  ParsedContent _parseUrl(String value) {
    final normalised =
        value.startsWith('http') ? value : 'https://$value';
    final uri = Uri.tryParse(normalised);
    final host = uri?.host ?? value;
    return ParsedContent(
      type: ContentType.url,
      raw: normalised,
      title: value,
      subtitle: host,
      fields: {'Domain': host},
      safety: _safety.analyze(normalised),
    );
  }

  // ---------------------------------------------------------------------------
  // Wi-Fi  (WIFI:S:ssid;T:WPA;P:pass;H:false;;)
  // ---------------------------------------------------------------------------
  ParsedContent _parseWifi(String value) {
    final body = value.substring(5);
    final map = <String, String>{};
    for (final part in _splitEscaped(body, ';')) {
      final idx = part.indexOf(':');
      if (idx > 0) {
        map[part.substring(0, idx).toUpperCase()] =
            _unescape(part.substring(idx + 1));
      }
    }
    final ssid = map['S'] ?? '';
    final security = map['T'] ?? 'nopass';
    return ParsedContent(
      type: ContentType.wifi,
      raw: value,
      title: ssid.isEmpty ? 'Wi-Fi network' : ssid,
      subtitle: 'Security: ${security.toUpperCase()}',
      fields: {
        'Network (SSID)': ssid,
        'Security': security.toUpperCase(),
        if ((map['P'] ?? '').isNotEmpty) 'Password': map['P']!,
        'Hidden': (map['H'] ?? 'false'),
      },
    );
  }

  // ---------------------------------------------------------------------------
  // vCard
  // ---------------------------------------------------------------------------
  ParsedContent _parseVCard(String value) {
    final fields = <String, String>{};
    String name = '';
    for (final line in value.split(RegExp(r'\r?\n'))) {
      final upper = line.toUpperCase();
      if (upper.startsWith('FN:')) {
        name = line.substring(3).trim();
      } else if (upper.startsWith('N:') && name.isEmpty) {
        name = line.substring(2).replaceAll(';', ' ').trim();
      } else if (upper.startsWith('TEL')) {
        fields['Phone'] = line.split(':').last.trim();
      } else if (upper.startsWith('EMAIL')) {
        fields['Email'] = line.split(':').last.trim();
      } else if (upper.startsWith('ORG:')) {
        fields['Organization'] = line.substring(4).trim();
      } else if (upper.startsWith('TITLE:')) {
        fields['Title'] = line.substring(6).trim();
      } else if (upper.startsWith('ADR')) {
        fields['Address'] =
            line.split(':').last.replaceAll(';', ' ').trim();
      } else if (upper.startsWith('URL')) {
        fields['Website'] = line.split(':').sublist(1).join(':').trim();
      }
    }
    return ParsedContent(
      type: ContentType.contact,
      raw: value,
      title: name.isEmpty ? 'Contact' : name,
      subtitle: fields['Phone'] ?? fields['Email'] ?? 'Contact card',
      fields: {'Name': name, ...fields}..removeWhere((k, v) => v.isEmpty),
    );
  }

  ParsedContent _parseMeCard(String value) {
    final body = value.substring(7);
    final fields = <String, String>{};
    String name = '';
    for (final part in _splitEscaped(body, ';')) {
      final idx = part.indexOf(':');
      if (idx < 0) continue;
      final key = part.substring(0, idx).toUpperCase();
      final v = part.substring(idx + 1);
      switch (key) {
        case 'N':
          name = v.replaceAll(',', ' ').trim();
          break;
        case 'TEL':
          fields['Phone'] = v;
          break;
        case 'EMAIL':
          fields['Email'] = v;
          break;
        case 'ADR':
          fields['Address'] = v;
          break;
        case 'ORG':
          fields['Organization'] = v;
          break;
      }
    }
    return ParsedContent(
      type: ContentType.contact,
      raw: value,
      title: name.isEmpty ? 'Contact' : name,
      subtitle: fields['Phone'] ?? fields['Email'] ?? 'Contact card',
      fields: {'Name': name, ...fields}..removeWhere((k, v) => v.isEmpty),
    );
  }

  // ---------------------------------------------------------------------------
  // Email / SMS / Geo / Event / Crypto
  // ---------------------------------------------------------------------------
  ParsedContent _parseEmail(String value) {
    final uri = Uri.tryParse(value);
    final to = uri?.path ?? value.replaceFirst(RegExp('mailto:', caseSensitive: false), '');
    final subject = uri?.queryParameters['subject'];
    final body = uri?.queryParameters['body'];
    return ParsedContent(
      type: ContentType.email,
      raw: value,
      title: to,
      subtitle: subject ?? 'Email',
      fields: {
        'To': to,
        if (subject != null && subject.isNotEmpty) 'Subject': subject,
        if (body != null && body.isNotEmpty) 'Message': body,
      },
    );
  }

  ParsedContent _parseSms(String value) {
    final withoutScheme = value.replaceFirst(RegExp(r'sms(to)?:', caseSensitive: false), '');
    String number = withoutScheme;
    String? body;
    if (withoutScheme.contains('?')) {
      final parts = withoutScheme.split('?');
      number = parts.first;
      final uri = Uri.tryParse('x?${parts.sublist(1).join('?')}');
      body = uri?.queryParameters['body'];
    } else if (withoutScheme.contains(':')) {
      final parts = withoutScheme.split(':');
      number = parts.first;
      body = parts.sublist(1).join(':');
    }
    return ParsedContent(
      type: ContentType.sms,
      raw: value,
      title: number,
      subtitle: body ?? 'Text message',
      fields: {
        'Number': number,
        if (body != null && body.isNotEmpty) 'Message': body,
      },
    );
  }

  ParsedContent _parseGeo(String value) {
    final body = value.substring(4);
    final coords = body.split('?').first.split(',');
    final lat = coords.isNotEmpty ? coords[0] : '';
    final lng = coords.length > 1 ? coords[1] : '';
    final uri = Uri.tryParse(value);
    final query = uri?.queryParameters['q'];
    return ParsedContent(
      type: ContentType.geo,
      raw: value,
      title: query ?? 'Location',
      subtitle: '$lat, $lng',
      fields: {
        'Latitude': lat,
        'Longitude': lng,
        'Label': ?query,
      },
    );
  }

  ParsedContent _parseEvent(String value) {
    final fields = <String, String>{};
    String summary = 'Event';
    for (final line in value.split(RegExp(r'\r?\n'))) {
      final upper = line.toUpperCase();
      if (upper.startsWith('SUMMARY:')) {
        summary = line.substring(8).trim();
        fields['Title'] = summary;
      } else if (upper.startsWith('DTSTART')) {
        fields['Starts'] = _formatIcalDate(line.split(':').last.trim());
      } else if (upper.startsWith('DTEND')) {
        fields['Ends'] = _formatIcalDate(line.split(':').last.trim());
      } else if (upper.startsWith('LOCATION:')) {
        fields['Location'] = line.substring(9).trim();
      } else if (upper.startsWith('DESCRIPTION:')) {
        fields['Description'] = line.substring(12).trim();
      }
    }
    return ParsedContent(
      type: ContentType.calendar,
      raw: value,
      title: summary,
      subtitle: fields['Starts'] ?? 'Calendar event',
      fields: fields,
    );
  }

  bool _isCrypto(String lower) {
    return lower.startsWith('bitcoin:') ||
        lower.startsWith('ethereum:') ||
        lower.startsWith('litecoin:') ||
        lower.startsWith('dogecoin:') ||
        RegExp(r'^(bc1|[13])[a-z0-9]{25,62}$', caseSensitive: false)
            .hasMatch(lower) ||
        RegExp(r'^0x[a-f0-9]{40}$', caseSensitive: false).hasMatch(lower);
  }

  ParsedContent _parseCrypto(String value) {
    String scheme = 'Address';
    String address = value;
    double? amount;
    if (value.contains(':')) {
      final uri = Uri.tryParse(value);
      scheme = uri?.scheme.isNotEmpty == true
          ? '${uri!.scheme[0].toUpperCase()}${uri.scheme.substring(1)}'
          : 'Crypto';
      address = uri?.path ?? value;
      final amt = uri?.queryParameters['amount'];
      if (amt != null) amount = double.tryParse(amt);
    }
    return ParsedContent(
      type: ContentType.crypto,
      raw: value,
      title: address,
      subtitle: '$scheme address',
      fields: {
        'Network': scheme,
        'Address': address,
        if (amount != null) 'Amount': amount.toString(),
      },
    );
  }

  bool _looksLikeEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  String _formatIcalDate(String raw) {
    // Basic iCal date parsing: 20240115T130000Z -> 2024-01-15 13:00
    final m = RegExp(r'^(\d{4})(\d{2})(\d{2})(T(\d{2})(\d{2}))?')
        .firstMatch(raw);
    if (m == null) return raw;
    final date = '${m.group(1)}-${m.group(2)}-${m.group(3)}';
    if (m.group(4) != null) return '$date ${m.group(5)}:${m.group(6)}';
    return date;
  }

  /// Splits on [sep] while respecting `\` escaping (used by WIFI/MECARD).
  List<String> _splitEscaped(String input, String sep) {
    final result = <String>[];
    final buffer = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final ch = input[i];
      if (ch == r'\' && i + 1 < input.length) {
        buffer.write(input[i + 1]);
        i++;
      } else if (ch == sep) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }
    if (buffer.isNotEmpty) result.add(buffer.toString());
    return result;
  }

  String _unescape(String input) =>
      input.replaceAllMapped(RegExp(r'\\(.)'), (m) => m.group(1)!);
}

/// Strategy interface so the offline heuristic can be swapped for an online
/// reputation service without touching callers.
abstract class UrlSafetyAnalyzer {
  UrlSafety analyze(String url);
}

/// Fully offline heuristic checker — no network dependency. Flags shorteners,
/// raw IP hosts, credential-in-URL tricks, punycode homographs and risky TLDs.
class HeuristicUrlSafetyAnalyzer implements UrlSafetyAnalyzer {
  const HeuristicUrlSafetyAnalyzer();

  static const _shorteners = {
    'bit.ly', 'tinyurl.com', 't.co', 'goo.gl', 'ow.ly', 'is.gd', 'buff.ly',
    'cutt.ly', 'rebrand.ly', 'shorturl.at', 'rb.gy', 't.ly', 'tiny.cc',
  };

  static const _riskyTlds = {'.zip', '.mov', '.xyz', '.top', '.click', '.gq'};

  @override
  UrlSafety analyze(String url) {
    final uri = Uri.tryParse(url);
    final host = (uri?.host ?? '').toLowerCase();
    final reasons = <String>[];
    var level = SafetyLevel.safe;

    void raise(SafetyLevel l, String reason) {
      reasons.add(reason);
      if (l.index > level.index) level = l;
    }

    if (host.isEmpty) {
      return const UrlSafety(level: SafetyLevel.caution, domain: 'unknown',
          reasons: ['Could not read a domain from this link.']);
    }

    // Raw IP address host.
    if (RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host)) {
      raise(SafetyLevel.danger, 'Uses a raw IP address instead of a domain.');
    }
    // Credentials embedded in the URL (phishing obfuscation).
    if (uri?.userInfo.isNotEmpty == true || url.contains('@')) {
      raise(SafetyLevel.danger, 'Contains an "@" — the real destination may be hidden.');
    }
    // Punycode / IDN homograph.
    if (host.contains('xn--')) {
      raise(SafetyLevel.caution, 'Uses punycode, which can imitate a trusted brand.');
    }
    // URL shortener — destination is unknown until opened.
    if (_shorteners.contains(host)) {
      raise(SafetyLevel.caution, 'Shortened link — the final destination is hidden.');
    }
    // Not HTTPS.
    if (uri?.scheme == 'http') {
      raise(SafetyLevel.caution, 'Not secured with HTTPS.');
    }
    // Risky TLD.
    for (final tld in _riskyTlds) {
      if (host.endsWith(tld)) {
        raise(SafetyLevel.caution, 'Uses the $tld domain extension, often abused.');
        break;
      }
    }
    // Excessive subdomains, e.g. secure.login.paypal.com.attacker.io
    if ('.'.allMatches(host).length >= 4) {
      raise(SafetyLevel.caution, 'Unusually deep subdomain structure.');
    }

    return UrlSafety(level: level, domain: host, reasons: reasons);
  }
}
