import 'package:flutter/material.dart';

import '../models/scan_record.dart';
import '../utils/formatters.dart';

/// Compact list row for a scan/generated record. Used on Home and History.
class RecordTile extends StatelessWidget {
  const RecordTile({
    super.key,
    required this.record,
    this.onTap,
    this.trailing,
  });

  final ScanRecord record;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final type = record.contentType;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: type.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(type.icon, color: type.color),
        ),
        title: Text(
          record.content,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Text(type.label,
                style: TextStyle(color: type.color, fontWeight: FontWeight.w600)),
            const Text('  ·  '),
            Flexible(
              child: Text(
                Formatters.relative(record.createdAt),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (record.isGenerated) ...[
              const SizedBox(width: 6),
              Icon(Icons.auto_awesome_rounded,
                  size: 13, color: Theme.of(context).colorScheme.outline),
            ],
          ],
        ),
        trailing: trailing ??
            (record.isFavorite
                ? const Icon(Icons.star_rounded, color: Color(0xFFF7931A))
                : null),
      ),
    );
  }
}
