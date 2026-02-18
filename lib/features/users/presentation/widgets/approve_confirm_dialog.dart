// lib/features/users/presentation/widgets/approve_confirm_dialog.dart
import 'package:flutter/material.dart';

/// Simple confirmation dialog for approving a driver
class ApproveConfirmDialog extends StatelessWidget {
  final String driverName;
  final VoidCallback onConfirm;

  const ApproveConfirmDialog({
    super.key,
    required this.driverName,
    required this.onConfirm,
  });

  /// Shows the dialog and returns true if confirmed, false if cancelled
  static Future<bool> show({
    required BuildContext context,
    required String driverName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ApproveConfirmDialog(
        driverName: driverName,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle_outline,
          size: 48,
          color: Colors.green,
        ),
      ),
      title: const Text(
        'Approve Driver',
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Are you sure you want to approve',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            driverName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The driver will be notified and can start accepting jobs immediately.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
        ),
        FilledButton.icon(
          onPressed: onConfirm,
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Approve'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    );
  }
}
