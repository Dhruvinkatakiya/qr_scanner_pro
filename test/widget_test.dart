import 'package:flutter_test/flutter_test.dart';

import 'package:qr_scanner_pro/models/content_type.dart';
import 'package:qr_scanner_pro/services/qr_parser_service.dart';

void main() {
  final parser = QrParserService();

  test('detects URLs and flags suspicious ones', () {
    final safe = parser.parse('https://flutter.dev');
    expect(safe.type, ContentType.url);
    expect(safe.safety?.isSuspicious, false);

    final ip = parser.parse('http://192.168.0.1/login');
    expect(ip.type, ContentType.url);
    expect(ip.safety?.isSuspicious, true);
  });

  test('parses Wi-Fi payloads', () {
    final wifi = parser.parse('WIFI:S:MyNet;T:WPA;P:secret123;H:false;;');
    expect(wifi.type, ContentType.wifi);
    expect(wifi.fields['Network (SSID)'], 'MyNet');
    expect(wifi.fields['Password'], 'secret123');
  });

  test('classifies plain text as a fallback', () {
    expect(parser.parse('just some text').type, ContentType.text);
  });
}
