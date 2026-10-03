import '../../../../core/constants/app_constants.dart';

class ClipboardItem {
  final String id;
  final ClipboardType type;
  final String content;
  final String title;
  final String preview;
  final String? filePath;
  final String sourceAppName;
  final String sourceAppBundleId;
  final DateTime createdAt;
  final DateTime lastCopiedAt;
  final int copyCount;
  final int position;
  final bool isPinned;
  final bool isFavorite;
  final bool isSensitive;
  final String? collection;
  final List<String> tags;

  const ClipboardItem({
    required this.id,
    required this.type,
    required this.content,
    required this.title,
    required this.preview,
    this.filePath,
    required this.sourceAppName,
    required this.sourceAppBundleId,
    required this.createdAt,
    required this.lastCopiedAt,
    this.copyCount = 1,
    this.position = 0,
    this.isPinned = false,
    this.isFavorite = false,
    this.isSensitive = false,
    this.collection,
    this.tags = const [],
  });

  ClipboardItem copyWith({
    String? id,
    ClipboardType? type,
    String? content,
    String? title,
    String? preview,
    String? filePath,
    String? sourceAppName,
    String? sourceAppBundleId,
    DateTime? createdAt,
    DateTime? lastCopiedAt,
    int? copyCount,
    int? position,
    bool? isPinned,
    bool? isFavorite,
    bool? isSensitive,
    String? collection,
    List<String>? tags,
  }) {
    return ClipboardItem(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      title: title ?? this.title,
      preview: preview ?? this.preview,
      filePath: filePath ?? this.filePath,
      sourceAppName: sourceAppName ?? this.sourceAppName,
      sourceAppBundleId: sourceAppBundleId ?? this.sourceAppBundleId,
      createdAt: createdAt ?? this.createdAt,
      lastCopiedAt: lastCopiedAt ?? this.lastCopiedAt,
      copyCount: copyCount ?? this.copyCount,
      position: position ?? this.position,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      isSensitive: isSensitive ?? this.isSensitive,
      collection: collection ?? this.collection,
      tags: tags ?? this.tags,
    );
  }
}
