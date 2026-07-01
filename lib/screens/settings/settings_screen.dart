import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/history_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/launch_helper.dart';
import '../paywall/paywall_screen.dart';

const _languages = {
  'en': 'English',
  'es': 'Español',
  'fr': 'Français',
  'de': 'Deutsch',
  'pt': 'Português',
  'hi': 'हिन्दी',
};

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final sub = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: Text('settings.title'.tr())),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Premium banner
          _ProCard(isPro: sub.isPro),
          const SizedBox(height: 20),

          _SectionCard(
            title: 'settings.appearance'.tr(),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('settings.theme_system'.tr())),
                    ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('settings.theme_light'.tr())),
                    ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('settings.theme_dark'.tr())),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (s) => notifier.setThemeMode(s.first),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('settings.accent'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final c in AccentColors.options)
                    GestureDetector(
                      onTap: () => notifier.setAccentColor(c),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: settings.accentColor.toARGB32() ==
                                    c.toARGB32()
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: settings.accentColor.toARGB32() == c.toARGB32()
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.language_rounded),
                title: Text('settings.language'.tr()),
                trailing: Text(
                  _languages[context.locale.languageCode] ?? 'English',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                onTap: () => _pickLanguage(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _SectionCard(
            title: 'settings.feedback'.tr(),
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.volume_up_rounded),
                title: Text('settings.sound'.tr()),
                value: settings.soundEnabled,
                onChanged: notifier.setSoundEnabled,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.vibration_rounded),
                title: Text('settings.haptics'.tr()),
                value: settings.hapticsEnabled,
                onChanged: notifier.setHapticsEnabled,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.link_rounded),
                title: Text('settings.auto_open'.tr()),
                value: settings.autoOpenLinks,
                onChanged: notifier.setAutoOpenLinks,
              ),
            ],
          ),
          const SizedBox(height: 16),

          _SectionCard(
            title: 'settings.account'.tr(),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.ios_share_rounded),
                title: Text('settings.export'.tr()),
                subtitle: Text('settings.export_desc'.tr()),
                onTap: () => _exportBackup(context, ref),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.download_rounded),
                title: Text('settings.import'.tr()),
                subtitle: Text('settings.import_desc'.tr()),
                onTap: () => _importBackup(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _SectionCard(
            title: 'settings.premium'.tr(),
            children: [
              if (sub.isPro)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.verified_rounded,
                      color: Color(0xFF23A455)),
                  title: Text(sub.displayName),
                  trailing: TextButton(
                    onPressed: () =>
                        LaunchHelper.openUrl(AppConstants.playStoreUrl),
                    child: Text('settings.manage_sub'.tr()),
                  ),
                )
              else
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.workspace_premium_rounded,
                      color: Color(0xFFF7931A)),
                  title: Text('settings.go_pro'.tr()),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  ),
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.restore_rounded),
                title: Text('settings.restore_purchases'.tr()),
                onTap: () =>
                    ref.read(subscriptionProvider.notifier).restore(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _SectionCard(
            title: 'settings.about'.tr(),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.privacy_tip_rounded),
                title: Text('settings.privacy'.tr()),
                onTap: () =>
                    LaunchHelper.openUrl(AppConstants.privacyPolicyUrl),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.star_rate_rounded),
                title: Text('settings.rate'.tr()),
                onTap: () => LaunchHelper.openUrl(AppConstants.playStoreUrl),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.support_agent_rounded),
                title: Text('settings.contact'.tr()),
                onTap: () => LaunchHelper.email(AppConstants.supportEmail,
                    subject: 'QR Scanner Pro support'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline_rounded),
                title: Text('settings.version'.tr()),
                trailing: const Text('1.0.0'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickLanguage(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in _languages.entries)
              ListTile(
                title: Text(entry.value),
                trailing: context.locale.languageCode == entry.key
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () {
                  context.setLocale(Locale(entry.key));
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final records = ref.read(historyProvider);
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('history.empty_title'.tr())));
      return;
    }
    final folders = ref.read(foldersProvider);
    try {
      await ref.read(backupServiceProvider).exportAndShare(records, folders);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final json = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('settings.import'.tr()),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 6,
          decoration: InputDecoration(hintText: 'settings.import_hint'.tr()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('common.cancel'.tr())),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text('common.done'.tr())),
        ],
      ),
    );
    if (json == null || json.isEmpty) return;
    try {
      final data = ref.read(backupServiceProvider).parse(json);
      await ref.read(foldersProvider.notifier).importAll(data.folders);
      final added =
          await ref.read(historyProvider.notifier).importAll(data.records);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('settings.import_done'.tr(args: ['$added']))));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('settings.import_error'.tr())));
      }
    }
  }
}

class _ProCard extends StatelessWidget {
  const _ProCard({required this.isPro});
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    if (isPro) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF23A455), Color(0xFF1B8F49)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: Colors.white, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Text('paywall.already_pro'.tr(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFF7B733), Color(0xFFF7931A)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('settings.go_pro'.tr(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900)),
                  Text('paywall.subtitle'.tr(),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.4)),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}
