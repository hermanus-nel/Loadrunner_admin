// lib/features/payments/data/repositories/payments_repository_impl.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/jwt_recovery_handler.dart';
import '../../../../core/services/supabase_provider.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payments_repository.dart';
import '../models/payment_model.dart';

/// Implementation of PaymentsRepository using Supabase
class PaymentsRepositoryImpl implements PaymentsRepository {
  final SupabaseProvider _supabaseProvider;
  final JwtRecoveryHandler _jwtRecoveryHandler;

  PaymentsRepositoryImpl({
    required SupabaseProvider supabaseProvider,
    required JwtRecoveryHandler jwtRecoveryHandler,
  })  : _supabaseProvider = supabaseProvider,
        _jwtRecoveryHandler = jwtRecoveryHandler;

  SupabaseClient get _client => _supabaseProvider.client;

  @override
  Future<PaymentsResult> fetchTransactions({
    PaymentFilters? filters,
    PaymentsPagination? pagination,
  }) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      final page = pagination?.page ?? 1;
      final pageSize = pagination?.pageSize ?? 20;
      final offset = (page - 1) * pageSize;

      // Build base query
      var query = _client
          .from('payments')
          .select('''
            *,
            shipper:shipper_id(id, first_name, last_name, phone_number, email),
            freight_posts:freight_post_id(id, pickup_location_name, dropoff_location_name, status, created_at),
            bids:bid_id(id, vehicle_id, vehicles:vehicle_id(driver_id, driver:driver_id(id, first_name, last_name, phone_number, email))),
            payment_refunds(id, refund_amount, cancellation_fee, status, cancellation_reason, initiated_at, processed_at)
          ''');

      // Pre-fetch matching user IDs if search query includes user name search
      String? searchOrClause;
      if (filters != null &&
          filters.searchQuery != null &&
          filters.searchQuery!.isNotEmpty) {
        final searchTerm = filters.searchQuery!;

        // Search for matching user IDs by name
        final userResults = await _client
            .from('users')
            .select('id')
            .ilike('full_name', '%$searchTerm%');

        final matchingUserIds = (userResults as List)
            .map((u) => u['id'] as String)
            .toList();

        if (matchingUserIds.isNotEmpty) {
          searchOrClause =
              'transaction_id.ilike.%$searchTerm%,'
              'paystack_reference.ilike.%$searchTerm%,'
              'shipper_id.in.(${matchingUserIds.join(",")})';
        } else {
          searchOrClause =
              'transaction_id.ilike.%$searchTerm%,'
              'paystack_reference.ilike.%$searchTerm%';
        }
      }

      // Apply filters to main query
      if (filters != null) {
        if (filters.status != null) {
          query = query.eq('status', filters.status!.dbValue);
        }

        if (filters.startDate != null) {
          query = query.gte('created_at', filters.startDate!.toIso8601String());
        }

        if (filters.endDate != null) {
          final endDatePlusOne = filters.endDate!.add(const Duration(days: 1));
          query = query.lt('created_at', endDatePlusOne.toIso8601String());
        }

        if (filters.minAmount != null) {
          query = query.gte('amount', filters.minAmount!);
        }

        if (filters.maxAmount != null) {
          query = query.lte('amount', filters.maxAmount!);
        }

        if (searchOrClause != null) {
          query = query.or(searchOrClause);
        }
      }

      // Get total count for pagination (with same filters applied)
      var countQuery = _client.from('payments').select('id');

      if (filters != null) {
        if (filters.status != null) {
          countQuery = countQuery.eq('status', filters.status!.dbValue);
        }
        if (filters.startDate != null) {
          countQuery = countQuery.gte('created_at', filters.startDate!.toIso8601String());
        }
        if (filters.endDate != null) {
          final endDatePlusOne = filters.endDate!.add(const Duration(days: 1));
          countQuery = countQuery.lt('created_at', endDatePlusOne.toIso8601String());
        }
        if (filters.minAmount != null) {
          countQuery = countQuery.gte('amount', filters.minAmount!);
        }
        if (filters.maxAmount != null) {
          countQuery = countQuery.lte('amount', filters.maxAmount!);
        }
        if (searchOrClause != null) {
          countQuery = countQuery.or(searchOrClause);
        }
      }

