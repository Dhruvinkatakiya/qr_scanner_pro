import 'content_type.dart';
import 'qr_style_config.dart';

/// The primary persisted entity: a single scanned or generated code.
///
/// Stored as JSON inside Hive (offline-first) and mirrored to Firestore for Pro
/// users who enable cloud sync. Everything is nullable-safe so old records keep
/// deserialising as the schema grows.
class ScanRecord {
  ScanRecord({
    required this.id,
    required this.content,
    required this.format,
    required this.contentType,
    required this.createdAt,
    this.source = RecordSource.scanned,
    this.isFavorite = false,
    this.folderId,
    this.note,
    this.styleConfig,
    this.updatedAt,
  });

  /// UUID v4.
  final String id;

  /// Raw decoded payload (the exact string in the barcode).
  final String content;

  /// Barcode symbology name, e.g. `qrCode`, `ean13`, `code128`.
  final String format;

  final ContentType contentType;
  final DateTime createdAt;
  final RecordSource source;

  final bool isFavorite;
  final String? folderId;
  final String? note;

  /// Only present for [RecordSource.generated] records.
  final QrStyleConfig? styleConfig;

  /// Last local mutation time — used for last-writer-wins cloud sync.
  final DateTime? updatedAt;

  bool get isGenerated => source == RecordSource.generated;

  ScanRecord copyWith({
    String? content,
    ContentType? contentType,
    bool? isFavorite,
    String? folderId,
    bool clearFolder = false,
    String? note,
    QrStyleConfig? styleConfig,
    DateTime? updatedAt,
  }) {
    return ScanRecord(
      id: id,
      content: content ?? this.content,
      format: format,
      contentType: contentType ?? this.contentType,
      createdAt: createdAt,
      source: source,
      isFavorite: isFavorite ?? this.isFavorite,
      folderId: clearFolder ? null : (folderId ?? this.folderId),
      note: note ?? this.note,
      styleConfig: styleConfig ?? this.styleConfig,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'format': format,
        'contentType': contentType.name,
        'createdAt': createdAt.toIso8601String(),
        'source': source.name,
        'isFavorite': isFavorite,
        'folderId': folderId,
        'note': note,
        'styleConfig': styleConfig?.toJson(),
        'updatedAt': (updatedAt ?? createdAt).toIso8601String(),
      };

  factory ScanRecord.fromJson(Map<String, dynamic> json) {
    return ScanRecord(
      id: json['id'] as String,
      content: json['content'] as String? ?? '',
      format: json['format'] as String? ?? 'unknown',
      contentType: ContentType.fromName(json['contentType'] as String?),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
              DateTime.now(),
      source: json['source'] == RecordSource.generated.name
          ? RecordSource.generated
          : RecordSource.scanned,
      isFavorite: json['isFavorite'] as bool? ?? false,
      folderId: json['folderId'] as String?,
      note: json['note'] as String?,
      styleConfig: json['styleConfig'] == null
          ? null
          : QrStyleConfig.fromJson(
              Map<String, dynamic>.from(json['styleConfig'] as Map)),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}
