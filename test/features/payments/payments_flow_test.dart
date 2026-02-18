// test/features/payments/payments_flow_test.dart

import 'package:flutter_test/flutter_test.dart';

import '../../../lib/features/payments/domain/entities/payment_entity.dart';
import '../../../lib/features/payments/domain/repositories/payments_repository.dart';
import '../../helpers/mock_payments_repository.dart';
import '../../helpers/test_data.dart';

void main() {
  late MockPaymentsRepository mockRepo;

  setUp(() {
    mockRepo = MockPaymentsRepository();
  });

  group('Payments Flow', () {
    group('Fetch Transactions', () {
      test('should fetch all transactions', () async {
        mockRepo.seedPayments(TestData.createPaymentsList(count: 10));

        final result = await mockRepo.fetchTransactions();

        expect(result.payments.length, equals(10));
        expect(result.pagination.totalCount, equals(10));
      });

      test('should paginate transactions', () async {
        mockRepo.seedPayments(TestData.createPaymentsList(count: 25));

        final page1 = await mockRepo.fetchTransactions(
          pagination: const PaymentsPagination(page: 1, pageSize: 10),
        );
        final page2 = await mockRepo.fetchTransactions(
          pagination: const PaymentsPagination(page: 2, pageSize: 10),
        );

        expect(page1.payments.length, equals(10));
        expect(page1.pagination.hasMore, isTrue);
        expect(page2.payments.length, equals(10));
      });

      test('should filter by status', () async {
        mockRepo.seedPayments(TestData.createPaymentsList(count: 10));

        final result = await mockRepo.fetchTransactions(
          filters: const PaymentFilters(status: PaymentStatus.success),
        );

        for (final payment in result.payments) {
          expect(payment.status, equals(PaymentStatus.success));
        }
      });

      test('should filter by amount range', () async {
        mockRepo.seedPayments([
          TestData.createPayment(id: '1', amount: 100),
          TestData.createPayment(id: '2', amount: 500),
          TestData.createPayment(id: '3', amount: 1000),
          TestData.createPayment(id: '4', amount: 2000),
        ]);

        final result = await mockRepo.fetchTransactions(
          filters: const PaymentFilters(minAmount: 400, maxAmount: 1500),
        );

        expect(result.payments.length, equals(2));
        for (final payment in result.payments) {
          expect(payment.amount, greaterThanOrEqualTo(400));
          expect(payment.amount, lessThanOrEqualTo(1500));
        }
      });

      test('should filter by date range', () async {
        final now = DateTime.now();
        mockRepo.seedPayments([
          TestData.createPayment(id: '1', amount: 100),
        ]);

        final result = await mockRepo.fetchTransactions(
          filters: PaymentFilters(
            startDate: now.subtract(const Duration(days: 7)),
            endDate: now.add(const Duration(days: 1)),
          ),
        );

        expect(result.payments, isNotEmpty);
      });

      test('should return empty list when no matches', () async {
        mockRepo.seedPayments(TestData.createPaymentsList(count: 5));

        final result = await mockRepo.fetchTransactions(
          filters: const PaymentFilters(status: PaymentStatus.cancelled),
        );

        expect(result.payments, isEmpty);
        expect(result.pagination.totalCount, equals(0));
      });

      test('should handle fetch error', () async {
        mockRepo.shouldFail = true;

        expect(
          () => mockRepo.fetchTransactions(),
          throwsException,
        );
      });
    });

    group('Transaction Detail', () {
      test('should fetch transaction detail by ID', () async {
        mockRepo.seedPayments([
          TestData.createPayment(id: 'payment-abc', amount: 750),
        ]);

        final payment = await mockRepo.fetchTransactionDetail('payment-abc');

        expect(payment.id, equals('payment-abc'));
        expect(payment.amount, equals(750));
      });

      test('should throw for non-existent payment', () async {
        mockRepo.seedPayments(TestData.createPaymentsList(count: 1));

        expect(
          () => mockRepo.fetchTransactionDetail('non-existent'),
          throwsStateError,
        );
      });
    });

    group('Process Refund', () {
      test('should refund a successful payment', () async {
        mockRepo.seedPayments([
          TestData.createPayment(
            id: 'payment-1',
            amount: 1000,
            status: PaymentStatus.success,
          ),
        ]);

        final result = await mockRepo.processRefund(
          paymentId: 'payment-1',
          reason: 'Customer requested refund',
        );

        expect(result.success, isTrue);
        expect(result.refundId, isNotNull);
        expect(result.message, contains('successfully'));

        // Verify status changed
        final updated = await mockRepo.fetchTransactionDetail('payment-1');
        expect(updated.status, equals(PaymentStatus.refunded));
      });

      test('should return failure for non-existent payment', () async {
        final result = await mockRepo.processRefund(
          paymentId: 'non-existent',
          reason: 'Test',
        );

        expect(result.success, isFalse);
        expect(result.errorCode, equals('NOT_FOUND'));
      });

      test('should handle refund failure', () async {
        mockRepo.seedPayments([
          TestData.createPayment(id: 'payment-1', status: PaymentStatus.success),
        ]);
        mockRepo.shouldFailRefund = true;

        final result = await mockRepo.processRefund(
          paymentId: 'payment-1',
          reason: 'Test refund',
        );

        expect(result.success, isFalse);
        expect(result.errorCode, equals('REFUND_FAILED'));
      });
    });

    group('Retry Payment', () {
      test('should retry a failed payment', () async {
        mockRepo.seedPayments([
          TestData.createPayment(
            id: 'payment-failed',
            amount: 500,
            status: PaymentStatus.failed,
          ),
        ]);

        final result = await mockRepo.retryPayment('payment-failed');

        expect(result.success, isTrue);
        expect(result.newTransactionId, isNotNull);

        // Verify status changed to pending
        final updated = await mockRepo.fetchTransactionDetail('payment-failed');
        expect(updated.status, equals(PaymentStatus.pending));
      });

      test('should return failure for non-existent payment', () async {
        final result = await mockRepo.retryPayment('non-existent');

        expect(result.success, isFalse);
        expect(result.errorCode, equals('NOT_FOUND'));
      });

      test('should handle retry failure', () async {
        mockRepo.seedPayments([
          TestData.createPayment(id: 'payment-1', status: PaymentStatus.failed),
        ]);
        mockRepo.shouldFailRetry = true;

        final result = await mockRepo.retryPayment('payment-1');

        expect(result.success, isFalse);
        expect(result.errorCode, equals('RETRY_FAILED'));
      });
    });

    group('Payment Stats', () {
      test('should compute correct stats', () async {
        mockRepo.seedPayments([
          TestData.createPayment(id: '1', amount: 1000, status: PaymentStatus.success),
          TestData.createPayment(id: '2', amount: 500, status: PaymentStatus.success),
          TestData.createPayment(id: '3', amount: 750, status: PaymentStatus.failed),
          TestData.createPayment(id: '4', amount: 300, status: PaymentStatus.pending),
          TestData.createPayment(id: '5', amount: 200, status: PaymentStatus.refunded),
        ]);

        final stats = await mockRepo.getPaymentStats();

        expect(stats.totalTransactions, equals(5));
        expect(stats.successfulTransactions, equals(2));
        expect(stats.failedTransactions, equals(1));
        expect(stats.pendingTransactions, equals(1));
        expect(stats.refundedTransactions, equals(1));
        expect(stats.totalRevenue, equals(1500.0)); // 1000 + 500
        expect(stats.successRate, equals(40.0)); // 2/5 * 100
      });

      test('should return zero stats when empty', () async {
        final stats = await mockRepo.getPaymentStats();

        expect(stats.totalTransactions, equals(0));
        expect(stats.totalRevenue, equals(0));
        expect(stats.successRate, equals(0));
      });

      test('should handle stats error', () async {
        mockRepo.shouldFail = true;

        expect(
          () => mockRepo.getPaymentStats(),
          throwsException,
        );
      });
    });

    group('Payment Entity', () {
      test('canRefund is true for successful payment without refund', () {
        final payment = TestData.createPayment(status: PaymentStatus.success);
        expect(payment.canRefund, isTrue);
      });

      test('canRefund is false for failed payment', () {
        final payment = TestData.createPayment(status: PaymentStatus.failed);
        expect(payment.canRefund, isFalse);
      });

      test('canRetry is true for failed payment', () {
        final payment = TestData.createPayment(status: PaymentStatus.failed);
        expect(payment.canRetry, isTrue);
      });

      test('canRetry is false for successful payment', () {
        final payment = TestData.createPayment(status: PaymentStatus.success);
        expect(payment.canRetry, isFalse);
      });

      test('formattedAmount includes currency', () {
        final payment = TestData.createPayment(amount: 1234.56);
        expect(payment.formattedAmount, contains('ZAR'));
        expect(payment.formattedAmount, contains('1234.56'));
      });
    });
  });
}
