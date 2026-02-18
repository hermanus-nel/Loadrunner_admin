// lib/features/payments/presentation/widgets/refund_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/payment_entity.dart';

/// Dialog for confirming and processing a refund
class RefundDialog extends StatefulWidget {
  final PaymentEntity payment;
  final Future<bool> Function(String reason, double? amount) onConfirm;

  const RefundDialog({
    super.key,
    required this.payment,
    required this.onConfirm,
  });

  /// Show the refund dialog
  static Future<bool?> show({
    required BuildContext context,
    required PaymentEntity payment,
    required Future<bool> Function(String reason, double? amount) onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RefundDialog(
        payment: payment,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends State<RefundDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _amountController = TextEditingController();
  
  bool _isFullRefund = true;
  bool _isProcessing = false;

  final _currencyFormat = NumberFormat.currency(symbol: 'R', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.payment.amount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double get _refundAmount {
    if (_isFullRefund) return widget.payment.amount;
    return double.tryParse(_amountController.text) ?? widget.payment.amount;
  }

  double get _cancellationFee => _refundAmount * 0.05;
  double get _netRefundAmount => _refundAmount - _cancellationFee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.replay,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Text('Process Refund'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Original Payment',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(widget.payment.amount),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Transaction: ${widget.payment.transactionId ?? "N/A"}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Refund type selection
              Text(
                'Refund Type',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _RefundTypeOption(
                      title: 'Full Refund',
                      subtitle: _currencyFormat.format(widget.payment.amount),
                      isSelected: _isFullRefund,
                      onTap: () => setState(() => _isFullRefund = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RefundTypeOption(
                      title: 'Partial',
                      subtitle: 'Custom amount',
                      isSelected: !_isFullRefund,
                      onTap: () => setState(() => _isFullRefund = false),
                    ),
                  ),
                ],
              ),

              // Partial refund amount input
              if (!_isFullRefund) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Refund Amount',
                    prefixText: 'R ',
                    hintText: '0.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    if (amount > widget.payment.amount) {
                      return 'Amount cannot exceed original payment';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ],

              const SizedBox(height: 20),

              // Refund reason
              Text(
                'Reason for Refund *',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  hintText: 'Enter the reason for this refund...',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 500,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a reason for the refund';
                  }
                  if (value.trim().length < 10) {
                    return 'Please provide a more detailed reason';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Refund breakdown
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Refund Breakdown',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBreakdownRow(
                      'Refund Amount',
                      _currencyFormat.format(_refundAmount),
                      theme,
                    ),
                    const SizedBox(height: 4),
                    _buildBreakdownRow(
                      'Cancellation Fee (5%)',
                      '- ${_currencyFormat.format(_cancellationFee)}',
                      theme,
                      isDeduction: true,
                    ),
                    const Divider(height: 16),
                    _buildBreakdownRow(
                      'Customer Receives',
                      _currencyFormat.format(_netRefundAmount),
                      theme,
                      isBold: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Warning
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This action cannot be undone. The refund will be processed and the payment status will be updated.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade700,
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
          onPressed: _isProcessing ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _handleConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Process Refund'),
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(
    String label,
    String value,
    ThemeData theme, {
    bool isDeduction = false,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.blue.shade700,
            fontWeight: isBold ? FontWeight.bold : null,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDeduction ? Colors.red.shade600 : Colors.blue.shade700,
            fontWeight: isBold ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final success = await widget.onConfirm(
        _reasonController.text.trim(),
        _isFullRefund ? null : _refundAmount,
      );

      if (mounted) {
        Navigator.pop(context, success);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

/// Helper widget for refund type selection
class _RefundTypeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RefundTypeOption({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : null,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
