import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/text_transformations.dart';
import '../../domain/entities/clipboard_item.dart';
import 'clipboard_detail_dialog.dart';
import 'edit_clipboard_dialog.dart';

class ClipboardItemTile extends StatefulWidget {
  final ClipboardItem item;
  final int? index;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onSelect;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;
  final VoidCallback onToggleFavorite;
  final VoidCallback onMoveToTop;
  final VoidCallback onMoveToBottom;
  final Function(String newContent) onSaveEdit;
  final Function(TransformationType type) onApplyTransform;

  const ClipboardItemTile({
    super.key,
    required this.item,
    this.index,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onSelect,
    required this.onCopy,
    required this.onDelete,
    required this.onTogglePin,
    required this.onToggleFavorite,
    required this.onMoveToTop,
    required this.onMoveToBottom,
    required this.onSaveEdit,
    required this.onApplyTransform,
  });

  @override
  State<ClipboardItemTile> createState() => _ClipboardItemTileState();
}

class _ClipboardItemTileState extends State<ClipboardItemTile> {
  bool _isHovered = false;
  bool _justCopied = false;

  void _triggerCopy() {
    widget.onCopy();
    setState(() => _justCopied = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _justCopied = false);
    });
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return DateFormat('h:mm a').format(dt);
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  IconData _getTypeIcon(ClipboardType type) {
    switch (type) {
      case ClipboardType.url:
        return Icons.link;
      case ClipboardType.image:
        return Icons.image_outlined;
      case ClipboardType.file:
        return Icons.insert_drive_file_outlined;
      case ClipboardType.color:
        return Icons.palette_outlined;
      case ClipboardType.richText:
        return Icons.format_paint_outlined;
      case ClipboardType.text:
      default:
        return Icons.short_text_rounded;
    }
  }

  IconData _getAppIcon(String appName) {
    final lower = appName.toLowerCase();
    if (lower.contains('terminal') || lower.contains('iterm')) return Icons.terminal;
    if (lower.contains('chrome') || lower.contains('brave') || lower.contains('safari') || lower.contains('edge') || lower.contains('firefox')) {
      return Icons.public;
    }
    if (lower.contains('code') || lower.contains('studio') || lower.contains('xcode') || lower.contains('intellij')) {
      return Icons.code;
    }
    if (lower.contains('notes')) return Icons.note_outlined;
    if (lower.contains('slack') || lower.contains('discord') || lower.contains('telegram')) return Icons.chat_bubble_outline;
    if (lower.contains('finder')) return Icons.folder_open;
    return Icons.apps;
  }

  bool _isImageItem(ClipboardItem item) {
    if (item.type == ClipboardType.image) return true;
    if (item.filePath != null && item.filePath!.isNotEmpty) {
      final ext = item.filePath!.toLowerCase();
      if (ext.endsWith('.png') ||
          ext.endsWith('.jpg') ||
          ext.endsWith('.jpeg') ||
          ext.endsWith('.gif') ||
          ext.endsWith('.webp') ||
          ext.endsWith('.bmp') ||
          ext.endsWith('.tiff') ||
          ext.endsWith('.heic')) {
        return true;
      }
    }
    return false;
  }

  Widget _buildImagePreview(BuildContext context, ClipboardItem item) {
    Widget? imageWidget;

    if (item.filePath != null && item.filePath!.isNotEmpty && File(item.filePath!).existsSync()) {
      imageWidget = Image.file(
        File(item.filePath!),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image_outlined, size: 28, color: Colors.grey),
        ),
      );
    } else if (item.content.isNotEmpty) {
      String base64Data = item.content;
      if (base64Data.startsWith('data:image/')) {
        final commaIdx = base64Data.indexOf(',');
        if (commaIdx != -1) {
          base64Data = base64Data.substring(commaIdx + 1);
        }
      }
      try {
        final bytes = base64Decode(base64Data.trim());
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image_outlined, size: 28, color: Colors.grey),
          ),
        );
      } catch (_) {}
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(maxHeight: 180, minHeight: 90),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191B20) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border(context), width: 0.9),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageWidget != null
          ? Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: imageWidget,
                  ),
                ),
                Positioned(
                  bottom: 6,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.title,
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.image_outlined, size: 24, color: AppTheme.macBlue),
                  const SizedBox(width: 8),
                  Text(item.title, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context))),
                ],
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? AppTheme.cardSelected(context)
              : (_isHovered ? AppTheme.cardHover(context) : AppTheme.cardBg(context)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.isSelected
                ? AppTheme.macBlue
                : (item.isPinned
                    ? AppTheme.macAmber.withValues(alpha: 0.6)
                    : (_isHovered
                        ? (isDark ? const Color(0xFF434855) : const Color(0xFFC7CBD5))
                        : AppTheme.border(context))),
            width: widget.isSelected ? 1.5 : (item.isPinned ? 1.2 : 0.9),
          ),
          boxShadow: [
            if (_isHovered && !isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            if (widget.isSelectionMode) {
              widget.onSelect();
            } else {
              _triggerCopy();
            }
          },
          onDoubleTap: () => _openDetailDialog(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Meta row: Drag Handle / Checkbox / Type / Source / Pin / Time
                Row(
                  children: [
                    // Drag Handle
                    if (widget.index != null)
                      ReorderableDragStartListener(
                        index: widget.index!,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {}, // Prevent card's InkWell from opening detail dialog
                          child: MouseRegion(
                            cursor: SystemMouseCursors.grab,
                            child: Tooltip(
                              message: 'Drag to reorder',
                              waitDuration: const Duration(milliseconds: 250),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: _isHovered ? AppTheme.sidebarBg(context) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                  border: _isHovered ? Border.all(color: AppTheme.border(context), width: 0.8) : null,
                                ),
                                child: Icon(
                                  Icons.drag_indicator_rounded,
                                  size: 15,
                                  color: _isHovered ? AppTheme.textPrimary(context) : AppTheme.textMuted(context).withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    if (widget.isSelectionMode)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: Checkbox(
                            value: widget.isSelected,
                            onChanged: (_) => widget.onSelect(),
                            activeColor: AppTheme.macBlue,
                            side: BorderSide(color: AppTheme.textMuted(context)),
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.macBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(_getTypeIcon(item.type), size: 12, color: AppTheme.macBlue),
                          const SizedBox(width: 4),
                          Text(
                            item.type.label,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.macBlue),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (item.sourceAppName.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.sidebarBg(context),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.border(context), width: 0.8),
                        ),
                        child: Row(
                          children: [
                            Icon(_getAppIcon(item.sourceAppName), size: 11, color: AppTheme.textSecondary(context)),
                            const SizedBox(width: 4),
                            Text(
                              item.sourceAppName,
                              style: TextStyle(fontSize: 10, color: AppTheme.textSecondary(context)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (item.copyCount > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.macPurple.withValues(alpha: isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${item.copyCount}x',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.macPurple),
                        ),
                      ),
                    const Spacer(),
                    if (item.isPinned)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.push_pin, size: 12, color: AppTheme.macAmber),
                      ),
                    if (item.isFavorite)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.star, size: 12, color: AppTheme.macAmber),
                      ),
                    Text(
                      _formatTimestamp(item.lastCopiedAt),
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 7),

                // Content Preview (Text vs Image)
                if (item.type == ClipboardType.image || _isImageItem(item))
                  _buildImagePreview(context, item)
                else
                  Text(
                    item.preview.replaceAll('\n', ' '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: item.type == ClipboardType.text ? 'SF Mono, Menlo, monospace' : null,
                      color: AppTheme.textPrimary(context),
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 8),

                // Action Bar: Copy, Pin, Move, More, Delete
                Row(
                  children: [
                    // Copy Action
                    _buildActionButton(
                      context: context,
                      icon: _justCopied ? Icons.check : Icons.copy,
                      label: _justCopied ? 'Copied!' : 'Copy',
                      color: _justCopied ? AppTheme.macGreen : AppTheme.macBlue,
                      onTap: _triggerCopy,
                    ),
                    const SizedBox(width: 6),

                    // Pin Action
                    _buildActionButton(
                      context: context,
                      icon: item.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      label: item.isPinned ? 'Pinned' : 'Pin',
                      color: item.isPinned ? AppTheme.macAmber : AppTheme.textSecondary(context),
                      onTap: widget.onTogglePin,
                    ),
                    const SizedBox(width: 6),

                    // Move Menu
                    PopupMenuButton<String>(
                      tooltip: 'Reorder Item',
                      color: AppTheme.cardBg(context),
                      onSelected: (val) {
                        if (val == 'top') widget.onMoveToTop();
                        if (val == 'bottom') widget.onMoveToBottom();
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'top',
                          child: Row(
                            children: [
                              Icon(Icons.vertical_align_top, size: 14, color: AppTheme.textSecondary(context)),
                              const SizedBox(width: 8),
                              Text('Move to Top', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context))),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'bottom',
                          child: Row(
                            children: [
                              Icon(Icons.vertical_align_bottom, size: 14, color: AppTheme.textSecondary(context)),
                              const SizedBox(width: 8),
                              Text('Move to Bottom', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context))),
                            ],
                          ),
                        ),
                      ],
                      child: _buildActionButton(
                        context: context,
                        icon: Icons.swap_vert,
                        label: 'Move',
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // More Menu (Transform, Edit, Favorite)
                    PopupMenuButton<String>(
                      tooltip: 'More Actions',
                      color: AppTheme.cardBg(context),
                      onSelected: (val) {
                        if (val == 'edit') {
                          showDialog(
                            context: context,
                            builder: (_) => EditClipboardDialog(item: item, onSave: widget.onSaveEdit),
                          );
                        } else if (val == 'favorite') {
                          widget.onToggleFavorite();
                        } else if (val == 'details') {
                          _openDetailDialog(context);
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'favorite',
                          child: Row(
                            children: [
                              Icon(item.isFavorite ? Icons.star : Icons.star_border, size: 14, color: AppTheme.macAmber),
                              const SizedBox(width: 8),
                              Text(item.isFavorite ? 'Remove Favorite' : 'Add to Favorites',
                                  style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context))),
                            ],
                          ),
                        ),
                        if (item.type != ClipboardType.image)
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 14, color: AppTheme.textSecondary(context)),
                                const SizedBox(width: 8),
                                Text('Edit Content', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context))),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'details',
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 14, color: AppTheme.textSecondary(context)),
                              const SizedBox(width: 8),
                              Text('View Full Details', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context))),
                            ],
                          ),
                        ),
                      ],
                      child: _buildActionButton(
                        context: context,
                        icon: Icons.more_horiz,
                        label: 'More',
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                    const Spacer(),

                    // Individual Delete Action
                    _buildActionButton(
                      context: context,
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      color: AppTheme.macRed,
                      onTap: widget.onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: isDark ? 0.25 : 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: color),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ClipboardDetailDialog(
        item: widget.item,
        onCopy: _triggerCopy,
        onTogglePin: widget.onTogglePin,
        onDelete: widget.onDelete,
        onSaveEdit: widget.onSaveEdit,
        onApplyTransform: widget.onApplyTransform,
      ),
    );
  }
}
