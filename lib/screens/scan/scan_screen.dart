import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

import '../../models/scan_record.dart';
import '../../providers/history_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/settings_provider.dart';
import '../../services/permission_service.dart';
import '../../services/scanner_service.dart';
import '../../utils/feedback.dart';
import '../result/result_screen.dart';
import 'scan_overlay.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: kSupportedFormats,
    detectionSpeed: DetectionSpeed.normal,
    autoStart: false,
  );
  final _picker = ImagePicker();

  PermissionOutcome? _permission;
  bool _handling = false;
  bool _batchMode = false;
  double _zoom = 0;
  String? _lastValue;
  DateTime _lastTime = DateTime.fromMillisecondsSinceEpoch(0);
  final List<ScanRecord> _batchItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensurePermission());
  }

  Future<void> _ensurePermission() async {
    final outcome =
        await ref.read(permissionServiceProvider).requestCamera();
    if (!mounted) return;
    setState(() => _permission = outcome);
    if (outcome == PermissionOutcome.granted) {
      await _controller.start();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Detection
  // ---------------------------------------------------------------------------
  void _onDetect(BarcodeCapture capture) {
    if (_handling) return;
    final barcode =
        capture.barcodes.firstWhereOrNull((b) => (b.rawValue ?? '').isNotEmpty);
    if (barcode == null) return;

    final value = barcode.rawValue!;
    final now = DateTime.now();
    if (value == _lastValue &&
        now.difference(_lastTime) < const Duration(seconds: 2)) {
      return; // debounce identical reads
    }
    _lastValue = value;
    _lastTime = now;
    _register(barcode, value);
  }

  Future<void> _register(Barcode barcode, String value) async {
    final settings = ref.read(settingsProvider);
    ScanFeedback.onScan(
        sound: settings.soundEnabled, haptics: settings.hapticsEnabled);

    final type = ref.read(qrParserServiceProvider).parse(value).type;
    final record = ScanRecord(
      id: const Uuid().v4(),
      content: value,
      format: ScannerService.formatLabel(barcode.format),
      contentType: type,
      createdAt: DateTime.now(),
    );
    await ref.read(historyProvider.notifier).add(record);

    if (_batchMode) {
      setState(() => _batchItems.insert(0, record));
      return;
    }

    // Single-scan: pause, show result, resume on return.
    _handling = true;
    await _controller.stop();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ResultScreen(recordId: record.id)),
    );
    if (!mounted) return;
    _handling = false;
    _lastValue = null;
    await _controller.start();
  }

  // ---------------------------------------------------------------------------
  // Controls
  // ---------------------------------------------------------------------------
  Future<void> _pickFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final barcodes =
        await ref.read(scannerServiceProvider).scanImageFile(file.path);
    final barcode =
        barcodes.firstWhereOrNull((b) => (b.rawValue ?? '').isNotEmpty);
    if (!mounted) return;
    if (barcode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('scan.no_code_found'.tr())));
      return;
    }
    await _register(barcode, barcode.rawValue!);
  }

  Future<void> _toggleBatch() async {
    setState(() => _batchMode = !_batchMode);
  }

  Future<void> _setZoom(double value) async {
    setState(() => _zoom = value);
    await _controller.setZoomScale(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _permission == null
          ? const Center(child: CircularProgressIndicator())
          : _permission == PermissionOutcome.granted
              ? _buildScanner()
              : _PermissionDenied(
                  permanentlyDenied:
                      _permission == PermissionOutcome.permanentlyDenied,
                  onGrant: _ensurePermission,
                  onOpenSettings: () =>
                      ref.read(permissionServiceProvider).openSettings(),
                ),
    );
  }

  Widget _buildScanner() {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(controller: _controller, onDetect: _onDetect),
        const ScannerFrameOverlay(),
        SafeArea(
          child: Column(
            children: [
              _TopBar(controller: _controller),
              const Spacer(),
              if (_batchMode && _batchItems.isNotEmpty)
                _BatchStrip(
                  count: _batchItems.length,
                  onDone: () => Navigator.of(context).pop(),
                ),
              _ZoomSlider(value: _zoom, onChanged: _setZoom),
              _BottomBar(
                batchMode: _batchMode,
                onGallery: _pickFromGallery,
                onBatch: _toggleBatch,
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: SafeArea(
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Sub-widgets
// -----------------------------------------------------------------------------
class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller});
  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 8, 12, 0),
      child: ValueListenableBuilder(
        valueListenable: controller,
        builder: (context, state, _) {
          final torchOn = state.torchState == TorchState.on;
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _CircleButton(
                icon: torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                active: torchOn,
                onTap: controller.toggleTorch,
              ),
              const SizedBox(width: 12),
              _CircleButton(
                icon: Icons.cameraswitch_rounded,
                onTap: controller.switchCamera,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ZoomSlider extends StatelessWidget {
  const _ZoomSlider({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          const Icon(Icons.zoom_out_rounded, color: Colors.white70, size: 20),
          Expanded(
            child: Slider(
              value: value,
              onChanged: onChanged,
            ),
          ),
          const Icon(Icons.zoom_in_rounded, color: Colors.white70, size: 20),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.batchMode,
    required this.onGallery,
    required this.onBatch,
  });

  final bool batchMode;
  final VoidCallback onGallery;
  final VoidCallback onBatch;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _LabeledButton(
            icon: Icons.photo_library_rounded,
            label: 'scan.gallery'.tr(),
            onTap: onGallery,
          ),
          _LabeledButton(
            icon: batchMode
                ? Icons.dynamic_feed_rounded
                : Icons.filter_none_rounded,
            label: 'scan.batch'.tr(),
            active: batchMode,
            onTap: onBatch,
          ),
        ],
      ),
    );
  }
}

class _BatchStrip extends StatelessWidget {
  const _BatchStrip({required this.count, required this.onDone});
  final int count;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'scan.batch_count'.tr(args: ['$count']),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: onDone,
            child: Text('common.done'.tr(),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton(
      {required this.icon, required this.onTap, this.active = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active
              ? Colors.white
              : Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: active ? Colors.black : Colors.white),
      ),
    );
  }
}

class _LabeledButton extends StatelessWidget {
  const _LabeledButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? Theme.of(context).colorScheme.primary : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _PermissionDenied extends StatelessWidget {
  const _PermissionDenied({
    required this.permanentlyDenied,
    required this.onGrant,
    required this.onOpenSettings,
  });
  final bool permanentlyDenied;
  final VoidCallback onGrant;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_photography_rounded,
              size: 72, color: Colors.white54),
          const SizedBox(height: 24),
          Text('scan.permission_title'.tr(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('scan.permission_body'.tr(),
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: permanentlyDenied ? onOpenSettings : onGrant,
            child: Text(permanentlyDenied
                ? 'scan.open_settings'.tr()
                : 'scan.grant'.tr()),
          ),
        ],
      ),
    );
  }
}
