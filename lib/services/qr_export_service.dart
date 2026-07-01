import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

/// Captures a rendered widget (via a [RepaintBoundary] key) to PNG bytes and
/// handles saving to the gallery or a temp file for sharing.
class QrExportService {
  const QrExportService();

  /// Rasterises the boundary behind [key] at [pixelRatio] and returns PNG bytes.
  Future<Uint8List> capturePng(GlobalKey key, {double pixelRatio = 3.0}) async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('QR is not ready to export yet.');
    }
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Failed to encode the QR image.');
    }
    return byteData.buffer.asUint8List();
  }

  /// Saves PNG bytes to the device gallery. Requests access if needed.
  Future<void> saveToGallery(Uint8List bytes, {String? name}) async {
    final hasAccess = await Gal.hasAccess();
    if (!hasAccess) {
      await Gal.requestAccess();
    }
    await Gal.putImageBytes(bytes, name: name ?? 'qr_scanner_pro');
  }

  /// Writes PNG bytes to a temp file and returns the path (for sharing).
  Future<String> writeTempPng(Uint8List bytes, {String? name}) async {
    final dir = await getTemporaryDirectory();
    final fileName =
        '${name ?? 'qr'}_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = await File('${dir.path}/$fileName').writeAsBytes(bytes);
    return file.path;
  }
}
