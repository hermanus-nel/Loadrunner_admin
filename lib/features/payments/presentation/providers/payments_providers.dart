// lib/features/payments/presentation/providers/payments_providers.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/core_providers.dart';
import '../../data/repositories/payments_repository_impl.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payments_repository.dart';

// ============================================================================
// Repository Provider
// ============================================================================

/// Provider for PaymentsRepository
final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  final supabaseProvider = ref.read(supabaseProviderInstance);
  final jwtRecoveryHandler = ref.read(jwtRecoveryHandlerProvider);
  
  return PaymentsRepositoryImpl(
    supabaseProvider: supabaseProvider,
    jwtRecoveryHandler: jwtRecoveryHandler,
  );
});

// ============================================================================
// State Classes
// ============================================================================

/// State for payments list
@immutable
class PaymentsListState {
  final List<PaymentEntity> payments;
  final PaymentFilters filters;
  final PaymentsPagination pagination;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final DateTime? lastFetched;

  const PaymentsListState({
    this.payments = const [],
    this.filters = const PaymentFilters(),
    this.pagination = const PaymentsPagination(),
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.lastFetched,
  });

  PaymentsListState copyWith({
    List<PaymentEntity>? payments,
    PaymentFilters? filters,
    PaymentsPagination? pagination,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    DateTime? lastFetched,
    bool clearError = false,
  }) {
    return PaymentsListState(
      payments: payments ?? this.payments,
      filters: filters ?? this.filters,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      lastFetched: lastFetched ?? this.lastFetched,
    );
  }
}

/// State for payment detail
@immutable
class PaymentDetailState {
  final PaymentEntity? payment;
  final bool isLoading;
  final String? error;
  final bool isProcessingAction;
  final String? actionMessage;

  const PaymentDetailState({
    this.payment,
    this.isLoading = false,
    this.error,
    this.isProcessingAction = false,
    this.actionMessage,
  });

  PaymentDetailState copyWith({
    PaymentEntity? payment,
    bool? isLoading,
    String? error,
    bool? isProcessingAction,
    String? actionMessage,
    bool clearError = false,
    bool clearPayment = false,
    bool clearActionMessage = false,
  }) {
    return PaymentDetailState(
      payment: clearPayment ? null : (payment ?? this.payment),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isProcessingAction: isProcessingAction ?? this.isProcessingAction,
      actionMessage: clearActionMessage ? null : (actionMessage ?? this.actionMessage),
    );
  }
}

// ============================================================================
// Notifiers
// ============================================================================

/// Notifier for managing payments list state
class PaymentsListNotifier extends StateNotifier<PaymentsListState> {
  final PaymentsRepository _repository;

  PaymentsListNotifier(this._repository) : super(const PaymentsListState());

  /// Fetch payments with current filters
  Future<void> fetchPayments({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      payments: refresh ? [] : state.payments,
      pagination: refresh ? const PaymentsPagination() : state.pagination,
    );

    try {
      final result = await _repository.fetchTransactions(
        filters: state.filters,
        pagination: PaymentsPagination(
          page: 1,
          pageSize: state.pagination.pageSize,
        ),
      );

      state = state.copyWith(
        payments: result.payments,
        pagination: result.pagination,
        isLoading: false,
        lastFetched: DateTime.now(),
      );

      debugPrint('✅ Fetched ${result.payments.length} payments');
    } catch (e) {
      debugPrint('❌ Failed to fetch payments: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load payments: ${e.toString()}',
      );
    }
  }

