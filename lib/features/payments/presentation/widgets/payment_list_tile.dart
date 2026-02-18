// lib/features/payments/presentation/widgets/payment_list_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/payment_entity.dart';
import 'payment_status_badge.dart';

/// List tile widget for displaying a payment in the transactions list
class PaymentListTile extends StatelessWidget {
  final PaymentEntity payment;
  final VoidCallback? onTap;

  const PaymentListTile({
    super.key,
    required this.payment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final currencyFormat = NumberFormat.currency(
      symbol: 'R',
      decimalDigits: 2,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Amount and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Amount
                  Text(
                    currencyFormat.format(payment.amount),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getAmountColor(theme),
                    ),
                  ),
                  // Status badge
                  PaymentStatusBadge(status: payment.status),
                ],
              ),

              const SizedBox(height: 12),

              // Transaction ID
              Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      payment.transactionId ?? payment.paystackReference ?? 'N/A',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Payer info
              if (payment.payer != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        payment.payer!.displayName,
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Payment method icon
                    if (payment.paymentMethod != null) ...[
                      const SizedBox(width: 8),
                      _buildPaymentMethodIcon(payment.paymentMethod!, theme),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Bottom row: Date and commission info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Date
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(payment.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  // Commission
                  if (payment.totalCommission > 0)
                    Text(
                      'Fee: ${currencyFormat.format(payment.totalCommission)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),

              // Failure reason if failed
              if (payment.status == PaymentStatus.failed && 
                  payment.failureReason != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          payment.failureReason!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Refund info if refunded
              if (payment.status == PaymentStatus.refunded && 
                  payment.refund != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.replay,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Refunded: ${currencyFormat.format(payment.refund!.refundAmount)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getAmountColor(ThemeData theme) {
    switch (payment.status) {
      case PaymentStatus.success:
        return Colors.green.shade700;
      case PaymentStatus.pending:
        return Colors.orange.shade700;
      case PaymentStatus.failed:
        return Colors.red.shade700;
      case PaymentStatus.refunded:
        return Colors.blue.shade700;
      case PaymentStatus.cancelled:
        return Colors.grey.shade600;
    }
  }

  Widget _buildPaymentMethodIcon(String method, ThemeData theme) {
    IconData icon;
    String label;

    switch (method.toLowerCase()) {
      case 'card':
        icon = Icons.credit_card;
        label = 'Card';
        break;
      case 'bank':
      case 'bank_transfer':
        icon = Icons.account_balance;
        label = 'Bank';
        break;
      case 'ussd':
        icon = Icons.phone_android;
        label = 'USSD';
        break;
      case 'qr':
        icon = Icons.qr_code;
        label = 'QR';
        break;
      default:
        icon = Icons.payment;
        label = method;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact version for showing in other contexts
class PaymentListTileCompact extends StatelessWidget {
  final PaymentEntity payment;
  final VoidCallback? onTap;

  const PaymentListTileCompact({
    super.key,
    required this.payment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yy');
    final currencyFormat = NumberFormat.currency(symbol: 'R', decimalDigits: 2);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: _getStatusColor().withOpacity(0.1),
        child: Icon(
          _getStatusIcon(),
          color: _getStatusColor(),
          size: 20,
        ),
      ),
      title: Text(
        currencyFormat.format(payment.amount),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        payment.payer?.displayName ?? 'Unknown',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          PaymentStatusBadge(status: payment.status, compact: true),
          const SizedBox(height: 4),
          Text(
            dateFormat.format(payment.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (payment.status) {
      case PaymentStatus.success:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.refunded:
        return Colors.blue;
      case PaymentStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (payment.status) {
      case PaymentStatus.success:
        return Icons.check_circle;
      case PaymentStatus.pending:
        return Icons.schedule;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.refunded:
        return Icons.replay;
      case PaymentStatus.cancelled:
        return Icons.cancel;
    }
  }
}
