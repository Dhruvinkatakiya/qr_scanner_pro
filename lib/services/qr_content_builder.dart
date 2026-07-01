/// Builds standards-compliant payload strings for the QR generator from
/// structured form input (the inverse of [QrParserService]).
class QrContentBuilder {
  QrContentBuilder._();

  static String url(String value) {
    final v = value.trim();
    if (v.isEmpty) return '';
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    return 'https://$v';
  }

  static String text(String value) => value;

  static String email({
    required String to,
    String subject = '',
    String body = '',
  }) {
    final params = <String, String>{};
    if (subject.isNotEmpty) params['subject'] = subject;
    if (body.isNotEmpty) params['body'] = body;
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return 'mailto:${to.trim()}${query.isEmpty ? '' : '?$query'}';
  }

  static String phone(String number) => 'tel:${number.trim()}';

  static String sms({required String number, String message = ''}) {
    if (message.isEmpty) return 'smsto:${number.trim()}';
    return 'smsto:${number.trim()}:$message';
  }

  static String wifi({
    required String ssid,
    String password = '',
    String security = 'WPA', // WPA | WEP | nopass
    bool hidden = false,
  }) {
    String esc(String v) =>
        v.replaceAllMapped(RegExp(r'([\\;,:"])'), (m) => '\\${m.group(1)}');
    final type = security == 'nopass' ? 'nopass' : security;
    return 'WIFI:S:${esc(ssid)};T:$type;'
        '${security == 'nopass' ? '' : 'P:${esc(password)};'}'
        'H:${hidden ? 'true' : 'false'};;';
  }

  static String geo({
    required double latitude,
    required double longitude,
    String label = '',
  }) {
    final base = 'geo:$latitude,$longitude';
    return label.isEmpty ? base : '$base?q=$latitude,$longitude(${Uri.encodeComponent(label)})';
  }

  static String contact({
    required String name,
    String phone = '',
    String email = '',
    String organization = '',
    String title = '',
    String website = '',
    String address = '',
  }) {
    final buffer = StringBuffer()
      ..writeln('BEGIN:VCARD')
      ..writeln('VERSION:3.0')
      ..writeln('FN:$name');
    if (organization.isNotEmpty) buffer.writeln('ORG:$organization');
    if (title.isNotEmpty) buffer.writeln('TITLE:$title');
    if (phone.isNotEmpty) buffer.writeln('TEL;TYPE=CELL:$phone');
    if (email.isNotEmpty) buffer.writeln('EMAIL:$email');
    if (website.isNotEmpty) buffer.writeln('URL:$website');
    if (address.isNotEmpty) buffer.writeln('ADR:;;$address;;;;');
    buffer.write('END:VCARD');
    return buffer.toString();
  }

  static String event({
    required String summary,
    DateTime? start,
    DateTime? end,
    String location = '',
    String description = '',
  }) {
    String fmt(DateTime d) {
      final u = d.toUtc();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${u.year}${two(u.month)}${two(u.day)}T'
          '${two(u.hour)}${two(u.minute)}${two(u.second)}Z';
    }

    final buffer = StringBuffer()
      ..writeln('BEGIN:VEVENT')
      ..writeln('SUMMARY:$summary');
    if (start != null) buffer.writeln('DTSTART:${fmt(start)}');
    if (end != null) buffer.writeln('DTEND:${fmt(end)}');
    if (location.isNotEmpty) buffer.writeln('LOCATION:$location');
    if (description.isNotEmpty) buffer.writeln('DESCRIPTION:$description');
    buffer.write('END:VEVENT');
    return buffer.toString();
  }

  static String crypto({
    required String network, // bitcoin | ethereum | litecoin
    required String address,
    double? amount,
  }) {
    final scheme = network.toLowerCase();
    final base = '$scheme:${address.trim()}';
    return amount == null ? base : '$base?amount=$amount';
  }
}
