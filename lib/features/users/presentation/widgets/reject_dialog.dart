// lib/features/users/presentation/widgets/reject_dialog.dart
import 'package:flutter/material.dart';

/// Result from the reject dialog containing the reason
class RejectDialogResult {
  final String reason;
  final String? notes;

  const RejectDialogResult({
    required this.reason,
    this.notes,
  });
}

/// Predefined rejection reasons
enum RejectionReason {
  invalidDocuments('Invalid or expired documents'),
  poorDocumentQuality('Poor document quality (blurry, unreadable)'),
  vehicleRequirements('Vehicle does not meet requirements'),
  incompleteDocuments('Incomplete documentation'),
  informationMismatch('Information mismatch between documents'),
  suspiciousActivity('Suspicious activity detected'),
  failedVerification('Failed background verification'),
  other('Other (specify below)');

  final String displayName;
  const RejectionReason(this.displayName);
}

/// Dialog for rejecting a driver with required reason
class RejectDialog extends StatefulWidget {
  final String driverName;

  const RejectDialog({
    super.key,
    required this.driverName,
  });

  /// Shows the dialog and returns the result if confirmed, null if cancelled
  static Future<RejectDialogResult?> show({
    required BuildContext context,
    required String driverName,
  }) async {
    return showDialog<RejectDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RejectDialog(driverName: driverName),
    );
  }

  @override
  State<RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<RejectDialog> {
  RejectionReason? _selectedReason;
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

  void _onReasonChanged(RejectionReason? reason) {
    setState(() {
      _selectedReason = reason;
      _showCustomReasonField = reason == RejectionReason.other;
      if (!_showCustomReasonField) {
        _customReasonController.clear();
      }
    });
  }

  void _onConfirm() {
    if (_formKey.currentState?.validate() ?? false) {
      String finalReason;
      if (_selectedReason == RejectionReason.other) {
        finalReason = _customReasonController.text.trim();
      } else {
        finalReason = _selectedReason!.displayName;
      }

      Navigator.of(context).pop(RejectDialogResult(
        reason: finalReason,
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
        'Reject Driver',
        textAlign: TextAlign.center,
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rejecting application for',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  widget.driverName,
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
              DropdownButtonFormField<RejectionReason>(
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
                items: RejectionReason.values.map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Text(
                      reason.displayName,
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
              
              // Custom reason field (shown when "Other" is selected)
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
                    if (_selectedReason == RejectionReason.other) {
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
              
              // Additional notes (optional)
              const SizedBox(height: 16),
              Text(
                'Additional Notes (Optional)',
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
              
              // Warning notice
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
                        'The driver will be notified of the rejection with the reason provided.',
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
            style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
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
