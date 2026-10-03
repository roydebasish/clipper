import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class DeleteConfirmationDialog extends StatefulWidget {
  final int totalCount;
  final int pinnedCount;
  final Function({required bool exceptPinned}) onConfirm;

  const DeleteConfirmationDialog({
    super.key,
    required this.totalCount,
    required this.pinnedCount,
    required this.onConfirm,
  });

  @override
  State<DeleteConfirmationDialog> createState() => _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<DeleteConfirmationDialog> {
  bool _exceptPinned = true;

  @override
  Widget build(BuildContext context) {
    final hasPinned = widget.pinnedCount > 0;

    return AlertDialog(
      backgroundColor: AppTheme.cardBg(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.border(context)),
      ),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.macRed, size: 22),
          SizedBox(width: 8),
          Text(
            'Delete Clipboard History?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This will permanently remove ${widget.totalCount} clipboard items.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context)),
          ),
          if (hasPinned) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: () => setState(() => _exceptPinned = !_exceptPinned),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Checkbox(
                      value: _exceptPinned,
                      onChanged: (val) => setState(() => _exceptPinned = val ?? true),
                      activeColor: AppTheme.macBlue,
                    ),
                    Expanded(
                      child: Text(
                        'Keep ${widget.pinnedCount} pinned items safe',
                        style: TextStyle(fontSize: 13, color: AppTheme.textPrimary(context)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textSecondary(context),
            side: BorderSide(color: AppTheme.border(context)),
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfirm(exceptPinned: hasPinned && _exceptPinned);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.macRed,
            foregroundColor: Colors.white,
          ),
          child: Text(hasPinned && _exceptPinned ? 'Delete History (Keep Pinned)' : 'Delete All'),
        ),
      ],
    );
  }
}
