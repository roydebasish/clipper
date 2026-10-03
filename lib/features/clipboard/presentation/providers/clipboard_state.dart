import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/clipboard_item.dart';

enum DuplicateHandlingOption {
  moveToTop,
  keepDuplicates,
  ignoreDuplicate,
}

class ClipboardState {
  final List<ClipboardItem> items;
  final bool isLoading;
  final String searchQuery;
  final String selectedCategory; // 'All', 'Pinned', 'Favorites', 'Text', 'URLs', 'Images', 'Files', 'Colors'
  final String? selectedAppFilter;
  final Set<String> selectedIds;
  final bool isSelectionMode;
  final bool isMonitoring;
  final bool isPaused;
  final DuplicateHandlingOption duplicateHandling;
  final String? statusMessage;

  const ClipboardState({
    this.items = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.selectedAppFilter,
    this.selectedIds = const {},
    this.isSelectionMode = false,
    this.isMonitoring = true,
    this.isPaused = false,
    this.duplicateHandling = DuplicateHandlingOption.moveToTop,
    this.statusMessage,
  });

  ClipboardState copyWith({
    List<ClipboardItem>? items,
    bool? isLoading,
    String? searchQuery,
    String? selectedCategory,
    String? selectedAppFilter,
    bool clearAppFilter = false,
    Set<String>? selectedIds,
    bool? isSelectionMode,
    bool? isMonitoring,
    bool? isPaused,
    DuplicateHandlingOption? duplicateHandling,
    String? statusMessage,
    bool clearStatusMessage = false,
  }) {
    return ClipboardState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedAppFilter: clearAppFilter ? null : (selectedAppFilter ?? this.selectedAppFilter),
      selectedIds: selectedIds ?? this.selectedIds,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      isMonitoring: isMonitoring ?? this.isMonitoring,
      isPaused: isPaused ?? this.isPaused,
      duplicateHandling: duplicateHandling ?? this.duplicateHandling,
      statusMessage: clearStatusMessage ? null : (statusMessage ?? this.statusMessage),
    );
  }

  /// Returns filtered items according to query, category, and app filter
  List<ClipboardItem> get filteredItems {
    return items.where((item) {
      // 1. Search Query
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final matchContent = item.content.toLowerCase().contains(q);
        final matchTitle = item.title.toLowerCase().contains(q);
        final matchApp = item.sourceAppName.toLowerCase().contains(q);
        final matchTags = item.tags.any((t) => t.toLowerCase().contains(q));
        if (!matchContent && !matchTitle && !matchApp && !matchTags) {
          return false;
        }
      }

      // 2. Category Filter
      switch (selectedCategory) {
        case 'Pinned':
          if (!item.isPinned) return false;
          break;
        case 'Favorites':
          if (!item.isFavorite) return false;
          break;
        case 'Text':
          if (item.type != ClipboardType.text) return false;
          break;
        case 'URLs':
          if (item.type != ClipboardType.url) return false;
          break;
        case 'Images':
          if (item.type != ClipboardType.image) return false;
          break;
        case 'Files':
          if (item.type != ClipboardType.file) return false;
          break;
        case 'Colors':
          if (item.type != ClipboardType.color) return false;
          break;
        case 'All':
        default:
          break;
      }

      // 3. Source App Filter
      if (selectedAppFilter != null && selectedAppFilter!.isNotEmpty) {
        if (item.sourceAppName != selectedAppFilter) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Distinct list of applications that generated items
  List<String> get availableSourceApps {
    final apps = items.map((e) => e.sourceAppName).where((e) => e.isNotEmpty && e != 'Unknown').toSet().toList();
    apps.sort();
    return apps;
  }

  int get pinnedCount => items.where((e) => e.isPinned).length;
  int get favoritesCount => items.where((e) => e.isFavorite).length;
  int get textCount => items.where((e) => e.type == ClipboardType.text).length;
  int get urlsCount => items.where((e) => e.type == ClipboardType.url).length;
  int get imagesCount => items.where((e) => e.type == ClipboardType.image).length;
  int get filesCount => items.where((e) => e.type == ClipboardType.file).length;
}
