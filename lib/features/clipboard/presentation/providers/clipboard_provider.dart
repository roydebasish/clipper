import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/native_clipboard_bridge.dart';
import '../../../../core/utils/text_transformations.dart';
import '../../data/datasources/clipboard_local_storage.dart';
import '../../data/models/clipboard_item_model.dart';
import '../../domain/entities/clipboard_item.dart';
import 'clipboard_state.dart';

final clipboardProvider = NotifierProvider<ClipboardNotifier, ClipboardState>(ClipboardNotifier.new);

class ClipboardNotifier extends Notifier<ClipboardState> {
  final NativeClipboardBridge bridge = NativeClipboardBridge.instance;
  final ClipboardLocalStorage storage = ClipboardLocalStorage.instance;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  @override
  ClipboardState build() {
    ref.onDispose(() {
      _subscription?.cancel();
    });

    // Schedule async initialization after build returns initial state
    Future.microtask(() => _init());

    return const ClipboardState(isLoading: true);
  }

  Future<void> _init() async {
    // 1. Load persisted history
    final savedItems = await storage.loadItems();
    state = state.copyWith(items: savedItems, isLoading: false);

    // 2. Attach MenuBar and Global Shortcut callbacks
    bridge.onClearHistoryRequested = () {
      deleteAll(exceptPinned: true);
    };
    bridge.onItemCopiedFromMenuBar = (itemMap) {
      final id = itemMap['id'] as String?;
      if (id != null) {
        final item = state.items.where((e) => e.id == id).firstOrNull;
        if (item != null) {
          copyItem(item);
        }
      }
    };
    bridge.onItemDeletedFromMenuBar = (id) {
      deleteItem(id);
    };

    // 3. Listen to Native EventChannel for real-time clipboard changes
    _subscription = bridge.clipboardStream.listen(
      _onNativeClipboardChanged,
      onError: (err) {
        // Ignored or logged safely
      },
    );

    // 4. Start native monitoring
    await bridge.startMonitoring();
    _syncMenuBar();
  }

  void _onNativeClipboardChanged(Map<String, dynamic> payload) {
    if (state.isPaused) return;

    final newItem = ClipboardItemModel.fromNativePayload(payload);
    if (newItem.content.isEmpty) return;

    final existingIndex = state.items.indexWhere((e) => e.content == newItem.content);

    List<ClipboardItem> updatedList = List.from(state.items);

    if (existingIndex != -1) {
      switch (state.duplicateHandling) {
        case DuplicateHandlingOption.moveToTop:
          final existing = updatedList.removeAt(existingIndex);
          final updated = existing.copyWith(
            lastCopiedAt: DateTime.now(),
            copyCount: existing.copyCount + 1,
            sourceAppName: newItem.sourceAppName.isNotEmpty ? newItem.sourceAppName : existing.sourceAppName,
            sourceAppBundleId: newItem.sourceAppBundleId.isNotEmpty ? newItem.sourceAppBundleId : existing.sourceAppBundleId,
          );
          updatedList.insert(0, updated);
          break;

        case DuplicateHandlingOption.ignoreDuplicate:
          return;

        case DuplicateHandlingOption.keepDuplicates:
          updatedList.insert(0, newItem);
          break;
      }
    } else {
      updatedList.insert(0, newItem);
    }

    state = state.copyWith(items: updatedList);
    storage.saveItems(updatedList);
    _syncMenuBar();
  }

  Future<void> copyItem(ClipboardItem item) async {
    await bridge.writeClipboard(
      item.content,
      type: item.type.name.toUpperCase(),
      filePath: item.filePath,
    );

    // Increment copy count and update last copied time
    final updatedList = state.items.map((e) {
      if (e.id == item.id) {
        return e.copyWith(
          copyCount: e.copyCount + 1,
          lastCopiedAt: DateTime.now(),
        );
      }
      return e;
    }).toList();

    state = state.copyWith(
      items: updatedList,
      statusMessage: 'Copied to clipboard!',
    );
    await storage.saveItems(updatedList);
    _syncMenuBar();
  }

  Future<void> deleteItem(String id) async {
    final updatedList = state.items.where((e) => e.id != id).toList();
    final updatedSelected = Set<String>.from(state.selectedIds)..remove(id);
    state = state.copyWith(
      items: updatedList,
      selectedIds: updatedSelected,
      statusMessage: 'Item removed',
    );
    await storage.saveItems(updatedList);
    _syncMenuBar();
  }

  Future<void> deleteSelected() async {
    if (state.selectedIds.isEmpty) return;
    final updatedList = state.items.where((e) => !state.selectedIds.contains(e.id)).toList();
    final count = state.selectedIds.length;
    state = state.copyWith(
      items: updatedList,
      selectedIds: {},
      isSelectionMode: false,
      statusMessage: '$count items deleted',
    );
    await storage.saveItems(updatedList);
  }

  Future<void> deleteAll({bool exceptPinned = false}) async {
    List<ClipboardItem> remaining;
    if (exceptPinned) {
      remaining = state.items.where((e) => e.isPinned).toList();
    } else {
      remaining = [];
    }
    state = state.copyWith(
      items: remaining,
      selectedIds: {},
      isSelectionMode: false,
      statusMessage: exceptPinned ? 'History cleared (pinned items kept)' : 'All clipboard history deleted',
    );
    await storage.saveItems(remaining);
  }

