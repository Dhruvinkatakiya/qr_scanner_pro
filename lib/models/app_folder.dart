/// A user-created folder used to organise saved scans (e.g. "Work",
/// "Receipts"). Folders are a Pro organisational feature but the model itself
/// is always available.
class AppFolder {
  const AppFolder({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.createdAt,
  });

  final String id;
  final String name;
  final int colorValue;
  final DateTime createdAt;

  AppFolder copyWith({String? name, int? colorValue}) => AppFolder(
        id: id,
        name: name ?? this.name,
        colorValue: colorValue ?? this.colorValue,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppFolder.fromJson(Map<String, dynamic> json) => AppFolder(
        id: json['id'] as String,
        name: json['name'] as String,
        colorValue: (json['colorValue'] as num).toInt(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
