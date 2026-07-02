import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../models/content_type.dart';
import '../../models/qr_style_config.dart';
import '../../models/scan_record.dart';
import '../../providers/history_provider.dart';
import '../../services/qr_content_builder.dart';
import '../../services/qr_export_service.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../utils/launch_helper.dart';
import '../../widgets/styled_qr_view.dart';
import 'qr_style_editor.dart';

/// Generator content types and their metadata.
enum GenType {
  url(Icons.link_rounded, ContentType.url, 'Website'),
  text(Icons.notes_rounded, ContentType.text, 'Text'),
  wifi(Icons.wifi_rounded, ContentType.wifi, 'Wi-Fi'),
  email(Icons.email_rounded, ContentType.email, 'Email'),
  phone(Icons.phone_rounded, ContentType.phone, 'Phone'),
  sms(Icons.sms_rounded, ContentType.sms, 'SMS'),
  geo(Icons.location_on_rounded, ContentType.geo, 'Location'),
  contact(Icons.person_rounded, ContentType.contact, 'Contact'),
  crypto(Icons.currency_bitcoin_rounded, ContentType.crypto, 'Crypto');

  const GenType(this.icon, this.contentType, this.label);
  final IconData icon;
  final ContentType contentType;
  final String label;
}

class GenerateScreen extends ConsumerStatefulWidget {
  const GenerateScreen({super.key});

  @override
  ConsumerState<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends ConsumerState<GenerateScreen>
    with SingleTickerProviderStateMixin {
  final _repaintKey = GlobalKey();
  final _picker = ImagePicker();
  final _export = const QrExportService();

  late final AnimationController _typeAnimController;

  GenType _type = GenType.url;
  QrStyleConfig _style = const QrStyleConfig();
  String _wifiSecurity = 'WPA';
  bool _wifiHidden = false;
  String _cryptoNetwork = 'bitcoin';
  bool _busy = false;

  final Map<String, TextEditingController> _c = {};

  static const _fieldKeys = [
    'url', 'text', 'ssid', 'password', 'to', 'subject', 'body', 'phone',
    'sms_msg', 'lat', 'lng', 'label', 'name', 'org', 'title', 'website',
    'address', 'crypto_address', 'amount',
  ];

  @override
  void initState() {
    super.initState();
    _typeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    for (final k in _fieldKeys) {
      _c[k] = TextEditingController()..addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _typeAnimController.dispose();
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() => setState(() {});

  String t(String key) => _c[key]!.text.trim();

  void _switchType(GenType type) {
    if (type == _type) return;
    _typeAnimController.forward(from: 0);
    setState(() => _type = type);
  }

  /// Builds the payload string for the current form + type.
  String get _content {
    switch (_type) {
      case GenType.url:
        return QrContentBuilder.url(t('url'));
      case GenType.text:
        return QrContentBuilder.text(_c['text']!.text);
      case GenType.wifi:
        return t('ssid').isEmpty
            ? ''
            : QrContentBuilder.wifi(
                ssid: t('ssid'),
                password: t('password'),
                security: _wifiSecurity,
                hidden: _wifiHidden);
      case GenType.email:
        return t('to').isEmpty
            ? ''
            : QrContentBuilder.email(
                to: t('to'), subject: t('subject'), body: t('body'));
      case GenType.phone:
        return t('phone').isEmpty ? '' : QrContentBuilder.phone(t('phone'));
      case GenType.sms:
        return t('phone').isEmpty
            ? ''
            : QrContentBuilder.sms(number: t('phone'), message: t('sms_msg'));
      case GenType.geo:
        final lat = double.tryParse(t('lat'));
        final lng = double.tryParse(t('lng'));
        return (lat == null || lng == null)
            ? ''
            : QrContentBuilder.geo(
                latitude: lat, longitude: lng, label: t('label'));
      case GenType.contact:
        return t('name').isEmpty
            ? ''
            : QrContentBuilder.contact(
                name: t('name'),
                phone: t('phone'),
                email: t('to'),
                organization: t('org'),
                title: t('title'),
                website: t('website'),
                address: t('address'));
      case GenType.crypto:
        return t('crypto_address').isEmpty
            ? ''
            : QrContentBuilder.crypto(
                network: _cryptoNetwork,
                address: t('crypto_address'),
                amount: double.tryParse(t('amount')));
    }
  }

  Future<void> _pickLogo() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _style = _style.copyWith(embeddedLogoPath: file.path));
    }
  }

