import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/content_type.dart';
import '../../models/parsed_content.dart';
import '../../models/scan_record.dart';
import '../../providers/history_provider.dart';
import '../../providers/service_providers.dart';
import '../../utils/formatters.dart';
import '../../utils/launch_helper.dart';

class _QuickAction {
  const _QuickAction(this.icon, this.label, this.color, this.onTap);
  final IconData icon;
  final String label;
  final Color color;
  final Future<void> Function() onTap;
}

/// Rich result view for a single record: type-aware fields, URL safety banner
/// and a grid of quick actions.
class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.recordId});

  final String recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch so the favourite star / note reflect edits immediately.
    final record = ref.watch(historyProvider
        .select((list) => list.where((r) => r.id == recordId).firstOrNull));

    if (record == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('result.title'.tr())),
      );
    }

    final parsed = ref.read(qrParserServiceProvider).parse(record.content);

    return Scaffold(
      appBar: AppBar(
        title: Text('result.title'.tr()),
        actions: [
          IconButton(
            tooltip: record.isFavorite
                ? 'common.unfavorite'.tr()
                : 'common.favorite'.tr(),
            icon: Icon(
              record.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: record.isFavorite ? const Color(0xFFF7931A) : null,
            ),
            onPressed: () =>
                ref.read(historyProvider.notifier).toggleFavorite(record.id),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => _onMenu(context, ref, v, record),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'note', child: Text('result.add_note'.tr())),
              PopupMenuItem(value: 'delete', child: Text('common.delete'.tr())),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Header(parsed: parsed, record: record),
          if (parsed.safety != null && parsed.safety!.isSuspicious) ...[
            const SizedBox(height: 16),
            _SafetyBanner(safety: parsed.safety!),
          ],
          const SizedBox(height: 16),
          _ContentCard(parsed: parsed),
          const SizedBox(height: 20),
          _ActionsGrid(actions: _buildActions(context, ref, parsed)),
          if ((record.note ?? '').isNotEmpty) ...[
            const SizedBox(height: 16),
            _NoteCard(note: record.note!),
          ],
        ],
      ),
    );
  }

  Future<void> _onMenu(
      BuildContext context, WidgetRef ref, String value, ScanRecord record) async {
    if (value == 'note') {
      await _editNote(context, ref, record);
    } else if (value == 'delete') {
      await ref.read(historyProvider.notifier).delete(record.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _editNote(
      BuildContext context, WidgetRef ref, ScanRecord record) async {
    final controller = TextEditingController(text: record.note ?? '');
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('result.add_note'.tr()),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(hintText: '…'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('common.cancel'.tr())),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: Text('common.save'.tr())),
        ],
      ),
    );
    if (note != null) {
      await ref.read(historyProvider.notifier).setNote(record.id, note);
    }
  }

  List<_QuickAction> _buildActions(
      BuildContext context, WidgetRef ref, ParsedContent parsed) {
    Future<void> toast(String msg) async {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }

    final copy = _QuickAction(Icons.copy_rounded, 'common.copy'.tr(),
        const Color(0xFF6B7280), () async {
      await LaunchHelper.copy(parsed.raw);
      await toast('common.copied'.tr());
    });
    final share = _QuickAction(Icons.share_rounded, 'common.share'.tr(),
        const Color(0xFF2F6BFF), () => LaunchHelper.shareText(parsed.raw));

    switch (parsed.type) {
      case ContentType.url:
        return [
          _QuickAction(Icons.open_in_new_rounded, 'common.open'.tr(),
              parsed.type.color, () => _openUrl(context, parsed)),
          copy,
          share,
        ];
      case ContentType.wifi:
        return [
          _QuickAction(Icons.copy_rounded, 'Password', const Color(0xFF00A88E),
              () async {
            await LaunchHelper.copy(parsed.fields['Password'] ?? '');
            await toast('common.copied'.tr());
          }),
          share,
        ];
      case ContentType.contact:
        return [
          if (parsed.fields['Phone'] != null)
            _QuickAction(Icons.call_rounded, 'common.call'.tr(),
                const Color(0xFF23A455),
                () => LaunchHelper.dial(parsed.fields['Phone']!)),
          if (parsed.fields['Phone'] != null)
            _QuickAction(Icons.message_rounded, 'common.message'.tr(),
                const Color(0xFF1FA2C4),
                () => LaunchHelper.sms(parsed.fields['Phone']!)),
          if (parsed.fields['Email'] != null)
            _QuickAction(Icons.email_rounded, 'common.email'.tr(),
                const Color(0xFFEA6A47),
                () => LaunchHelper.email(parsed.fields['Email']!)),
          share,
        ];
      case ContentType.email:
        return [
          _QuickAction(Icons.email_rounded, 'common.email'.tr(),
              parsed.type.color,
              () => LaunchHelper.email(parsed.fields['To'] ?? parsed.title,
                  subject: parsed.fields['Subject'],
                  body: parsed.fields['Message'])),
          copy,
          share,
        ];
      case ContentType.phone:
        return [
          _QuickAction(Icons.call_rounded, 'common.call'.tr(),
              parsed.type.color, () => LaunchHelper.dial(parsed.title)),
          _QuickAction(Icons.message_rounded, 'common.message'.tr(),
              const Color(0xFF1FA2C4), () => LaunchHelper.sms(parsed.title)),
          copy,
        ];
      case ContentType.sms:
        return [
          _QuickAction(Icons.message_rounded, 'common.message'.tr(),
              parsed.type.color,
              () => LaunchHelper.sms(parsed.fields['Number'] ?? parsed.title,
                  body: parsed.fields['Message'])),
          copy,
        ];
      case ContentType.geo:
        return [
          _QuickAction(Icons.map_rounded, 'common.open_maps'.tr(),
              parsed.type.color,
              () => LaunchHelper.openMaps(
                  parsed.fields['Latitude'] ?? '', parsed.fields['Longitude'] ?? '',
                  label: parsed.fields['Label'])),
          copy,
          share,
        ];
      case ContentType.calendar:
        return [
          _QuickAction(Icons.event_rounded, 'common.add_to_calendar'.tr(),
              parsed.type.color, () => LaunchHelper.shareText(parsed.raw)),
          copy,
        ];
      case ContentType.crypto:
        return [
          _QuickAction(Icons.copy_rounded, 'Address', parsed.type.color,
              () async {
            await LaunchHelper.copy(parsed.fields['Address'] ?? parsed.raw);
            await toast('common.copied'.tr());
          }),
          share,
        ];
      case ContentType.product:
      case ContentType.text:
        return [copy, share];
    }
  }

  Future<void> _openUrl(BuildContext context, ParsedContent parsed) async {
    final safety = parsed.safety;
    if (safety != null && safety.isSuspicious) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.gpp_maybe_rounded, color: Color(0xFFE0553D)),
          title: Text('result.suspicious'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(safety.domain,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...safety.reasons.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $r'),
                  )),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('common.cancel'.tr())),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('result.open_anyway'.tr())),
          ],
        ),
      );
      if (proceed != true) return;
    }
    await LaunchHelper.openUrl(parsed.raw);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.parsed, required this.record});
  final ParsedContent parsed;
  final ScanRecord record;

  @override
  Widget build(BuildContext context) {
    final type = parsed.type;
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: type.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(type.icon, color: type.color, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type.label,
                  style: TextStyle(
                      color: type.color, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(
                '${record.format} · ${Formatters.relative(record.createdAt)}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SafetyBanner extends StatelessWidget {
  const _SafetyBanner({required this.safety});
  final UrlSafety safety;

  @override
  Widget build(BuildContext context) {
    final danger = safety.level == SafetyLevel.danger;
    final color = danger ? const Color(0xFFE0553D) : const Color(0xFFF7931A);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(danger ? Icons.dangerous_rounded : Icons.warning_amber_rounded,
              color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  danger ? 'result.suspicious'.tr() : 'result.caution'.tr(),
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                ...safety.reasons.map((r) => Text('• $r',
                    style: Theme.of(context).textTheme.bodySmall)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.parsed});
  final ParsedContent parsed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: parsed.fields.isEmpty
            ? SelectableText(parsed.raw,
                style: const TextStyle(fontSize: 15, height: 1.4))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in parsed.fields.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key.toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline,
                                      letterSpacing: 0.6)),
                          const SizedBox(height: 2),
                          SelectableText(entry.value,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _ActionsGrid extends StatelessWidget {
  const _ActionsGrid({required this.actions});
  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final a in actions)
          SizedBox(
            width: (MediaQuery.sizeOf(context).width - 32 - 24) / 3,
            child: _ActionButton(action: a),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});
  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: action.color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(action.icon, color: action.color),
            const SizedBox(height: 8),
            Text(action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: action.color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});
  final String note;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.sticky_note_2_rounded),
        title: Text(note),
      ),
    );
  }
}
