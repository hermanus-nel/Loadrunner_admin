// lib/features/payments/domain/repositories/payments_repository.dart

import '../entities/payment_entity.dart';

/// Result type for paginated payments
class PaymentsResult {
  final List<PaymentEntity> payments;
  final PaymentsPagination pagination;

  const PaymentsResult({
    required this.payments,
    required this.pagination,
  });
}

/// Result type for refund operation
class RefundResult {
  final bool success;
  final String? refundId;
  final String? message;
  final String? errorCode;

  const RefundResult({
    required this.success,
    this.refundId,
    this.message,
    this.errorCode,
  });
}

/// Result type for retry operation
class RetryResult {
  final bool success;
  final String? newTransactionId;
  final String? message;
  final String? errorCode;

  const RetryResult({
    required this.success,
    this.newTransactionId,
    this.message,
    this.errorCode,
  });
}

/// Abstract repository for payments operations
abstract class PaymentsRepository {
  /// Fetch paginated list of payments with optional filters
  /// Returns [PaymentsResult] containing payments list and pagination info
  Future<PaymentsResult> fetchTransactions({
    PaymentFilters? filters,
    PaymentsPagination? pagination,
  });

  /// Fetch detailed information for a single payment
  /// Includes payer/payee info, shipment details, and refund info if applicable
  Future<PaymentEntity> fetchTransactionDetail(String paymentId);

  /// Process a refund for a completed payment
  /// [paymentId] - The ID of the payment to refund
  /// [reason] - The reason for the refund
  /// [amount] - Optional partial refund amount (null for full refund)
  Future<RefundResult> processRefund({
    required String paymentId,
    required String reason,
    double? amount,
  });

  /// Retry a failed payment
  /// [paymentId] - The ID of the failed payment to retry
  Future<RetryResult> retryPayment(String paymentId);

  /// Get payment statistics for dashboard
  Future<PaymentStats> getPaymentStats({
    DateTime? startDate,
    DateTime? endDate,
  });
}

/// Payment statistics for dashboard display
class PaymentStats {
  final double totalRevenue;
  final double totalCommissions;
  final int totalTransactions;
  final int successfulTransactions;
  final int failedTransactions;
  final int pendingTransactions;
  final int refundedTransactions;
  final double refundedAmount;

  const PaymentStats({
    this.totalRevenue = 0,
    this.totalCommissions = 0,
    this.totalTransactions = 0,
    this.successfulTransactions = 0,
    this.failedTransactions = 0,
    this.pendingTransactions = 0,
    this.refundedTransactions = 0,
    this.refundedAmount = 0,
  });

  double get successRate => totalTransactions > 0
      ? (successfulTransactions / totalTransactions) * 100
      : 0;
}
