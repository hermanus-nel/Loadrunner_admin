// lib/features/disputes/presentation/widgets/resolution_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/dispute_entity.dart';

class ResolutionDialog extends StatefulWidget {
  final String disputeId;
  final DisputeEntity dispute;
  final Future<bool> Function(
    ResolutionType resolution,
    String notes,
    double? refundAmount,
  ) onResolve;

  const ResolutionDialog({
    super.key,
    required this.disputeId,
    required this.dispute,
    required this.onResolve,
  });

  @override
  State<ResolutionDialog> createState() => _ResolutionDialogState();
}

class _ResolutionDialogState extends State<ResolutionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _refundController = TextEditingController();
  ResolutionType _selectedResolution = ResolutionType.noAction;
  bool _includeRefund = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    _refundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.gavel,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resolve Dispute',
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          '#${widget.disputeId.substring(0, 8)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dispute summary
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.dispute.title,
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '${widget.dispute.raisedBy?.displayName ?? "User"} vs ${widget.dispute.raisedAgainst?.displayName ?? "User"}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Resolution type
                      Text(
                        'Resolution Decision',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ...ResolutionType.values.map((type) => RadioListTile<ResolutionType>(
                            value: type,
                            groupValue: _selectedResolution,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedResolution = value);
                              }
                            },
                            title: Text(type.displayName),
                            subtitle: Text(
                              _getResolutionDescription(type),
                              style: theme.textTheme.bodySmall,
                            ),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          )),
                      const SizedBox(height: 16),

                      // Refund option
                      if (_selectedResolution == ResolutionType.favorShipper ||
                          _selectedResolution == ResolutionType.splitDecision) ...[
                        CheckboxListTile(
                          value: _includeRefund,
                          onChanged: (value) {
                            setState(() => _includeRefund = value ?? false);
                          },
                          title: const Text('Include refund'),
                          subtitle: const Text('Issue a refund to the shipper'),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        if (_includeRefund) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _refundController,
                            decoration: InputDecoration(
                              labelText: 'Refund Amount',
                              prefixText: 'R ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            validator: (value) {
                              if (_includeRefund && (value == null || value.isEmpty)) {
                                return 'Please enter refund amount';
                              }
                              if (_includeRefund) {
                                final amount = double.tryParse(value ?? '');
                                if (amount == null || amount <= 0) {
                                  return 'Please enter a valid amount';
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],

                      // Notes
                      Text(
                        'Resolution Notes',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          hintText: 'Explain the resolution decision...',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please provide resolution notes';
                          }
                          if (value.length < 10) {
                            return 'Please provide more detail (min 10 characters)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Warning
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.error.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'This action cannot be undone. Both parties will be notified of the resolution.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
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
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Resolve Dispute'),
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

  String _getResolutionDescription(ResolutionType type) {
    switch (type) {
      case ResolutionType.favorShipper:
        return 'The shipper\'s complaint is valid. Driver at fault.';
      case ResolutionType.favorDriver:
        return 'The driver is not at fault. Shipper\'s claim dismissed.';
      case ResolutionType.splitDecision:
        return 'Both parties share responsibility.';
      case ResolutionType.mediated:
        return 'A compromise was reached between parties.';
      case ResolutionType.noAction:
        return 'No action required. Insufficient evidence or invalid claim.';
      case ResolutionType.escalated:
        return 'Escalate to senior admin for review.';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final refundAmount = _includeRefund
        ? double.tryParse(_refundController.text)
        : null;

    final success = await widget.onResolve(
      _selectedResolution,
      _notesController.text,
      refundAmount,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dispute resolved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to resolve dispute'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Quick action buttons for dispute resolution
class ResolutionActions extends StatelessWidget {
  final DisputeEntity dispute;
  final VoidCallback? onResolve;
  final VoidCallback? onEscalate;
  final VoidCallback? onRequestEvidence;

  const ResolutionActions({
    super.key,
    required this.dispute,
    this.onResolve,
    this.onEscalate,
    this.onRequestEvidence,
  });

  @override
  Widget build(BuildContext context) {
    if (!dispute.isActive) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (onResolve != null)
          FilledButton.icon(
            onPressed: onResolve,
            icon: const Icon(Icons.check),
            label: const Text('Resolve'),
          ),
        if (onEscalate != null)
          OutlinedButton.icon(
            onPressed: onEscalate,
            icon: const Icon(Icons.arrow_upward),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
            label: const Text('Escalate'),
          ),
        if (onRequestEvidence != null)
          OutlinedButton.icon(
            onPressed: onRequestEvidence,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Request Evidence'),
          ),
      ],
    );
  }
}

/// Request evidence dialog
class RequestEvidenceDialog extends StatefulWidget {
  final DisputeEntity dispute;
  final Future<bool> Function(String userId, String message) onRequest;

  const RequestEvidenceDialog({
    super.key,
    required this.dispute,
    required this.onRequest,
  });

  @override
  State<RequestEvidenceDialog> createState() => _RequestEvidenceDialogState();
}

class _RequestEvidenceDialogState extends State<RequestEvidenceDialog> {
  final _messageController = TextEditingController();
  String? _selectedUserId;
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Request Evidence'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request from:',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          RadioListTile<String>(
            value: widget.dispute.raisedById,
            groupValue: _selectedUserId,
            onChanged: (value) {
              setState(() => _selectedUserId = value);
            },
            title: Text(widget.dispute.raisedBy?.displayName ?? 'User who raised'),
            subtitle: const Text('Raised the dispute'),
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<String>(
            value: widget.dispute.raisedAgainstId,
            groupValue: _selectedUserId,
            onChanged: (value) {
              setState(() => _selectedUserId = value);
            },
            title: Text(widget.dispute.raisedAgainst?.displayName ?? 'User raised against'),
            subtitle: const Text('Raised against'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText: 'Specify what evidence is needed...',
              alignLabelWithHint: true,
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading || _selectedUserId == null ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Request'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_selectedUserId == null || _messageController.text.isEmpty) return;

    setState(() => _isLoading = true);

    final success = await widget.onRequest(
      _selectedUserId!,
      _messageController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Evidence request sent' : 'Failed to send request',
          ),
        ),
      );
    }
  }
}
