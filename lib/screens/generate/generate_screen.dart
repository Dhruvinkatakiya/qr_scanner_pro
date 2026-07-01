import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../models/content_type.dart';
import '../../models/qr_style_config.dart';
import '../../models/scan_record.dart';
import '../../providers/history_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/qr_content_builder.dart';
import '../../services/qr_export_service.dart';
import '../../utils/launch_helper.dart';
import '../../widgets/styled_qr_view.dart';
import '../paywall/paywall_screen.dart';
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

class _GenerateScreenState extends ConsumerState<GenerateScreen> {
  final _repaintKey = GlobalKey();
  final _picker = ImagePicker();
  final _export = const QrExportService();

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
    for (final k in _fieldKeys) {
      _c[k] = TextEditingController()..addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() => setState(() {});

  String t(String key) => _c[key]!.text.trim();

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

  bool get _isPro => ref.read(subscriptionProvider).isPro;

  void _openPaywall() => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaywallScreen()));

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
    return Scaffold(
      appBar: AppBar(title: Text('generate.title'.tr())),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: GenType.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final type = GenType.values[i];
                final selected = type == _type;
                return ChoiceChip(
                  avatar: Icon(type.icon,
                      size: 18,
                      color: selected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant),
                  label: Text(type.label),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                      fontWeight: FontWeight.w600),
                  onSelected: (_) => setState(() => _type = type),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: RepaintBoundary(
              key: _repaintKey,
              child: StyledQrView(data: content, style: _style, size: 220),
            ),
          ),
          if (content.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('generate.enter_content'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          const SizedBox(height: 20),
          ..._buildForm(),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          QrStyleEditor(
            style: _style,
            isPro: _isPro,
            onChanged: (s) => setState(() => _style = s),
            onPickLogo: _pickLogo,
            onUpgrade: _openPaywall,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: (content.isEmpty || _busy) ? null : _saveAndShare,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.ios_share_rounded),
            label: Text('generate.save_share'.tr()),
          ),
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
          const SizedBox(height: 8),
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
              const SizedBox(width: 12),
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
          const SizedBox(height: 8),
          _field('crypto_address', 'Wallet address'),
          _field('amount', 'Amount (optional)',
              keyboard: TextInputType.number),
        ];
    }
  }

  Widget _field(String key, String hint,
      {TextInputType? keyboard, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _c[key],
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(hintText: hint),
      ),
    );
  }
}
