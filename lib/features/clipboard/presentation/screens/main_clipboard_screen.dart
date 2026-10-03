import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../settings/presentation/screens/settings_dialog.dart';
import '../../../settings/presentation/settings_provider.dart';
import '../providers/clipboard_provider.dart';
import '../providers/clipboard_state.dart';
import '../widgets/clipboard_item_tile.dart';
import '../widgets/delete_confirmation_dialog.dart';

class MainClipboardScreen extends ConsumerStatefulWidget {
  const MainClipboardScreen({super.key});

  @override
  ConsumerState<MainClipboardScreen> createState() => _MainClipboardScreenState();
}

class _MainClipboardScreenState extends ConsumerState<MainClipboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onFocusChange);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const SettingsDialog(),
    );
  }

  void _handleGlobalKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCmd = HardwareKeyboard.instance.isMetaPressed;
      // ⌘K for search
      if (isCmd && event.logicalKey == LogicalKeyboardKey.keyK) {
        _searchFocusNode.requestFocus();
      }
      // ⌘, for settings
      if (isCmd && event.logicalKey == LogicalKeyboardKey.comma) {
        _openSettings(context);
      }
      // Esc to clear search
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (_searchFocusNode.hasFocus) {
          _searchController.clear();
          ref.read(clipboardProvider.notifier).setSearchQuery('');
          _searchFocusNode.unfocus();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clipboardProvider);
    final notifier = ref.read(clipboardProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen for status messages (e.g. "Copied to clipboard!")
    ref.listen<String?>(clipboardProvider.select((s) => s.statusMessage), (_, msg) {
      if (msg != null && msg.isNotEmpty) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              msg,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF1D2129),
              ),
            ),
            backgroundColor: isDark ? const Color(0xFF2C3038) : Colors.white,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            width: 260,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: AppTheme.border(context)),
            ),
          ),
        );
      }
    });

    final filteredItems = state.filteredItems;

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleGlobalKey,
      child: Scaffold(
        backgroundColor: AppTheme.bg(context),
        body: Column(
          children: [
            // Top Navigation / macOS Toolbar
            _buildTopBar(context, state, notifier, settings),
            Divider(height: 1, color: AppTheme.border(context)),

            // Content Area: Sidebar + Items List
            Expanded(
              child: Row(
                children: [
                  // Left Sidebar
                  _buildSidebar(context, state, notifier),
                  VerticalDivider(width: 1, color: AppTheme.border(context)),

                  // Main List View
                  Expanded(
                    child: Column(
                      children: [
                        // Multi-select banner
                        if (state.isSelectionMode)
                          _buildSelectionBanner(context, state, notifier),

                        // List of items
                        Expanded(
                          child: state.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : filteredItems.isEmpty
                                  ? _buildEmptyState(context, state)
                                  : ReorderableListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                      itemCount: filteredItems.length,
                                      buildDefaultDragHandles: false,
                                      onReorder: (oldIndex, newIndex) => notifier.reorderItem(oldIndex, newIndex),
                                      proxyDecorator: (child, index, animation) {
                                        return Material(
                                          color: Colors.transparent,
                                          elevation: 8,
                                          shadowColor: Colors.black.withValues(alpha: 0.2),
                                          child: child,
                                        );
                                      },
                                      itemBuilder: (context, index) {
                                        final item = filteredItems[index];
                                        return ClipboardItemTile(
                                          key: ValueKey(item.id),
                                          item: item,
                                          index: index,
                                          isSelected: state.selectedIds.contains(item.id),
                                          isSelectionMode: state.isSelectionMode,
                                          onSelect: () => notifier.toggleSelect(item.id),
                                          onCopy: () => notifier.copyItem(item),
                                          onDelete: () => notifier.deleteItem(item.id),
                                          onTogglePin: () => notifier.togglePin(item.id),
                                          onToggleFavorite: () => notifier.toggleFavorite(item.id),
                                          onMoveToTop: () => notifier.moveToTop(item.id),
                                          onMoveToBottom: () => notifier.moveToBottom(item.id),
                                          onSaveEdit: (newContent) => notifier.updateContent(item.id, newContent),
                                          onApplyTransform: (t) => notifier.applyTransformation(item.id, t),
                                        );
                                      },
                                    ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, ClipboardState state, ClipboardNotifier notifier, settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.sidebarBg(context),
      ),
      child: Row(
        children: [
          // App Logo / Title
          Tooltip(
            message: 'Show All History (Clipper)',
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                notifier.setCategory('all');
                _searchController.clear();
                notifier.setSearchQuery('');
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppTheme.macBlue.withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.content_paste_rounded, color: AppTheme.macBlue, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Clipper',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Monitoring State Pill
          _buildMonitoringPill(context, state, notifier),
          const SizedBox(width: 16),

          // Search Field
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.text,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _searchFocusNode.requestFocus(),
                child: Container(
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2127) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _searchFocusNode.hasFocus
                          ? AppTheme.macBlue
                          : AppTheme.border(context),
                      width: _searchFocusNode.hasFocus ? 1.4 : 1.0,
                    ),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: _searchFocusNode.hasFocus
                              ? AppTheme.macBlue.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    mouseCursor: SystemMouseCursors.text,
                    cursorColor: AppTheme.macBlue,
                    cursorWidth: 2.0,
                    cursorHeight: 16.0,
                    cursorRadius: const Radius.circular(1),
                    showCursor: true,
                    textAlignVertical: TextAlignVertical.center,
                    onChanged: (val) => notifier.setSearchQuery(val),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textPrimary(context),
                      decoration: TextDecoration.none,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      prefixIconConstraints: const BoxConstraints(minWidth: 32, maxWidth: 36, minHeight: 34, maxHeight: 34),
                      suffixIconConstraints: const BoxConstraints(minWidth: 32, maxWidth: 44, minHeight: 34, maxHeight: 34),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 8, right: 6),
                        child: Icon(Icons.search_rounded, size: 16, color: AppTheme.textSecondary(context)),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              icon: Icon(Icons.cancel, size: 14, color: AppTheme.textMuted(context)),
                              onPressed: () {
                                _searchController.clear();
                                notifier.setSearchQuery('');
                              },
                            )
                          : Container(
                              padding: const EdgeInsets.only(right: 8),
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppTheme.sidebarBg(context),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppTheme.border(context)),
                                ),
                                child: Text(
                                  '⌘K',
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.textMuted(context)),
                                ),
                              ),
                            ),
                      hintText: 'Search clipboard history, source apps, tags...',
                      hintStyle: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Quick Theme Toggle Button (Light / Dark)
          IconButton(
            tooltip: isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 17,
              color: AppTheme.textSecondary(context),
            ),
            onPressed: () {
              final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
              ref.read(settingsProvider.notifier).setThemeMode(newMode);
            },
          ),

          // Multi-Select Toggle
          IconButton(
            tooltip: state.isSelectionMode ? 'Exit Selection Mode' : 'Multi-Select Items',
            icon: Icon(
              state.isSelectionMode ? Icons.checklist_rtl : Icons.checklist,
              size: 17,
              color: state.isSelectionMode ? AppTheme.macBlue : AppTheme.textSecondary(context),
            ),
            onPressed: () => notifier.toggleSelectionMode(),
          ),

          // Settings Button (⌘,)
          IconButton(
            tooltip: 'Settings (⌘,)',
            icon: Icon(Icons.settings_outlined, size: 17, color: AppTheme.textSecondary(context)),
            onPressed: () => _openSettings(context),
          ),

          // Delete All History Action
          IconButton(
            tooltip: 'Clear History',
            icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: AppTheme.macRed),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => DeleteConfirmationDialog(
                  totalCount: state.items.length,
                  pinnedCount: state.pinnedCount,
                  onConfirm: ({required bool exceptPinned}) {
                    notifier.deleteAll(exceptPinned: exceptPinned);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringPill(BuildContext context, ClipboardState state, ClipboardNotifier notifier) {
    final isPaused = state.isPaused;
    return PopupMenuButton<String>(
      tooltip: isPaused ? 'Clipboard Paused (Click to Resume)' : 'Monitoring Active (Click to Pause)',
      color: AppTheme.cardBg(context),
      onSelected: (val) {
        if (val == 'resume') {
          notifier.resumeMonitoring();
        } else if (val == '5m') {
          notifier.pauseMonitoring(duration: const Duration(minutes: 5));
        } else if (val == '30m') {
          notifier.pauseMonitoring(duration: const Duration(minutes: 30));
        } else if (val == '1h') {
          notifier.pauseMonitoring(duration: const Duration(hours: 1));
        } else if (val == 'indefinite') {
          notifier.pauseMonitoring();
        }
      },
      itemBuilder: (ctx) => [
        if (isPaused)
          const PopupMenuItem(
            value: 'resume',
            child: Row(
              children: [
                Icon(Icons.play_arrow, size: 14, color: AppTheme.macGreen),
                SizedBox(width: 8),
                Text('Resume Monitoring', style: TextStyle(fontSize: 12)),
              ],
            ),
          )
        else ...[
          const PopupMenuItem(
            value: '5m',
            child: Text('Pause for 5 Minutes', style: TextStyle(fontSize: 12)),
          ),
          const PopupMenuItem(
            value: '30m',
            child: Text('Pause for 30 Minutes', style: TextStyle(fontSize: 12)),
          ),
          const PopupMenuItem(
            value: '1h',
            child: Text('Pause for 1 Hour', style: TextStyle(fontSize: 12)),
          ),
          const PopupMenuItem(
            value: 'indefinite',
            child: Text('Pause Until Resumed', style: TextStyle(fontSize: 12)),
          ),
        ],
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (isPaused ? AppTheme.macAmber : AppTheme.macGreen).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isPaused ? AppTheme.macAmber : AppTheme.macGreen).withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPaused ? AppTheme.macAmber : AppTheme.macGreen,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isPaused ? 'Paused' : 'Monitoring',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isPaused ? AppTheme.macAmber : AppTheme.macGreen,
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 13, color: AppTheme.textSecondary(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, ClipboardState state, ClipboardNotifier notifier) {
    return Container(
      width: 200,
      color: AppTheme.sidebarBg(context),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              children: [
                _buildSidebarItem(
                  context: context,
                  icon: Icons.all_inbox_rounded,
                  label: 'All History',
                  count: state.items.length,
                  isSelected: state.selectedCategory == 'All' && state.selectedAppFilter == null,
                  onTap: () {
                    notifier.setCategory('All');
                    notifier.setAppFilter(null);
                  },
                ),
                _buildSidebarItem(
                  context: context,
                  icon: Icons.push_pin_rounded,
                  label: 'Pinned',
                  count: state.pinnedCount,
                  accentColor: AppTheme.macAmber,
                  isSelected: state.selectedCategory == 'Pinned',
                  onTap: () {
                    notifier.setCategory('Pinned');
                    notifier.setAppFilter(null);
                  },
                ),
                _buildSidebarItem(
                  context: context,
                  icon: Icons.star_rounded,
                  label: 'Favorites',
                  count: state.favoritesCount,
                  accentColor: AppTheme.macAmber,
                  isSelected: state.selectedCategory == 'Favorites',
                  onTap: () {
                    notifier.setCategory('Favorites');
                    notifier.setAppFilter(null);
                  },
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    'TYPES',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.6, color: AppTheme.textMuted(context)),
                  ),
                ),
                _buildSidebarItem(
                  context: context,
                  icon: Icons.short_text_rounded,
                  label: 'Text',
                  count: state.textCount,
                  isSelected: state.selectedCategory == 'Text',
                  onTap: () {
                    notifier.setCategory('Text');
                    notifier.setAppFilter(null);
                  },
                ),
                _buildSidebarItem(
                  context: context,
                  icon: Icons.link_rounded,
                  label: 'Links / URLs',
                  count: state.urlsCount,
                  isSelected: state.selectedCategory == 'URLs',
                  onTap: () {
                    notifier.setCategory('URLs');
                    notifier.setAppFilter(null);
                  },
                ),
                _buildSidebarItem(
                  context: context,
                  icon: Icons.image_outlined,
                  label: 'Images',
                  count: state.imagesCount,
                  isSelected: state.selectedCategory == 'Images',
                  onTap: () {
                    notifier.setCategory('Images');
                    notifier.setAppFilter(null);
                  },
                ),
                _buildSidebarItem(
                  context: context,
                  icon: Icons.insert_drive_file_outlined,
                  label: 'Files',
                  count: state.filesCount,
                  isSelected: state.selectedCategory == 'Files',
                  onTap: () {
                    notifier.setCategory('Files');
                    notifier.setAppFilter(null);
                  },
                ),

                // Source Applications section
                if (state.availableSourceApps.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text(
                      'APPLICATIONS',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.6, color: AppTheme.textMuted(context)),
                    ),
                  ),
                  ...state.availableSourceApps.map<Widget>((app) {
                    final isAppSelected = state.selectedAppFilter == app;
                    final count = state.items.where((e) => e.sourceAppName == app).length;
                    return _buildSidebarItem(
                      context: context,
                      icon: Icons.apps_rounded,
                      label: app,
                      count: count,
                      isSelected: isAppSelected,
                      onTap: () {
                        if (isAppSelected) {
                          notifier.setAppFilter(null);
                        } else {
                          notifier.setAppFilter(app);
                        }
                      },
                    );
                  }),
                ],
              ],
            ),
          ),

          // Bottom Settings Button in Sidebar
          Divider(height: 1, color: AppTheme.border(context)),
          Padding(
            padding: const EdgeInsets.all(8),
            child: InkWell(
              onTap: () => _openSettings(context),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 15, color: AppTheme.textSecondary(context)),
                    const SizedBox(width: 8),
                    Text(
                      'Settings',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary(context)),
                    ),
                    const Spacer(),
                    Text(
                      '⌘,',
                      style: TextStyle(fontSize: 10, color: AppTheme.textMuted(context)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    Color? accentColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.macBlue.withValues(alpha: isDark ? 0.18 : 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
        leading: Icon(
          icon,
          size: 15,
          color: isSelected ? AppTheme.macBlue : (accentColor ?? AppTheme.textSecondary(context)),
        ),
        title: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppTheme.macBlue : AppTheme.textPrimary(context),
          ),
        ),
        trailing: count > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.macBlue.withValues(alpha: isDark ? 0.25 : 0.15)
                      : AppTheme.border(context).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppTheme.macBlue : AppTheme.textSecondary(context),
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildSelectionBanner(BuildContext context, ClipboardState state, ClipboardNotifier notifier) {
    final count = state.selectedIds.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardSelected(context),
        border: Border(bottom: BorderSide(color: AppTheme.macBlue.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          Text(
            '$count items selected',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.macBlue),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => notifier.selectAll(),
            child: const Text('Select All', style: TextStyle(fontSize: 12, color: AppTheme.macBlue)),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => notifier.clearSelection(),
            child: Text('Deselect', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context))),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete, size: 14),
            label: const Text('Delete Selected'),
            onPressed: count > 0 ? () => notifier.deleteSelected() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.macRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ClipboardState state) {
    final isSearching = state.searchQuery.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.sidebarBg(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching ? Icons.search_off_rounded : Icons.content_paste_search_rounded,
                size: 42,
                color: AppTheme.textMuted(context),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isSearching ? 'No matching clipboard items' : 'Clipboard history is empty',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'Try searching with different keywords or clear the search filter.'
                  : 'Copy text in Google Chrome, VS Code, or Terminal.\nSwift will automatically detect changes and record them here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
