import 'package:flutter/material.dart';
import '../../domain/entities/document_reupload_reason.dart';

/// Result from the document reupload dialog
class DocumentReuploadResult {
  final DocumentReuploadReason reason;
  final String? customReason;
  final String? adminNotes;

  const DocumentReuploadResult({
    required this.reason,
    this.customReason,
    this.adminNotes,
  });
}

/// Dialog for requesting a document re-upload with a predefined reason
class DocumentReuploadDialog extends StatefulWidget {
  final String docTypeLabel;

  const DocumentReuploadDialog({
    super.key,
    required this.docTypeLabel,
  });

  /// Shows the dialog and returns the result if confirmed, null if cancelled
  static Future<DocumentReuploadResult?> show({
    required BuildContext context,
    required String docTypeLabel,
  }) async {
    return showDialog<DocumentReuploadResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DocumentReuploadDialog(docTypeLabel: docTypeLabel),
    );
  }

  @override
  State<DocumentReuploadDialog> createState() =>
      _DocumentReuploadDialogState();
}

class _DocumentReuploadDialogState extends State<DocumentReuploadDialog> {
  DocumentReuploadReason? _selectedReason;
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

  void _onReasonChanged(DocumentReuploadReason? reason) {
    setState(() {
      _selectedReason = reason;
      _showCustomReasonField = reason == DocumentReuploadReason.other;
      if (!_showCustomReasonField) {
        _customReasonController.clear();
      }
    });
  }

  void _onConfirm() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(DocumentReuploadResult(
        reason: _selectedReason!,
        customReason: _selectedReason == DocumentReuploadReason.other
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
          color: Colors.orange.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.upload_file_outlined,
          size: 48,
          color: Colors.orange,
        ),
      ),
      title: const Text(
        'Request Re-upload',
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
                'Re-upload Reason *',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<DocumentReuploadReason>(
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
                items: DocumentReuploadReason.values.map((reason) {
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
                    return 'Please select a reason';
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
                    hintText: 'Enter the re-upload reason',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 2,
                  maxLength: 200,
                  validator: (value) {
                    if (_selectedReason == DocumentReuploadReason.other) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please specify the reason';
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

              // Info banner
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The driver will be notified to re-upload this document.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange[800],
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
          icon: const Icon(Icons.upload_file, size: 18),
          label: const Text('Request Re-upload'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    );
  }
}
