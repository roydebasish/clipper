import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/clipboard_item_model.dart';
import '../../domain/entities/clipboard_item.dart';

class ClipboardLocalStorage {
  static final ClipboardLocalStorage instance = ClipboardLocalStorage._internal();
  ClipboardLocalStorage._internal();

  File? _file;

  Future<File> _getFile() async {
    if (_file != null) return _file!;
    final dir = await getApplicationSupportDirectory();
    final dataDir = Directory(p.join(dir.path, 'database'));
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }
    _file = File(p.join(dataDir.path, 'clipboard_history.json'));
    return _file!;
  }

  Future<List<ClipboardItem>> loadItems() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return [];
      }
      final content = await file.readAsString();
      if (content.isEmpty) return [];
      final List decoded = jsonDecode(content);
      return decoded.map((e) => ClipboardItemModel.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveItems(List<ClipboardItem> items) async {
    try {
      final file = await _getFile();
      final models = items.map((item) {
        if (item is ClipboardItemModel) {
          return item.toMap();
        }
        return ClipboardItemModel(
          id: item.id,
          type: item.type,
          content: item.content,
          title: item.title,
          preview: item.preview,
          filePath: item.filePath,
          sourceAppName: item.sourceAppName,
          sourceAppBundleId: item.sourceAppBundleId,
          createdAt: item.createdAt,
          lastCopiedAt: item.lastCopiedAt,
          copyCount: item.copyCount,
          position: item.position,
          isPinned: item.isPinned,
          isFavorite: item.isFavorite,
          isSensitive: item.isSensitive,
          collection: item.collection,
          tags: item.tags,
        ).toMap();
      }).toList();
      await file.writeAsString(jsonEncode(models));
    } catch (_) {}
  }
}