  Future<void> togglePin(String id) async {
    final updatedList = state.items.map((e) {
      if (e.id == id) {
        return e.copyWith(isPinned: !e.isPinned);
      }
      return e;
    }).toList();
    state = state.copyWith(items: updatedList);
    await storage.saveItems(updatedList);
  }

  Future<void> toggleFavorite(String id) async {
    final updatedList = state.items.map((e) {
      if (e.id == id) {
        return e.copyWith(isFavorite: !e.isFavorite);
      }
      return e;
    }).toList();
    state = state.copyWith(items: updatedList);
    await storage.saveItems(updatedList);
  }

  Future<void> moveToTop(String id) async {
    final index = state.items.indexWhere((e) => e.id == id);
    if (index > 0) {
      final updatedList = List<ClipboardItem>.from(state.items);
      final item = updatedList.removeAt(index);
      updatedList.insert(0, item);
      state = state.copyWith(items: updatedList);
      await storage.saveItems(updatedList);
    }
  }

  Future<void> moveToBottom(String id) async {
    final index = state.items.indexWhere((e) => e.id == id);
    if (index != -1 && index < state.items.length - 1) {
      final updatedList = List<ClipboardItem>.from(state.items);
      final item = updatedList.removeAt(index);
      updatedList.add(item);
      state = state.copyWith(items: updatedList);
      await storage.saveItems(updatedList);
    }
  }

  Future<void> reorderItem(int oldIndex, int newIndex) async {
    final filtered = state.filteredItems;
    if (oldIndex < 0 || oldIndex >= filtered.length) return;
    if (newIndex < 0 || newIndex > filtered.length) return;

    final targetItem = filtered[oldIndex];
    int targetNewIndex = newIndex;
    if (targetNewIndex > oldIndex) {
      targetNewIndex -= 1;
    }
    if (targetNewIndex < 0 || targetNewIndex >= filtered.length) return;
    final destinationItem = filtered[targetNewIndex];

    final updatedList = List<ClipboardItem>.from(state.items);
    final masterOldIndex = updatedList.indexWhere((e) => e.id == targetItem.id);
    if (masterOldIndex == -1) return;

    final item = updatedList.removeAt(masterOldIndex);

    int masterNewIndex = updatedList.indexWhere((e) => e.id == destinationItem.id);
    if (masterNewIndex == -1) {
      masterNewIndex = updatedList.length;
    } else if (newIndex > oldIndex) {
      masterNewIndex += 1;
    }

    if (masterNewIndex > updatedList.length) {
      masterNewIndex = updatedList.length;
    }

    updatedList.insert(masterNewIndex, item);
    state = state.copyWith(items: updatedList);
    await storage.saveItems(updatedList);
  }

  Future<void> updateContent(String id, String newContent) async {
    final updatedList = state.items.map((e) {
      if (e.id == id) {
        final title = newContent.length > 50 ? '${newContent.substring(0, 50)}...' : newContent;
        final preview = newContent.length > 150 ? '${newContent.substring(0, 150)}...' : newContent;
        return e.copyWith(
          content: newContent,
          title: title,
          preview: preview,
        );
      }
      return e;
    }).toList();
    state = state.copyWith(items: updatedList, statusMessage: 'Content updated');
    await storage.saveItems(updatedList);
  }

  Future<void> applyTransformation(String id, TransformationType type) async {
    final item = state.items.firstWhere((e) => e.id == id, orElse: () => throw 'Not found');
    final transformed = TextTransformations.apply(item.content, type);
    await updateContent(id, transformed);
    await copyItem(item.copyWith(content: transformed));
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setAppFilter(String? app) {
    state = state.copyWith(selectedAppFilter: app, clearAppFilter: app == null);
  }

  void toggleSelectionMode() {
    state = state.copyWith(
      isSelectionMode: !state.isSelectionMode,
      selectedIds: {},
    );
  }

  void toggleSelect(String id) {
    final newSet = Set<String>.from(state.selectedIds);
    if (newSet.contains(id)) {
      newSet.remove(id);
    } else {
      newSet.add(id);
    }
    state = state.copyWith(
      selectedIds: newSet,
      isSelectionMode: newSet.isNotEmpty || state.isSelectionMode,
    );
  }

  void selectAll() {
    final allIds = state.filteredItems.map((e) => e.id).toSet();
    state = state.copyWith(selectedIds: allIds, isSelectionMode: true);
  }

  void clearSelection() {
    state = state.copyWith(selectedIds: {}, isSelectionMode: false);
  }

  Future<void> pauseMonitoring({Duration? duration}) async {
    final seconds = duration?.inSeconds.toDouble();
    await bridge.pauseMonitoring(seconds: seconds);
    state = state.copyWith(isPaused: true);
  }

  Future<void> resumeMonitoring() async {
    await bridge.resumeMonitoring();
    state = state.copyWith(isPaused: false);
  }

  void _syncMenuBar() {
    final list = state.items.take(25).map((e) => {
      'id': e.id,
      'type': e.type.name,
      'title': e.title,
      'content': e.content,
      'preview': e.preview,
      'filePath': e.filePath,
      'sourceAppName': e.sourceAppName,
      'isPinned': e.isPinned,
    }).toList();
    bridge.updateMenuBarItems(list);
  }
}