      final countResponse = await countQuery.count(CountOption.exact);
      final totalCount = countResponse.count;

      // Apply pagination and ordering
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + pageSize - 1);

      debugPrint('📊 Fetched ${(response as List).length} payments');

      final payments = (response as List)
          .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
          .map((model) => model.toEntity())
          .toList();

      return PaymentsResult(
        payments: payments,
        pagination: PaymentsPagination(
          page: page,
          pageSize: pageSize,
          totalCount: totalCount,
          hasMore: offset + payments.length < totalCount,
        ),
      );
    });
  }

  @override
  Future<PaymentEntity> fetchTransactionDetail(String paymentId) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      final response = await _client
          .from('payments')
          .select('''
            *,
            shipper:shipper_id(id, first_name, last_name, phone_number, email, role),
            freight_posts:freight_post_id(
              id,
              pickup_location_name,
              dropoff_location_name,
              status,
              created_at
            ),
            bids:bid_id(
              id,
              vehicle_id,
              bid_amount,
              status,
              vehicles:vehicle_id(driver_id, driver:driver_id(id, first_name, last_name, phone_number, email))
            ),
            payment_refunds(
              id, 
              refund_amount, 
              cancellation_fee, 
              status, 
              cancellation_reason, 
              failure_reason,
              initiated_at, 
              processed_at,
              cancelled_by
            )
          ''')
          .eq('id', paymentId)
          .single();

      debugPrint('📊 Fetched payment detail: $paymentId');

      final model = PaymentModel.fromJson(response);
      return model.toEntity();
    });
  }

  @override
  Future<RefundResult> processRefund({
    required String paymentId,
    required String reason,
    double? amount,
  }) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        // First, get the payment details
        final payment = await fetchTransactionDetail(paymentId);

        if (!payment.canRefund) {
          return RefundResult(
            success: false,
            message: 'This payment cannot be refunded',
            errorCode: 'INVALID_STATE',
          );
        }

        // Calculate refund amount (full refund if amount not specified)
        final refundAmount = amount ?? payment.amount;
        
        // Calculate 5% cancellation fee
        final cancellationFee = refundAmount * 0.05;
        final netRefundAmount = refundAmount - cancellationFee;

        // Get escrow holding for this payment
        final escrowResponse = await _client
            .from('escrow_holdings')
            .select('id')
            .eq('payment_id', paymentId)
            .maybeSingle();

        final escrowId = escrowResponse?['id'] as String?;

        // Create refund record
        final refundResponse = await _client
            .from('payment_refunds')
            .insert({
              'payment_id': paymentId,
              'escrow_id': escrowId,
              'freight_post_id': payment.freightPostId,
              'shipper_id': payment.shipperId,
              'original_amount': payment.amount,
              'refund_amount': netRefundAmount,
              'cancellation_fee': cancellationFee,
              'status': 'pending',
              'cancellation_reason': reason,
              'initiated_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

        final refundId = refundResponse['id'] as String;

        // Update payment status to refunded
        await _client
            .from('payments')
            .update({
              'status': 'refunded',
              'modified_at': DateTime.now().toIso8601String(),
            })
            .eq('id', paymentId);

        // Log the action in admin_audit_logs (if table exists)
        try {
          final adminUserId = await _supabaseProvider.getCurrentUserId();
          await _client.from('admin_audit_logs').insert({
            'admin_id': adminUserId,
            'action': 'process_refund',
            'target_type': 'payment',
            'target_id': paymentId,
            'new_values': {
              'refund_id': refundId,
              'refund_amount': netRefundAmount,
              'cancellation_fee': cancellationFee,
              'reason': reason,
            },
          });
        } catch (e) {
          // Audit logging failure should not block the refund
          debugPrint('⚠️ Failed to log audit: $e');
        }

        debugPrint('✅ Refund processed: $refundId');

        return RefundResult(
          success: true,
          refundId: refundId,
          message: 'Refund of R${netRefundAmount.toStringAsFixed(2)} initiated successfully',
        );
      } catch (e) {
        debugPrint('❌ Refund failed: $e');
        return RefundResult(
          success: false,
          message: 'Failed to process refund: ${e.toString()}',
          errorCode: 'REFUND_FAILED',
        );
      }
    });
  }

  @override
  Future<RetryResult> retryPayment(String paymentId) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        // Get the failed payment details
        final payment = await fetchTransactionDetail(paymentId);

        if (!payment.canRetry) {
          return RetryResult(
            success: false,
            message: 'This payment cannot be retried',
            errorCode: 'INVALID_STATE',
          );
        }

        // Generate new transaction ID
        final newTransactionId = 'RETRY_${DateTime.now().millisecondsSinceEpoch}';

        // Update payment to pending status with new transaction ID
        await _client
            .from('payments')
            .update({
              'status': 'pending',
              'transaction_id': newTransactionId,
              'modified_at': DateTime.now().toIso8601String(),
              'metadata': {
                ...?payment.metadata,
                'retry_count': (payment.metadata?['retry_count'] ?? 0) + 1,
                'original_transaction_id': payment.transactionId,
                'retried_at': DateTime.now().toIso8601String(),
              },
            })
            .eq('id', paymentId);

        // Log the action
        try {
          final adminUserId = await _supabaseProvider.getCurrentUserId();
          await _client.from('admin_audit_logs').insert({
            'admin_id': adminUserId,
            'action': 'retry_payment',
            'target_type': 'payment',
            'target_id': paymentId,
            'new_values': {
              'new_transaction_id': newTransactionId,
              'original_transaction_id': payment.transactionId,
            },
          });
        } catch (e) {
          debugPrint('⚠️ Failed to log audit: $e');
        }

        debugPrint('✅ Payment retry initiated: $newTransactionId');

        return RetryResult(
          success: true,
          newTransactionId: newTransactionId,
          message: 'Payment retry initiated successfully',
        );
      } catch (e) {
        debugPrint('❌ Retry failed: $e');
        return RetryResult(
          success: false,
          message: 'Failed to retry payment: ${e.toString()}',
          errorCode: 'RETRY_FAILED',
        );
      }
    });
  }

  @override
  Future<PaymentStats> getPaymentStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      // Default to last 30 days if no dates provided
      final effectiveStartDate = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final effectiveEndDate = endDate ?? DateTime.now();

      var query = _client.from('payments').select('amount, status, total_commission');

      query = query.gte('created_at', effectiveStartDate.toIso8601String());
      query = query.lte('created_at', effectiveEndDate.toIso8601String());

      final response = await query;

      double totalRevenue = 0;
      double totalCommissions = 0;
      int successfulTransactions = 0;
      int failedTransactions = 0;
      int pendingTransactions = 0;
      int refundedTransactions = 0;

      for (final payment in response as List) {
        final amount = _parseDouble(payment['amount']);
        final commission = _parseDouble(payment['total_commission']);
        final status = payment['status'] as String? ?? 'pending';

        switch (status) {
          case 'success':
          case 'completed':
            successfulTransactions++;
            totalRevenue += amount;
            totalCommissions += commission;
            break;
          case 'failed':
            failedTransactions++;
            break;
          case 'pending':
            pendingTransactions++;
            break;
          case 'refunded':
            refundedTransactions++;
            break;
        }
      }

      // Get refunded amounts
      final refundsQuery = await _client
          .from('payment_refunds')
          .select('refund_amount')
          .gte('created_at', effectiveStartDate.toIso8601String())
          .lte('created_at', effectiveEndDate.toIso8601String())
          .eq('status', 'success');

      double refundedAmount = 0;
      for (final refund in refundsQuery as List) {
        refundedAmount += _parseDouble(refund['refund_amount']);
      }

      return PaymentStats(
        totalRevenue: totalRevenue,
        totalCommissions: totalCommissions,
        totalTransactions: (response as List).length,
        successfulTransactions: successfulTransactions,
        failedTransactions: failedTransactions,
        pendingTransactions: pendingTransactions,
        refundedTransactions: refundedTransactions,
        refundedAmount: refundedAmount,
      );
    });
  }

  /// Helper to parse double from various types
  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
