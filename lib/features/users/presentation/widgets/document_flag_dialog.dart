import 'package:flutter/material.dart';

/// Result from the document flag dialog
class DocumentFlagResult {
  final String reason;
  final String? notes;

  const DocumentFlagResult({
    required this.reason,
    this.notes,
  });
}

/// Dialog for flagging a document as suspicious / fraudulent.
/// Sends a neutral re-upload notification to the driver (no fraud mention).
class DocumentFlagDialog extends StatefulWidget {
  final String docTypeLabel;

  const DocumentFlagDialog({
    super.key,
    required this.docTypeLabel,
  });

  /// Shows the dialog and returns the result if confirmed, null if cancelled
  static Future<DocumentFlagResult?> show({
    required BuildContext context,
    required String docTypeLabel,
  }) async {
    return showDialog<DocumentFlagResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DocumentFlagDialog(docTypeLabel: docTypeLabel),
    );
  }

  @override
  State<DocumentFlagDialog> createState() => _DocumentFlagDialogState();
}

class _DocumentFlagDialogState extends State<DocumentFlagDialog> {
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(DocumentFlagResult(
        reason: _reasonController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ));
    }
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
          color: Colors.amber.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.flag_outlined,
          size: 48,
          color: Colors.amber,
        ),
      ),
      title: const Text(
        'Flag Document',
        textAlign: TextAlign.center,
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  widget.docTypeLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Warning banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The driver will receive a neutral re-upload notification. '
                        'No mention of flagging or fraud will be communicated to the driver.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.amber[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Flag reason
              Text(
                'Flag Reason *',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  hintText: 'Describe why this document is being flagged',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
                maxLength: 500,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a flag reason';
                  }
                  if (value.trim().length < 10) {
                    return 'Reason must be at least 10 characters';
                  }
                  return null;
                },
              ),

              // Admin notes
              const SizedBox(height: 16),
              Text(
                'Internal Notes (Optional)',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: 'Additional notes for admin reference',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 2,
                maxLength: 500,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: _onConfirm,
          icon: const Icon(Icons.flag, size: 18),
          label: const Text('Flag'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black87,
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    );
  }
}
