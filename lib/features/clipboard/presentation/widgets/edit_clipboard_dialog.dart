import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/clipboard_item.dart';

class EditClipboardDialog extends StatefulWidget {
  final ClipboardItem item;
  final Function(String newContent) onSave;

  const EditClipboardDialog({
    super.key,
    required this.item,
    required this.onSave,
  });

  @override
  State<EditClipboardDialog> createState() => _EditClipboardDialogState();
}

class _EditClipboardDialogState extends State<EditClipboardDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.content);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardBg(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.border(context)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Clipboard Content',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 16, color: AppTheme.textSecondary(context)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.sidebarBg(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'SF Mono, Menlo, monospace',
                      color: AppTheme.textPrimary(context),
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter clipboard text...',
                      hintStyle: TextStyle(color: AppTheme.textMuted(context)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary(context),
                      side: BorderSide(color: AppTheme.border(context)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      widget.onSave(_controller.text);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.macBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