  /// Load more payments (pagination)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.pagination.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final result = await _repository.fetchTransactions(
        filters: state.filters,
        pagination: PaymentsPagination(
          page: state.pagination.page + 1,
          pageSize: state.pagination.pageSize,
        ),
      );

      state = state.copyWith(
        payments: [...state.payments, ...result.payments],
        pagination: result.pagination,
        isLoadingMore: false,
      );

      debugPrint('✅ Loaded ${result.payments.length} more payments');
    } catch (e) {
      debugPrint('❌ Failed to load more payments: $e');
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Failed to load more payments',
      );
    }
  }

  /// Update filters and refresh
  Future<void> updateFilters(PaymentFilters filters) async {
    state = state.copyWith(filters: filters);
    await fetchPayments(refresh: true);
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    state = state.copyWith(filters: const PaymentFilters());
    await fetchPayments(refresh: true);
  }

  /// Search by query
  Future<void> search(String query) async {
    final newFilters = state.filters.copyWith(
      searchQuery: query.isEmpty ? null : query,
      clearSearch: query.isEmpty,
    );
    await updateFilters(newFilters);
  }

  /// Filter by status
  Future<void> filterByStatus(PaymentStatus? status) async {
    final newFilters = state.filters.copyWith(
      status: status,
      clearStatus: status == null,
    );
    await updateFilters(newFilters);
  }

  /// Filter by date range
  Future<void> filterByDateRange(DateTime? start, DateTime? end) async {
    final newFilters = state.filters.copyWith(
      startDate: start,
      endDate: end,
      clearDates: start == null && end == null,
    );
    await updateFilters(newFilters);
  }

  /// Filter by amount range
  Future<void> filterByAmountRange(double? min, double? max) async {
    final newFilters = state.filters.copyWith(
      minAmount: min,
      maxAmount: max,
      clearAmounts: min == null && max == null,
    );
    await updateFilters(newFilters);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Notifier for managing payment detail state
class PaymentDetailNotifier extends StateNotifier<PaymentDetailState> {
  final PaymentsRepository _repository;

  PaymentDetailNotifier(this._repository) : super(const PaymentDetailState());

  /// Fetch payment details
  Future<void> fetchPaymentDetail(String paymentId) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearPayment: true,
    );

    try {
      final payment = await _repository.fetchTransactionDetail(paymentId);
      state = state.copyWith(
        payment: payment,
        isLoading: false,
      );
      debugPrint('✅ Fetched payment detail: $paymentId');
    } catch (e) {
      debugPrint('❌ Failed to fetch payment detail: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load payment details: ${e.toString()}',
      );
    }
  }

  /// Process refund
  Future<bool> processRefund({
    required String paymentId,
    required String reason,
    double? amount,
  }) async {
    state = state.copyWith(
      isProcessingAction: true,
      clearActionMessage: true,
    );

    try {
      final result = await _repository.processRefund(
        paymentId: paymentId,
        reason: reason,
        amount: amount,
      );

      if (result.success) {
        // Refresh payment details
        await fetchPaymentDetail(paymentId);
        state = state.copyWith(
          isProcessingAction: false,
          actionMessage: result.message ?? 'Refund processed successfully',
        );
        return true;
      } else {
        state = state.copyWith(
          isProcessingAction: false,
          error: result.message ?? 'Failed to process refund',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Refund failed: $e');
      state = state.copyWith(
        isProcessingAction: false,
        error: 'Failed to process refund: ${e.toString()}',
      );
      return false;
    }
  }

  /// Retry failed payment
  Future<bool> retryPayment(String paymentId) async {
    state = state.copyWith(
      isProcessingAction: true,
      clearActionMessage: true,
    );

    try {
      final result = await _repository.retryPayment(paymentId);

      if (result.success) {
        // Refresh payment details
        await fetchPaymentDetail(paymentId);
        state = state.copyWith(
          isProcessingAction: false,
          actionMessage: result.message ?? 'Payment retry initiated',
        );
        return true;
      } else {
        state = state.copyWith(
          isProcessingAction: false,
          error: result.message ?? 'Failed to retry payment',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Retry failed: $e');
      state = state.copyWith(
        isProcessingAction: false,
        error: 'Failed to retry payment: ${e.toString()}',
      );
      return false;
    }
  }

  /// Clear state
  void clear() {
    state = const PaymentDetailState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear action message
  void clearActionMessage() {
    state = state.copyWith(clearActionMessage: true);
  }
}

// ============================================================================
// Providers
// ============================================================================

/// Provider for payments list notifier
final paymentsListNotifierProvider =
    StateNotifierProvider<PaymentsListNotifier, PaymentsListState>((ref) {
  final repository = ref.read(paymentsRepositoryProvider);
  return PaymentsListNotifier(repository);
});

/// Provider for payment detail notifier
final paymentDetailNotifierProvider =
    StateNotifierProvider<PaymentDetailNotifier, PaymentDetailState>((ref) {
  final repository = ref.read(paymentsRepositoryProvider);
  return PaymentDetailNotifier(repository);
});

/// Provider for payment stats
final paymentStatsProvider = FutureProvider.autoDispose
    .family<PaymentStats, ({DateTime? startDate, DateTime? endDate})>((ref, params) async {
  final repository = ref.read(paymentsRepositoryProvider);
  return repository.getPaymentStats(
    startDate: params.startDate,
    endDate: params.endDate,
  );
});

/// Provider for default payment stats (last 30 days)
final defaultPaymentStatsProvider = FutureProvider.autoDispose<PaymentStats>((ref) async {
  final repository = ref.read(paymentsRepositoryProvider);
  return repository.getPaymentStats();
});
