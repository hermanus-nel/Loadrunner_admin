import 'package:flutter/material.dart';
import '../../domain/entities/document_rejection_reason.dart';

/// Result from the document reject dialog
class DocumentRejectResult {
  final DocumentRejectionReason reason;
  final String? customReason;
  final String? adminNotes;

  const DocumentRejectResult({
    required this.reason,
    this.customReason,
    this.adminNotes,
  });
}

/// Dialog for rejecting a single document with a predefined reason
class DocumentRejectDialog extends StatefulWidget {
  final String docTypeLabel;

  const DocumentRejectDialog({
    super.key,
    required this.docTypeLabel,
  });

  /// Shows the dialog and returns the result if confirmed, null if cancelled
  static Future<DocumentRejectResult?> show({
    required BuildContext context,
    required String docTypeLabel,
  }) async {
    return showDialog<DocumentRejectResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DocumentRejectDialog(docTypeLabel: docTypeLabel),
    );
  }

  @override
  State<DocumentRejectDialog> createState() => _DocumentRejectDialogState();
}

class _DocumentRejectDialogState extends State<DocumentRejectDialog> {
  DocumentRejectionReason? _selectedReason;
  final _customReasonController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showCustomReasonField = false;

  @override
  void dispose() {
    _customReasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onReasonChanged(DocumentRejectionReason? reason) {
    setState(() {
      _selectedReason = reason;
      _showCustomReasonField = reason == DocumentRejectionReason.other;
      if (!_showCustomReasonField) {
        _customReasonController.clear();
      }
    });
  }

  void _onConfirm() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(DocumentRejectResult(
        reason: _selectedReason!,
        customReason: _selectedReason == DocumentRejectionReason.other
            ? _customReasonController.text.trim()
            : null,
        adminNotes: _notesController.text.trim().isEmpty
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
          color: colorScheme.error.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.cancel_outlined,
          size: 48,
          color: colorScheme.error,
        ),
      ),
      title: const Text(
        'Reject Document',
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

              // Reason dropdown
              Text(
                'Rejection Reason *',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<DocumentRejectionReason>(
                value: _selectedReason,
                decoration: InputDecoration(
                  hintText: 'Select a reason',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                isExpanded: true,
                items: DocumentRejectionReason.values.map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Text(
                      reason.displayText,
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: _onReasonChanged,
                validator: (value) {
                  if (value == null) {
                    return 'Please select a rejection reason';
                  }
                  return null;
                },
              ),

              // Custom reason field
              if (_showCustomReasonField) ...[
                const SizedBox(height: 16),
                Text(
                  'Specify Reason *',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _customReasonController,
                  decoration: InputDecoration(
                    hintText: 'Enter the rejection reason',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 2,
                  maxLength: 200,
                  validator: (value) {
                    if (_selectedReason == DocumentRejectionReason.other) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please specify the rejection reason';
                      }
                      if (value.trim().length < 10) {
                        return 'Reason must be at least 10 characters';
                      }
                    }
                    return null;
                  },
                ),
              ],

              // Admin notes
              const SizedBox(height: 16),
              Text(
                'Admin Notes (Optional)',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: 'Internal notes for admin reference',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 2,
                maxLength: 500,
              ),

              // Warning
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The driver will be notified that this document has been rejected with the reason provided.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
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
          icon: const Icon(Icons.cancel, size: 18),
          label: const Text('Reject'),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    );
  }
}
