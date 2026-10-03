import '../entities/clipboard_item.dart';

abstract class ClipboardRepository {
  Future<List<ClipboardItem>> getHistory();
  Future<void> saveHistory(List<ClipboardItem> items);
  Future<bool> writeToSystemClipboard(String content, {String type = 'TEXT'});
}
