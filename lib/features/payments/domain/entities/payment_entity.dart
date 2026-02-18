// lib/features/payments/domain/entities/payment_entity.dart

import 'package:flutter/foundation.dart';

/// Payment status enum matching database payment_status type
enum PaymentStatus {
  pending,
  success,
  failed,
  refunded,
  cancelled;

  static PaymentStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'success':
      case 'completed':
        return PaymentStatus.success;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'cancelled':
      case 'canceled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.pending;
    }
  }

  /// Database enum value for Supabase queries
  String get dbValue {
    switch (this) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.success:
        return 'completed';
      case PaymentStatus.failed:
        return 'failed';
      case PaymentStatus.refunded:
        return 'refunded';
      case PaymentStatus.cancelled:
        return 'failed'; // no 'cancelled' in DB enum; map to closest
    }
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.success:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// User info for payer/payee display
@immutable
class PaymentUserInfo {
  final String id;
  final String? fullName;
  final String? phone;
  final String? email;
  final String? userType; // 'shipper' or 'driver'

  const PaymentUserInfo({
    required this.id,
    this.fullName,
    this.phone,
    this.email,
    this.userType,
  });

  String get displayName => fullName ?? phone ?? 'Unknown User';
}

/// Shipment info associated with payment
@immutable
class PaymentShipmentInfo {
  final String id;
  final String? pickupLocation;
  final String? deliveryLocation;
  final String? status;
  final DateTime? createdAt;

  const PaymentShipmentInfo({
    required this.id,
    this.pickupLocation,
    this.deliveryLocation,
    this.status,
    this.createdAt,
  });
}

/// Refund information associated with payment
@immutable
class PaymentRefundInfo {
  final String id;
  final double refundAmount;
  final double cancellationFee;
  final String status;
  final String? reason;
  final DateTime? initiatedAt;
  final DateTime? processedAt;

  const PaymentRefundInfo({
    required this.id,
    required this.refundAmount,
    required this.cancellationFee,
    required this.status,
    this.reason,
    this.initiatedAt,
    this.processedAt,
  });
}

/// Main Payment Entity
@immutable
class PaymentEntity {
  final String id;
  final double amount;
  final PaymentStatus status;
  final String? paymentMethod;
  final String? paymentChannel;
  final String currency;
  final DateTime createdAt;
  final DateTime? paidAt;
  
  // IDs for relationships
  final String? freightPostId;
  final String? bidId;
  final String? shipperId;
  
  // Commission breakdown
  final double bidAmount;
  final double shipperCommission;
  final double driverCommission;
  final double totalCommission;
  
  // Paystack references
  final String? transactionId;
  final String? paystackReference;
  
  // Failure info (for failed payments)
  final String? failureReason;
  
  // Related entities (populated when fetching details)
  final PaymentUserInfo? payer;
  final PaymentUserInfo? payee;
  final PaymentShipmentInfo? shipment;
  final PaymentRefundInfo? refund;
  
  // Metadata
  final Map<String, dynamic>? metadata;

  const PaymentEntity({
    required this.id,
    required this.amount,
    required this.status,
    this.paymentMethod,
    this.paymentChannel,
    this.currency = 'ZAR',
    required this.createdAt,
    this.paidAt,
    this.freightPostId,
    this.bidId,
    this.shipperId,
    this.bidAmount = 0,
    this.shipperCommission = 0,
    this.driverCommission = 0,
    this.totalCommission = 0,
    this.transactionId,
    this.paystackReference,
    this.failureReason,
    this.payer,
    this.payee,
    this.shipment,
    this.refund,
    this.metadata,
  });

  /// Check if payment can be refunded
  bool get canRefund => status == PaymentStatus.success && refund == null;

  /// Check if payment can be retried
  bool get canRetry => status == PaymentStatus.failed;

  /// Get formatted amount with currency
  String get formattedAmount {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  /// Get net amount after commissions
  double get netAmount => bidAmount - driverCommission;

  /// Copy with method for immutability
  PaymentEntity copyWith({
    String? id,
    double? amount,
    PaymentStatus? status,
    String? paymentMethod,
    String? paymentChannel,
    String? currency,
    DateTime? createdAt,
    DateTime? paidAt,
    String? freightPostId,
    String? bidId,
    String? shipperId,
    double? bidAmount,
    double? shipperCommission,
    double? driverCommission,
    double? totalCommission,
    String? transactionId,
    String? paystackReference,
    String? failureReason,
    PaymentUserInfo? payer,
    PaymentUserInfo? payee,
    PaymentShipmentInfo? shipment,
    PaymentRefundInfo? refund,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentEntity(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentChannel: paymentChannel ?? this.paymentChannel,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
      freightPostId: freightPostId ?? this.freightPostId,
      bidId: bidId ?? this.bidId,
      shipperId: shipperId ?? this.shipperId,
      bidAmount: bidAmount ?? this.bidAmount,
      shipperCommission: shipperCommission ?? this.shipperCommission,
      driverCommission: driverCommission ?? this.driverCommission,
      totalCommission: totalCommission ?? this.totalCommission,
      transactionId: transactionId ?? this.transactionId,
      paystackReference: paystackReference ?? this.paystackReference,
      failureReason: failureReason ?? this.failureReason,
      payer: payer ?? this.payer,
      payee: payee ?? this.payee,
      shipment: shipment ?? this.shipment,
      refund: refund ?? this.refund,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Filter options for fetching payments
@immutable
class PaymentFilters {
  final PaymentStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final String? searchQuery; // Search by transaction ID or user name

  const PaymentFilters({
    this.status,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.searchQuery,
  });

  PaymentFilters copyWith({
    PaymentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    String? searchQuery,
    bool clearStatus = false,
    bool clearDates = false,
    bool clearAmounts = false,
    bool clearSearch = false,
  }) {
    return PaymentFilters(
      status: clearStatus ? null : (status ?? this.status),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      minAmount: clearAmounts ? null : (minAmount ?? this.minAmount),
      maxAmount: clearAmounts ? null : (maxAmount ?? this.maxAmount),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }

  bool get hasActiveFilters =>
      status != null ||
      startDate != null ||
      endDate != null ||
      minAmount != null ||
      maxAmount != null ||
      (searchQuery != null && searchQuery!.isNotEmpty);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentFilters &&
        other.status == status &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.minAmount == minAmount &&
        other.maxAmount == maxAmount &&
        other.searchQuery == searchQuery;
  }

  @override
  int get hashCode => Object.hash(
        status,
        startDate,
        endDate,
        minAmount,
        maxAmount,
        searchQuery,
      );
}

/// Pagination info for payments list
@immutable
class PaymentsPagination {
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;

  const PaymentsPagination({
    this.page = 1,
    this.pageSize = 20,
    this.totalCount = 0,
    this.hasMore = false,
  });

  int get totalPages => (totalCount / pageSize).ceil();

  PaymentsPagination copyWith({
    int? page,
    int? pageSize,
    int? totalCount,
    bool? hasMore,
  }) {
    return PaymentsPagination(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}