  Future<void> _saveAndShare() async {
    final content = _content;
    if (content.isEmpty) return;
    setState(() => _busy = true);
    try {
      final bytes = await _export.capturePng(_repaintKey);
      await _export.saveToGallery(bytes, name: 'qr_${_type.name}');
      final path = await _export.writeTempPng(bytes, name: _type.name);

      // Persist as a generated record.
      await ref.read(historyProvider.notifier).add(
            ScanRecord(
              id: const Uuid().v4(),
              content: content,
              format: 'QR Code',
              contentType: _type.contentType,
              createdAt: DateTime.now(),
              source: RecordSource.generated,
              styleConfig: _style,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('generate.saved_gallery'.tr())));
      await LaunchHelper.shareImage(path, text: content);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _content;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text('generate.title'.tr())),
      body: ListView(
        // extendBody: the bottom inset already includes the nav bar height +
        // system gesture inset, so pad past it to keep the Save button visible.
        padding: EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.sm,
            AppSpacing.base, MediaQuery.paddingOf(context).bottom + AppSpacing.xl),
        children: [
          // ─── Type selector ─────────────────────────────────────────────────
          _TypeSelector(
            selectedType: _type,
            onTypeSelected: _switchType,
          ).animate().fadeIn(duration: 400.ms).slideY(
                begin: -0.05, end: 0, duration: 400.ms, curve: Curves.easeOut),

          const SizedBox(height: AppSpacing.base),

          // ─── QR preview hero ───────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: Container(
              key: ValueKey(content.isEmpty),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B26) : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                border: isDark
                    ? Border.all(
                        color: Colors.white.withValues(alpha: 0.06))
                    : Border.all(
                        color: Colors.black.withValues(alpha: 0.04)),
                boxShadow: isDark
                    ? null
                    : AppShadows.md(Colors.black),
              ),
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  RepaintBoundary(
                    key: _repaintKey,
                    child: StyledQrView(
                        data: content, style: _style, size: 200),
                  ),
                  if (content.isEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'generate.enter_content'.tr(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ).animate().fadeIn(duration: 450.ms, delay: 80.ms).slideY(
                begin: 0.04, end: 0, duration: 450.ms, delay: 80.ms,
                curve: Curves.easeOut),

          const SizedBox(height: AppSpacing.lg),

          // ─── Form ──────────────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(_type),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildForm(),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ─── Divider ───────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(child: Divider(color: scheme.outlineVariant.withValues(alpha: 0.3))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'Style',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                ),
              ),
              Expanded(child: Divider(color: scheme.outlineVariant.withValues(alpha: 0.3))),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // ─── Style editor ──────────────────────────────────────────────────
          QrStyleEditor(
            style: _style,
            onChanged: (s) => setState(() => _style = s),
            onPickLogo: _pickLogo,
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

          const SizedBox(height: AppSpacing.lg),

          // ─── Save & Share button ───────────────────────────────────────────
          _SaveButton(
            busy: _busy,
            enabled: content.isNotEmpty && !_busy,
            onPressed: _saveAndShare,
          ).animate().fadeIn(duration: 400.ms, delay: 280.ms),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Per-type forms
  // ---------------------------------------------------------------------------
  List<Widget> _buildForm() {
    switch (_type) {
      case GenType.url:
        return [_field('url', 'https://example.com', keyboard: TextInputType.url)];
      case GenType.text:
        return [_field('text', 'generate.content'.tr(), maxLines: 4)];
      case GenType.wifi:
        return [
          _field('ssid', 'Network name (SSID)'),
          _field('password', 'Password'),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: _wifiSecurity,
            decoration: const InputDecoration(labelText: 'Security'),
            items: const [
              DropdownMenuItem(value: 'WPA', child: Text('WPA/WPA2')),
              DropdownMenuItem(value: 'WEP', child: Text('WEP')),
              DropdownMenuItem(value: 'nopass', child: Text('None')),
            ],
            onChanged: (v) => setState(() => _wifiSecurity = v ?? 'WPA'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hidden network'),
            value: _wifiHidden,
            onChanged: (v) => setState(() => _wifiHidden = v),
          ),
        ];
      case GenType.email:
        return [
          _field('to', 'name@example.com', keyboard: TextInputType.emailAddress),
          _field('subject', 'Subject'),
          _field('body', 'Message', maxLines: 3),
        ];
      case GenType.phone:
        return [_field('phone', '+1 555 000 1234', keyboard: TextInputType.phone)];
      case GenType.sms:
        return [
          _field('phone', '+1 555 000 1234', keyboard: TextInputType.phone),
          _field('sms_msg', 'Message', maxLines: 3),
        ];
      case GenType.geo:
        return [
          Row(
            children: [
              Expanded(
                  child: _field('lat', 'Latitude',
                      keyboard: TextInputType.number)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: _field('lng', 'Longitude',
                      keyboard: TextInputType.number)),
            ],
          ),
          _field('label', 'Label (optional)'),
        ];
      case GenType.contact:
        return [
          _field('name', 'Full name'),
          _field('phone', 'Phone', keyboard: TextInputType.phone),
          _field('to', 'Email', keyboard: TextInputType.emailAddress),
          _field('org', 'Organization'),
          _field('title', 'Job title'),
          _field('website', 'Website'),
          _field('address', 'Address'),
        ];
      case GenType.crypto:
        return [
          DropdownButtonFormField<String>(
            initialValue: _cryptoNetwork,
            decoration: const InputDecoration(labelText: 'Network'),
            items: const [
              DropdownMenuItem(value: 'bitcoin', child: Text('Bitcoin')),
              DropdownMenuItem(value: 'ethereum', child: Text('Ethereum')),
              DropdownMenuItem(value: 'litecoin', child: Text('Litecoin')),
            ],
            onChanged: (v) => setState(() => _cryptoNetwork = v ?? 'bitcoin'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _field('crypto_address', 'Wallet address'),
          _field('amount', 'Amount (optional)', keyboard: TextInputType.number),
        ];
    }
  }

  Widget _field(String key, String hint,
      {TextInputType? keyboard, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: _c[key],
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(hintText: hint),
      ),
    );
  }
}

// ─── Type Selector ───────────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.selectedType,
    required this.onTypeSelected,
  });

  final GenType selectedType;
  final ValueChanged<GenType> onTypeSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: GenType.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final type = GenType.values[i];
          final selected = type == selectedType;
          return _TypeChip(
            icon: type.icon,
            label: type.label,
            selected: selected,
            onTap: () => onTypeSelected(type),
            accentColor: scheme.primary,
            isDark: isDark,
          );
        },
      ),
    );
  }
}

class _TypeChip extends StatefulWidget {
  const _TypeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.accentColor,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accentColor;
  final bool isDark;

  @override
  State<_TypeChip> createState() => _TypeChipState();
}

class _TypeChipState extends State<_TypeChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: widget.selected
                ? widget.accentColor
                : widget.isDark
                    ? const Color(0xFF161B26)
                    : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: widget.selected
                ? null
                : Border.all(
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
            boxShadow: widget.selected
                ? AppShadows.sm(widget.accentColor)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.selected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.selected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Save Button ─────────────────────────────────────────────────────────────

class _SaveButton extends StatefulWidget {
  const _SaveButton({
    required this.busy,
    required this.enabled,
    required this.onPressed,
  });

  final bool busy;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          decoration: BoxDecoration(
            gradient: widget.enabled
                ? LinearGradient(
                    colors: [scheme.primary, scheme.tertiary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: widget.enabled ? null : scheme.onSurface.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow:
                widget.enabled ? AppShadows.md(scheme.primary) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.busy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                const Icon(Icons.ios_share_rounded,
                    color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'generate.save_share'.tr(),
                style: GoogleFonts.manrope(
                  color: widget.enabled
                      ? Colors.white
                      : scheme.onSurface.withValues(alpha: 0.35),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
