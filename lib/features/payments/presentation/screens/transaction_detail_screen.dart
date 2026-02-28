// lib/features/payments/presentation/screens/transaction_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/payment_entity.dart';
import '../providers/payments_providers.dart';
import '../widgets/payment_status_badge.dart';
import '../widgets/refund_dialog.dart';
import '../widgets/retry_dialog.dart';

/// Screen displaying detailed information about a single transaction
class TransactionDetailScreen extends ConsumerStatefulWidget {
  final String paymentId;

  const TransactionDetailScreen({
    super.key,
    required this.paymentId,
  });

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  final _currencyFormat = NumberFormat.currency(symbol: 'R', decimalDigits: 2);
  final _dateFormat = DateFormat('dd MMM yyyy, HH:mm:ss');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(paymentDetailNotifierProvider.notifier)
          .fetchPaymentDetail(widget.paymentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(paymentDetailNotifierProvider);

    // Listen for action messages
    ref.listen<PaymentDetailState>(paymentDetailNotifierProvider, (prev, next) {
      if (next.actionMessage != null && prev?.actionMessage != next.actionMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.actionMessage!),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
        ref.read(paymentDetailNotifierProvider.notifier).clearActionMessage();
      }

      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            behavior: SnackBarBehavior.floating,
            backgroundColor: theme.colorScheme.error,
          ),
        );
        ref.read(paymentDetailNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.isLoading
                ? null
                : () => ref
                    .read(paymentDetailNotifierProvider.notifier)
                    .fetchPaymentDetail(widget.paymentId),
          ),
        ],
      ),
      body: _buildBody(theme, state),
      bottomNavigationBar: state.payment != null
          ? _buildActionBar(theme, state.payment!)
          : null,
    );
  }

  Widget _buildBody(ThemeData theme, PaymentDetailState state) {
    if (state.isLoading && state.payment == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.payment == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load transaction',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref
                  .read(paymentDetailNotifierProvider.notifier)
                  .fetchPaymentDetail(widget.paymentId),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final payment = state.payment!;

    return RefreshIndicator(
      onRefresh: () => ref
          .read(paymentDetailNotifierProvider.notifier)
          .fetchPaymentDetail(widget.paymentId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount card
            _buildAmountCard(theme, payment),

            const SizedBox(height: 20),

            // Transaction details section
            _buildSection(
              theme,
              'Transaction Details',
              Icons.receipt_long_outlined,
              [
                _buildDetailRow(
                  theme,
                  'Transaction ID',
                  payment.transactionId ?? 'N/A',
                  canCopy: true,
                ),
                if (payment.paystackReference != null)
                  _buildDetailRow(
                    theme,
                    'Paystack Reference',
                    payment.paystackReference!,
                    canCopy: true,
                  ),
                _buildDetailRow(
                  theme,
                  'Payment Method',
                  _formatPaymentMethod(payment.paymentMethod),
                ),
                if (payment.paymentChannel != null)
                  _buildDetailRow(
                    theme,
                    'Channel',
                    payment.paymentChannel!.toUpperCase(),
                  ),
                _buildDetailRow(
                  theme,
                  'Currency',
                  payment.currency,
                ),
                _buildDetailRow(
                  theme,
                  'Created At',
                  _dateFormat.format(payment.createdAt),
                ),
                if (payment.paidAt != null)
                  _buildDetailRow(
                    theme,
                    'Paid At',
                    _dateFormat.format(payment.paidAt!),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Commission breakdown
            _buildSection(
              theme,
              'Commission Breakdown',
              Icons.pie_chart_outline,
              [
                _buildDetailRow(
                  theme,
                  'Bid Amount',
                  _currencyFormat.format(payment.bidAmount),
                ),
                _buildDetailRow(
                  theme,
                  'Shipper Commission',
                  _currencyFormat.format(payment.shipperCommission),
                ),
                _buildDetailRow(
                  theme,
                  'Driver Commission',
                  _currencyFormat.format(payment.driverCommission),
                ),
                _buildDetailRow(
                  theme,
                  'Total Platform Commission',
                  _currencyFormat.format(payment.totalCommission),
                  highlight: true,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Payer info
            if (payment.payer != null)
              _buildSection(
                theme,
                'Payer (Shipper)',
                Icons.person_outline,
                [
                  _buildDetailRow(theme, 'Name', payment.payer!.displayName),
                  if (payment.payer!.phone != null)
                    _buildDetailRow(theme, 'Phone', payment.payer!.phone!),
                  if (payment.payer!.email != null)
                    _buildDetailRow(theme, 'Email', payment.payer!.email!),
                ],
              ),

            if (payment.payer != null) const SizedBox(height: 16),

            // Payee info
            if (payment.payee != null)
              _buildSection(
                theme,
                'Payee (Driver)',
                Icons.local_shipping_outlined,
                [
                  _buildDetailRow(theme, 'Name', payment.payee!.displayName),
                  if (payment.payee!.phone != null)
                    _buildDetailRow(theme, 'Phone', payment.payee!.phone!),
                  if (payment.payee!.email != null)
                    _buildDetailRow(theme, 'Email', payment.payee!.email!),
                ],
              ),

            if (payment.payee != null) const SizedBox(height: 16),

            // Shipment info
            if (payment.shipment != null)
              _buildSection(
                theme,
                'Related Shipment',
                Icons.inventory_2_outlined,
                [
                  _buildDetailRow(
                    theme,
                    'Shipment ID',
                    payment.shipment!.id,
                    canCopy: true,
                  ),
                  if (payment.shipment!.pickupLocation != null)
                    _buildDetailRow(
                      theme,
                      'Pickup',
                      payment.shipment!.pickupLocation!,
                    ),
                  if (payment.shipment!.deliveryLocation != null)
                    _buildDetailRow(
                      theme,
                      'Delivery',
                      payment.shipment!.deliveryLocation!,
                    ),
                  if (payment.shipment!.status != null)
                    _buildDetailRow(
                      theme,
                      'Status',
                      payment.shipment!.status!.toUpperCase(),
                    ),
                ],
              ),

            if (payment.shipment != null) const SizedBox(height: 16),

            // Failure info
            if (payment.status == PaymentStatus.failed &&
                payment.failureReason != null)
              _buildFailureSection(theme, payment),

            // Refund info
            if (payment.refund != null) _buildRefundSection(theme, payment),

            // Extra bottom padding for action bar
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard(ThemeData theme, PaymentEntity payment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(payment.amount),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getAmountColor(payment.status),
                      ),
                    ),
                  ],
                ),
                PaymentStatusBadge(status: payment.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    String label,
    String value, {
    bool canCopy = false,
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: highlight ? FontWeight.bold : null,
                      color: highlight ? theme.colorScheme.primary : null,
                    ),
                  ),
                ),
                if (canCopy)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Copy',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureSection(ThemeData theme, PaymentEntity payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Payment Failed',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            payment.failureReason!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundSection(ThemeData theme, PaymentEntity payment) {
    final refund = payment.refund!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.replay,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Refund Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRefundDetailRow(
            theme,
            'Refund Amount',
            _currencyFormat.format(refund.refundAmount),
          ),
          _buildRefundDetailRow(
            theme,
            'Cancellation Fee',
            _currencyFormat.format(refund.cancellationFee),
          ),
          _buildRefundDetailRow(
            theme,
            'Status',
            refund.status.toUpperCase(),
          ),
          if (refund.reason != null)
            _buildRefundDetailRow(
              theme,
              'Reason',
              refund.reason!,
            ),
          if (refund.initiatedAt != null)
            _buildRefundDetailRow(
              theme,
              'Initiated',
              _dateFormat.format(refund.initiatedAt!),
            ),
          if (refund.processedAt != null)
            _buildRefundDetailRow(
              theme,
              'Processed',
              _dateFormat.format(refund.processedAt!),
            ),
        ],
      ),
    );
  }

  Widget _buildRefundDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.blue.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.blue.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(ThemeData theme, PaymentEntity payment) {
    final state = ref.watch(paymentDetailNotifierProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Refund button (for completed payments)
            if (payment.canRefund)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.isProcessingAction
                      ? null
                      : () => _showRefundDialog(payment),
                  icon: const Icon(Icons.replay, size: 18),
                  label: const Text('Process Refund'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

            // Retry button (for failed payments)
            if (payment.canRetry) ...[
              if (payment.canRefund) const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.isProcessingAction
                      ? null
                      : () => _showRetryDialog(payment),
                  icon: state.isProcessingAction
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry Payment'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onPrimary,
                    backgroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],

            // Status message for non-actionable payments
            if (!payment.canRefund && !payment.canRetry)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusMessage(payment.status),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRefundDialog(PaymentEntity payment) async {
    final result = await RefundDialog.show(
      context: context,
      payment: payment,
      onConfirm: (reason, amount) async {
        return ref.read(paymentDetailNotifierProvider.notifier).processRefund(
              paymentId: payment.id,
              reason: reason,
              amount: amount,
            );
      },
    );

    if (result == true) {
      // Refresh the payments list
      ref.read(paymentsListNotifierProvider.notifier).fetchPayments(refresh: true);
    }
  }

  Future<void> _showRetryDialog(PaymentEntity payment) async {
    final result = await RetryDialog.show(
      context: context,
      payment: payment,
      onConfirm: () async {
        return ref
            .read(paymentDetailNotifierProvider.notifier)
            .retryPayment(payment.id);
      },
    );

    if (result == true) {
      // Refresh the payments list
      ref.read(paymentsListNotifierProvider.notifier).fetchPayments(refresh: true);
    }
  }

  Color _getAmountColor(PaymentStatus status) {
    switch (status) {
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

  String _formatPaymentMethod(String? method) {
    if (method == null) return 'N/A';
    switch (method.toLowerCase()) {
      case 'card':
        return 'Credit/Debit Card';
      case 'bank':
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'ussd':
        return 'USSD';
      case 'qr':
        return 'QR Code';
      default:
        return method;
    }
  }

  String _getStatusMessage(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Payment is pending - waiting for completion';
      case PaymentStatus.refunded:
        return 'This payment has been refunded';
      case PaymentStatus.cancelled:
        return 'This payment was cancelled';
      default:
        return 'No actions available';
    }
  }
}
