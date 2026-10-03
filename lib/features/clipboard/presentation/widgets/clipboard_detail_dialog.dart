import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/text_transformations.dart';
import '../../domain/entities/clipboard_item.dart';
import 'edit_clipboard_dialog.dart';

class ClipboardDetailDialog extends StatelessWidget {
  final ClipboardItem item;
  final VoidCallback onCopy;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;
  final Function(String newContent) onSaveEdit;
  final Function(TransformationType type) onApplyTransform;

  const ClipboardDetailDialog({
    super.key,
    required this.item,
    required this.onCopy,
    required this.onTogglePin,
    required this.onDelete,
    required this.onSaveEdit,
    required this.onApplyTransform,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final charCount = item.content.length;
    final lineCount = item.content.split('\n').length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: AppTheme.cardBg(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.border(context)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 580),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.macBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.macBlue.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      item.type.label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.macBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (item.sourceAppName.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.sidebarBg(context),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.border(context)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.apps, size: 12, color: AppTheme.textSecondary(context)),
                          const SizedBox(width: 4),
                          Text(
                            item.sourceAppName,
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, size: 16, color: AppTheme.textSecondary(context)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Metadata grid
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.sidebarBg(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border(context)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetaItem(context, 'Created', dateFormat.format(item.createdAt)),
                    _buildMetaItem(context, 'Last Copied', dateFormat.format(item.lastCopiedAt)),
                    _buildMetaItem(context, 'Copy Count', '${item.copyCount}x'),
                    _buildMetaItem(
                      context,
                      'Size',
                      item.type == ClipboardType.image
                          ? item.title
                          : '$charCount chars / $lineCount lines',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Content Body
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.bg(context) : const Color(0xFFFAFAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  child: _buildContentBody(context),
                ),
              ),
              const SizedBox(height: 16),

              // Actions footer
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: Icon(
                      item.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 14,
                      color: item.isPinned ? AppTheme.macAmber : AppTheme.textSecondary(context),
                    ),
                    label: Text(item.isPinned ? 'Unpin' : 'Pin'),
                    onPressed: () {
                      onTogglePin();
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary(context),
                      side: BorderSide(color: AppTheme.border(context)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (item.type != ClipboardType.image) ...[
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      label: const Text('Edit'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        showDialog(
                          context: context,
                          builder: (_) => EditClipboardDialog(item: item, onSave: onSaveEdit),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary(context),
                        side: BorderSide(color: AppTheme.border(context)),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Transform Popup Menu
                    PopupMenuButton<TransformationType>(
                      tooltip: 'Text Transformations',
                      color: AppTheme.cardBg(context),
                      onSelected: (type) {
                        onApplyTransform(type);
                        Navigator.of(context).pop();
                      },
                      itemBuilder: (ctx) => TransformationType.values.map((t) {
                        return PopupMenuItem<TransformationType>(
                          value: t,
                          child: Text(
                            t.title,
                            style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context)),
                          ),
                        );
                      }).toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.border(context)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_fix_high, size: 14, color: AppTheme.macPurple),
                            const SizedBox(width: 6),
                            Text(
                              'Transform',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context)),
                            ),
                            Icon(Icons.arrow_drop_down, size: 14, color: AppTheme.textSecondary(context)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 14, color: AppTheme.macRed),
                    label: const Text('Delete', style: TextStyle(color: AppTheme.macRed)),
                    onPressed: () {
                      onDelete();
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.copy, size: 14),
                    label: Text(item.type == ClipboardType.image ? 'Copy Image' : 'Copy to Clipboard'),
                    onPressed: () {
                      onCopy();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.macBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildContentBody(BuildContext context) {
    if (_isImageItem(item)) {
      Widget? img;
      if (item.filePath != null && item.filePath!.isNotEmpty && File(item.filePath!).existsSync()) {
        img = Image.file(
          File(item.filePath!),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image_outlined, size: 36, color: Colors.grey),
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
          img = Image.memory(
            bytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.broken_image_outlined, size: 36, color: Colors.grey),
            ),
          );
        } catch (_) {}
      }
      return Center(
        child: SingleChildScrollView(
          child: img ?? const Text('Image data unavailable'),
        ),
      );
    }

    return SingleChildScrollView(
      child: SelectableText(
        item.content,
        style: TextStyle(
          fontSize: 13,
          fontFamily: 'SF Mono, Menlo, monospace',
          height: 1.5,
          color: AppTheme.textPrimary(context),
        ),
      ),
    );
  }

  Widget _buildMetaItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 10, color: AppTheme.textMuted(context), fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context)),
        ),
      ],
    );
  }
}
