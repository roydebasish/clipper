import '../../../../core/services/native_clipboard_bridge.dart';
import '../../domain/entities/clipboard_item.dart';
import '../../domain/repositories/clipboard_repository.dart';
import '../datasources/clipboard_local_storage.dart';

class ClipboardRepositoryImpl implements ClipboardRepository {
  final ClipboardLocalStorage localStorage;
  final NativeClipboardBridge nativeBridge;

  ClipboardRepositoryImpl({
    required this.localStorage,
    required this.nativeBridge,
  });

  @override
  Future<List<ClipboardItem>> getHistory() async {
    return await localStorage.loadItems();
  }

  @override
  Future<void> saveHistory(List<ClipboardItem> items) async {
    await localStorage.saveItems(items);
  }

  @override
  Future<bool> writeToSystemClipboard(String content, {String type = 'TEXT'}) async {
    return await nativeBridge.writeClipboard(content, type: type);
  }
}
