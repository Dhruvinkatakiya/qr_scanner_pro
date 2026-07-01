import 'package:mobile_scanner/mobile_scanner.dart';

/// Barcode symbologies the app advertises support for. Passed to the
/// [MobileScannerController] so ML Kit only looks for what we handle.
const List<BarcodeFormat> kSupportedFormats = [
  BarcodeFormat.qrCode,
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
  BarcodeFormat.code128,
  BarcodeFormat.code39,
  BarcodeFormat.code93,
  BarcodeFormat.codabar,
  BarcodeFormat.itf14,
  BarcodeFormat.pdf417,
  BarcodeFormat.dataMatrix,
  BarcodeFormat.aztec,
];

/// Stateless helpers shared by the scan screen and gallery import.
class ScannerService {
  const ScannerService();

  /// Runs ML Kit detection over a still image on disk (gallery import).
  /// Returns the decoded [Barcode]s, or an empty list if none were found.
  Future<List<Barcode>> scanImageFile(String path) async {
    final controller = MobileScannerController(formats: kSupportedFormats);
    try {
      final capture = await controller.analyzeImage(path);
      return capture?.barcodes ?? const <Barcode>[];
    } finally {
      await controller.dispose();
    }
  }

  /// Human-friendly name for a detected symbology.
  static String formatLabel(BarcodeFormat format) {
    switch (format) {
      case BarcodeFormat.qrCode:
        return 'QR Code';
      case BarcodeFormat.ean13:
        return 'EAN-13';
      case BarcodeFormat.ean8:
        return 'EAN-8';
      case BarcodeFormat.upcA:
        return 'UPC-A';
      case BarcodeFormat.upcE:
        return 'UPC-E';
      case BarcodeFormat.code128:
        return 'Code 128';
      case BarcodeFormat.code39:
        return 'Code 39';
      case BarcodeFormat.code93:
        return 'Code 93';
      case BarcodeFormat.codabar:
        return 'Codabar';
      case BarcodeFormat.itf14:
        return 'ITF-14';
      case BarcodeFormat.pdf417:
        return 'PDF417';
      case BarcodeFormat.dataMatrix:
        return 'Data Matrix';
      case BarcodeFormat.aztec:
        return 'Aztec';
      default:
        return 'Barcode';
    }
  }
}
