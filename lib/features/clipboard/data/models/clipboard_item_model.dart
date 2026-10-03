import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/clipboard_item.dart';

class ClipboardItemModel extends ClipboardItem {
  const ClipboardItemModel({
    required super.id,
    required super.type,
    required super.content,
    required super.title,
    required super.preview,
    super.filePath,
    required super.sourceAppName,
    required super.sourceAppBundleId,
    required super.createdAt,
    required super.lastCopiedAt,
    super.copyCount,
    super.position,
    super.isPinned,
    super.isFavorite,
    super.isSensitive,
    super.collection,
    super.tags,
  });

  factory ClipboardItemModel.fromNativePayload(Map<String, dynamic> payload) {
    final timestamp = payload['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final rawType = payload['type'] as String? ?? 'TEXT';
    final content = payload['content'] as String? ?? '';
    final title = payload['title'] as String? ?? (content.length > 50 ? '${content.substring(0, 50)}...' : content);
    final preview = payload['preview'] as String? ?? (content.length > 150 ? '${content.substring(0, 150)}...' : content);

    // Simple sensitive data detection pattern
    final isSensitive = _detectSensitive(content);

    return ClipboardItemModel(
      id: payload['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      type: ClipboardType.fromString(rawType),
      content: content,
      title: title,
      preview: preview,
      filePath: payload['filePath'] as String?,
      sourceAppName: payload['sourceAppName'] as String? ?? 'System',
      sourceAppBundleId: payload['sourceAppBundleId'] as String? ?? '',
      createdAt: date,
      lastCopiedAt: date,
      copyCount: 1,
      position: 0,
      isPinned: false,
      isFavorite: false,
      isSensitive: isSensitive,
      collection: null,
      tags: const [],
    );
  }

  factory ClipboardItemModel.fromMap(Map<String, dynamic> map) {
    return ClipboardItemModel(
      id: map['id'] as String,
      type: ClipboardType.fromString(map['type'] as String? ?? 'TEXT'),
      content: map['content'] as String? ?? '',
      title: map['title'] as String? ?? '',
      preview: map['preview'] as String? ?? '',
      filePath: map['filePath'] as String?,
      sourceAppName: map['sourceAppName'] as String? ?? '',
      sourceAppBundleId: map['sourceAppBundleId'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      lastCopiedAt: DateTime.tryParse(map['lastCopiedAt'] as String? ?? '') ?? DateTime.now(),
      copyCount: (map['copyCount'] as num?)?.toInt() ?? 1,
      position: (map['position'] as num?)?.toInt() ?? 0,
      isPinned: map['isPinned'] == true,
      isFavorite: map['isFavorite'] == true,
      isSensitive: map['isSensitive'] == true,
      collection: map['collection'] as String?,
      tags: (map['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'content': content,
      'title': title,
      'preview': preview,
      'filePath': filePath,
      'sourceAppName': sourceAppName,
      'sourceAppBundleId': sourceAppBundleId,
      'createdAt': createdAt.toIso8601String(),
      'lastCopiedAt': lastCopiedAt.toIso8601String(),
      'copyCount': copyCount,
      'position': position,
      'isPinned': isPinned,
      'isFavorite': isFavorite,
      'isSensitive': isSensitive,
      'collection': collection,
      'tags': tags,
    };
  }

  static bool _detectSensitive(String content) {
    final lower = content.toLowerCase();
    // Look for common sensitive patterns (JWT tokens, private keys, auth headers, API key prefixes)
    if (content.contains('-----BEGIN PRIVATE KEY-----') ||
        content.contains('-----BEGIN RSA PRIVATE KEY-----') ||
        lower.contains('eyj') && content.length > 80 && content.contains('.') ||
        lower.startsWith('ghp_') ||
        lower.startsWith('sk_live_') ||
        lower.startsWith('bearer ')) {
      return true;
    }
    return false;
  }
}
