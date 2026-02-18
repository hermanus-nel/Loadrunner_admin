// lib/features/payments/presentation/widgets/retry_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/payment_entity.dart';

/// Dialog for confirming payment retry
class RetryDialog extends StatefulWidget {
  final PaymentEntity payment;
  final Future<bool> Function() onConfirm;

  const RetryDialog({
    super.key,
    required this.payment,
    required this.onConfirm,
  });

  /// Show the retry confirmation dialog
  static Future<bool?> show({
    required BuildContext context,
    required PaymentEntity payment,
    required Future<bool> Function() onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RetryDialog(
        payment: payment,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<RetryDialog> createState() => _RetryDialogState();
}

class _RetryDialogState extends State<RetryDialog> {
  bool _isProcessing = false;

  final _currencyFormat = NumberFormat.currency(symbol: 'R', decimalDigits: 2);
  final _dateFormat = DateFormat('dd MMM yyyy, HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.refresh,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Text('Retry Payment'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(widget.payment.amount),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  
                  // Transaction ID
                  _buildInfoRow(
                    theme,
                    'Transaction ID',
                    widget.payment.transactionId ?? 'N/A',
                    icon: Icons.receipt_outlined,
                  ),
                  const SizedBox(height: 12),
                  
                  // Original date
                  _buildInfoRow(
                    theme,
                    'Original Date',
                    _dateFormat.format(widget.payment.createdAt),
                    icon: Icons.calendar_today_outlined,
                  ),
                  const SizedBox(height: 12),
                  
                  // Payer
                  if (widget.payment.payer != null)
                    _buildInfoRow(
                      theme,
                      'Payer',
                      widget.payment.payer!.displayName,
                      icon: Icons.person_outline,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Failure reason
            if (widget.payment.failureReason != null) ...[
              Text(
                'Failure Reason',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.payment.failureReason!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Retry info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'What happens when you retry?',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildBulletPoint(
                    theme,
                    'A new transaction will be created',
                  ),
                  _buildBulletPoint(
                    theme,
                    'The payment status will change to "Pending"',
                  ),
                  _buildBulletPoint(
                    theme,
                    'The customer may receive a new payment link',
                  ),
                  _buildBulletPoint(
                    theme,
                    'Original failure details will be preserved',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Retry count warning
            if (_getRetryCount() > 0) ...[
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
                        'This payment has been retried ${_getRetryCount()} time(s) already.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : _handleConfirm,
          icon: _isProcessing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh, size: 18),
          label: const Text('Retry Payment'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    String label,
    String value, {
    IconData? icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getRetryCount() {
    return widget.payment.metadata?['retry_count'] as int? ?? 0;
  }

  Future<void> _handleConfirm() async {
    setState(() => _isProcessing = true);

    try {
      final success = await widget.onConfirm();

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
