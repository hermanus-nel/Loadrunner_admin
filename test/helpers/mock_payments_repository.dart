// test/helpers/mock_payments_repository.dart

import '../../lib/features/payments/domain/entities/payment_entity.dart';
import '../../lib/features/payments/domain/repositories/payments_repository.dart';

/// Mock PaymentsRepository for testing payment flows
class MockPaymentsRepository implements PaymentsRepository {
  final List<PaymentEntity> _payments = [];
  bool shouldFail = false;
  bool shouldFailRefund = false;
  bool shouldFailRetry = false;

  void seedPayments(List<PaymentEntity> payments) {
    _payments
      ..clear()
      ..addAll(payments);
  }

  @override
  Future<PaymentsResult> fetchTransactions({
    PaymentFilters? filters,
    PaymentsPagination? pagination,
  }) async {
    if (shouldFail) throw Exception('Mock fetch failed');

    final page = pagination?.page ?? 1;
    final pageSize = pagination?.pageSize ?? 20;
    final offset = (page - 1) * pageSize;

    var filtered = List<PaymentEntity>.from(_payments);

    if (filters?.status != null) {
      filtered = filtered.where((p) => p.status == filters!.status).toList();
    }
    if (filters?.startDate != null) {
      filtered = filtered.where((p) => p.createdAt.isAfter(filters!.startDate!)).toList();
    }
    if (filters?.endDate != null) {
      filtered = filtered.where((p) => p.createdAt.isBefore(filters!.endDate!)).toList();
    }
    if (filters?.minAmount != null) {
      filtered = filtered.where((p) => p.amount >= filters!.minAmount!).toList();
    }
    if (filters?.maxAmount != null) {
      filtered = filtered.where((p) => p.amount <= filters!.maxAmount!).toList();
    }

    final totalCount = filtered.length;
    final paged = filtered.skip(offset).take(pageSize).toList();

    return PaymentsResult(
      payments: paged,
      pagination: PaymentsPagination(
        page: page,
        pageSize: pageSize,
        totalCount: totalCount,
        hasMore: offset + paged.length < totalCount,
      ),
    );
  }

  @override
  Future<PaymentEntity> fetchTransactionDetail(String paymentId) async {
    if (shouldFail) throw Exception('Mock fetch detail failed');
    return _payments.firstWhere((p) => p.id == paymentId);
  }

  @override
  Future<RefundResult> processRefund({
    required String paymentId,
    required String reason,
    double? amount,
  }) async {
    if (shouldFailRefund) {
      return const RefundResult(
        success: false,
        message: 'Refund failed',
        errorCode: 'REFUND_FAILED',
      );
    }

    final index = _payments.indexWhere((p) => p.id == paymentId);
    if (index == -1) {
      return const RefundResult(
        success: false,
        message: 'Payment not found',
        errorCode: 'NOT_FOUND',
      );
    }

    _payments[index] = _payments[index].copyWith(
      status: PaymentStatus.refunded,
    );

    return RefundResult(
      success: true,
      refundId: 'refund-${DateTime.now().millisecondsSinceEpoch}',
      message: 'Refund processed successfully',
    );
  }

  @override
  Future<RetryResult> retryPayment(String paymentId) async {
    if (shouldFailRetry) {
      return const RetryResult(
        success: false,
        message: 'Retry failed',
        errorCode: 'RETRY_FAILED',
      );
    }

    final index = _payments.indexWhere((p) => p.id == paymentId);
    if (index == -1) {
      return const RetryResult(
        success: false,
        message: 'Payment not found',
        errorCode: 'NOT_FOUND',
      );
    }

    _payments[index] = _payments[index].copyWith(
      status: PaymentStatus.pending,
    );

    return RetryResult(
      success: true,
      newTransactionId: 'RETRY_${DateTime.now().millisecondsSinceEpoch}',
      message: 'Retry initiated',
    );
  }

  @override
  Future<PaymentStats> getPaymentStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (shouldFail) throw Exception('Mock stats failed');

    double totalRevenue = 0;
    double totalCommissions = 0;
    int successful = 0, failed = 0, pending = 0, refunded = 0;

    for (final p in _payments) {
      switch (p.status) {
        case PaymentStatus.success:
          successful++;
          totalRevenue += p.amount;
          totalCommissions += p.totalCommission;
          break;
        case PaymentStatus.failed:
          failed++;
          break;
        case PaymentStatus.pending:
          pending++;
          break;
        case PaymentStatus.refunded:
          refunded++;
          break;
        case PaymentStatus.cancelled:
          break;
      }
    }

    return PaymentStats(
      totalRevenue: totalRevenue,
      totalCommissions: totalCommissions,
      totalTransactions: _payments.length,
      successfulTransactions: successful,
      failedTransactions: failed,
      pendingTransactions: pending,
      refundedTransactions: refunded,
    );
  }
}
