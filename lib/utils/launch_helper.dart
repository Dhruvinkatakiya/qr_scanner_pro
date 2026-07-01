import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Small facade over `url_launcher`, `share_plus` and the clipboard so result
/// actions are one-liners at the call site and easy to unit test.
class LaunchHelper {
  LaunchHelper._();

  static Future<void> copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  static Future<void> shareText(String text, {String? subject}) =>
      SharePlus.instance.share(ShareParams(text: text, subject: subject));

  static Future<void> shareImage(String path, {String? text}) =>
      SharePlus.instance.share(
        ShareParams(files: [XFile(path)], text: text),
      );

  static Future<bool> openUrl(String url) => _launch(Uri.parse(url));

  static Future<bool> dial(String number) =>
      _launch(Uri(scheme: 'tel', path: number));

  static Future<bool> sms(String number, {String? body}) => _launch(
        Uri(scheme: 'sms', path: number, queryParameters: {
          if (body != null && body.isNotEmpty) 'body': body,
        }),
      );

  static Future<bool> email(String to, {String? subject, String? body}) =>
      _launch(Uri(scheme: 'mailto', path: to, queryParameters: {
        if (subject != null && subject.isNotEmpty) 'subject': subject,
        if (body != null && body.isNotEmpty) 'body': body,
      }));

  static Future<bool> openMaps(String lat, String lng, {String? label}) {
    // geo: intent is handled by any maps app on Android.
    final geo = Uri.parse(
        'geo:$lat,$lng?q=$lat,$lng${label != null ? '(${Uri.encodeComponent(label)})' : ''}');
    return _launch(geo);
  }

  /// Opens the raw payload as a URI when it carries its own scheme (mailto:,
  /// tel:, geo:, bitcoin:, etc.). Falls back to false when unlaunchable.
  static Future<bool> openRaw(String raw) => _launch(Uri.parse(raw));

  static Future<bool> _launch(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }
}
