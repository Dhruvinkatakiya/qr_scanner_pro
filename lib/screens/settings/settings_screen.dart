import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/history_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/launch_helper.dart';

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

    return Scaffold(
      appBar: AppBar(title: Text('settings.title'.tr())),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.base, AppSpacing.sm, AppSpacing.base, 40),
        children: [
          // ─── Rate / Share banner ───────────────────────────────────────
          _RateBanner().animate().fadeIn(duration: 400.ms).slideY(
                begin: -0.04, end: 0, duration: 400.ms, curve: Curves.easeOut),
          const SizedBox(height: AppSpacing.lg),

          // ─── Appearance ────────────────────────────────────────────────
          _SectionCard(
            title: 'settings.appearance'.tr(),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'settings.accent'.tr(),
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Glow-ring accent picker
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (final c in AccentColors.options)
                    _AccentSwatch(
                      color: c,
                      selected: settings.accentColor.toARGB32() == c.toARGB32(),
                      onTap: () => notifier.setAccentColor(c),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.language_rounded,
                    color: Theme.of(context).colorScheme.primary),
                title: Text('settings.language'.tr()),
                trailing: Text(
                  _languages[context.locale.languageCode] ?? 'English',
                  style: TextStyle(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                onTap: () => _pickLanguage(context),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 80.ms),

          const SizedBox(height: AppSpacing.base),

          // ─── Feedback ──────────────────────────────────────────────────
          _SectionCard(
            title: 'settings.feedback'.tr(),
            children: [
              _ToggleTile(
                icon: Icons.volume_up_rounded,
                title: 'settings.sound'.tr(),
                value: settings.soundEnabled,
                onChanged: notifier.setSoundEnabled,
              ),
              _ToggleTile(
                icon: Icons.vibration_rounded,
                title: 'settings.haptics'.tr(),
                value: settings.hapticsEnabled,
                onChanged: notifier.setHapticsEnabled,
              ),
              _ToggleTile(
                icon: Icons.link_rounded,
                title: 'settings.auto_open'.tr(),
                value: settings.autoOpenLinks,
                onChanged: notifier.setAutoOpenLinks,
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 120.ms),

          const SizedBox(height: AppSpacing.base),

          // ─── Data / Account ────────────────────────────────────────────
          _SectionCard(
            title: 'settings.account'.tr(),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(Icons.ios_share_rounded,
                      color: Theme.of(context).colorScheme.primary, size: 18),
                ),
                title: Text('settings.export'.tr()),
                subtitle: Text('settings.export_desc'.tr()),
                onTap: () => _exportBackup(context, ref),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.download_rounded,
                      color: Color(0xFF22C55E), size: 18),
                ),
                title: Text('settings.import'.tr()),
                subtitle: Text('settings.import_desc'.tr()),
                onTap: () => _importBackup(context, ref),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 160.ms),

          const SizedBox(height: AppSpacing.base),

          // ─── About ─────────────────────────────────────────────────────
          _SectionCard(
            title: 'settings.about'.tr(),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _IconTile(
                    icon: Icons.privacy_tip_rounded,
                    color: const Color(0xFF7C5CFC)),
                title: Text('settings.privacy'.tr()),
                trailing: const Icon(Icons.open_in_new_rounded, size: 16),
                onTap: () =>
                    LaunchHelper.openUrl(AppConstants.privacyPolicyUrl),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _IconTile(
                    icon: Icons.star_rate_rounded,
                    color: const Color(0xFFF59E0B)),
                title: Text('settings.rate'.tr()),
                trailing: const Icon(Icons.open_in_new_rounded, size: 16),
                onTap: () => LaunchHelper.openUrl(AppConstants.playStoreUrl),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _IconTile(
                    icon: Icons.support_agent_rounded,
                    color: const Color(0xFF3B7FF5)),
                title: Text('settings.contact'.tr()),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                onTap: () => LaunchHelper.email(AppConstants.supportEmail,
                    subject: 'QR Scanner Pro support'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _IconTile(
                    icon: Icons.info_outline_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                title: Text('settings.version'.tr()),
                trailing: Text(
                  '1.0.0',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
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
            content:
                Text('settings.import_done'.tr(args: ['$added']))));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('settings.import_error'.tr())));
      }
    }
  }
}

// ─── Rate / Share Banner ─────────────────────────────────────────────────────

class _RateBanner extends StatefulWidget {
  @override
  State<_RateBanner> createState() => _RateBannerState();
}

class _RateBannerState extends State<_RateBanner> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) async {
        setState(() => _pressed = false);
        await SharePlus.instance.share(
          ShareParams(
            text: 'Check out QR Scanner Pro — a free, full-featured QR code scanner and generator!\n${AppConstants.playStoreUrl}',
          ),
        );
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0055FF), // Logo primary
                Color(0xFF00E5FF), // Logo cyan
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.md(const Color(0xFF0055FF)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Love using the scanner?',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Help us grow by leaving a quick rating ⭐',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Accent Colour Swatch ─────────────────────────────────────────────────────

class _AccentSwatch extends StatefulWidget {
  const _AccentSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_AccentSwatch> createState() => _AccentSwatchState();
}

class _AccentSwatchState extends State<_AccentSwatch> {
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
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.25),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ]
                : AppShadows.sm(widget.color),
            border: widget.selected
                ? Border.all(color: Colors.white, width: 2.5)
                : null,
          ),
          child: AnimatedOpacity(
            opacity: widget.selected ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B26) : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: isDark
                ? Border.all(color: Colors.white.withValues(alpha: 0.06))
                : null,
            boxShadow:
                isDark ? null : AppShadows.sm(Colors.black),
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base, vertical: AppSpacing.sm),
              child: Column(children: children),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Toggle Tile ──────────────────────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(
        icon,
        color: value
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}

// ─── Icon Tile ────────────────────────────────────────────────────────────────

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}
