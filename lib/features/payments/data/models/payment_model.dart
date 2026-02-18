// lib/features/payments/data/models/payment_model.dart

import '../../domain/entities/payment_entity.dart';

/// Data model for Payment with JSON serialization
class PaymentModel {
  final String id;
  final double amount;
  final String status;
  final String? paymentMethod;
  final String? paymentChannel;
  final String currency;
  final DateTime createdAt;
  final DateTime? modifiedAt;
  final DateTime? paidAt;
  final String? freightPostId;
  final String? bidId;
  final String? shipperId;
  final double bidAmount;
  final double shipperCommission;
  final double driverCommission;
  final double totalCommission;
  final String? transactionId;
  final String? paystackReference;
  final String? paystackAccessCode;
  final String? paystackAuthorizationUrl;
  final Map<String, dynamic>? metadata;

  // Related data from joins
  final Map<String, dynamic>? shipperData;
  final Map<String, dynamic>? freightPostData;
  final Map<String, dynamic>? bidData;
  final Map<String, dynamic>? refundData;

  PaymentModel({
    required this.id,
    required this.amount,
    required this.status,
    this.paymentMethod,
    this.paymentChannel,
    this.currency = 'ZAR',
    required this.createdAt,
    this.modifiedAt,
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
    this.paystackAccessCode,
    this.paystackAuthorizationUrl,
    this.metadata,
    this.shipperData,
    this.freightPostData,
    this.bidData,
    this.refundData,
  });

  /// Create from JSON (Supabase response)
  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      amount: _parseDouble(json['amount']),
      status: json['status'] as String? ?? 'pending',
      paymentMethod: json['payment_method'] as String?,
      paymentChannel: json['payment_channel'] as String?,
      currency: json['currency'] as String? ?? 'ZAR',
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      modifiedAt: _parseDateTime(json['modified_at']),
      paidAt: _parseDateTime(json['paid_at']),
      freightPostId: json['freight_post_id'] as String?,
      bidId: json['bid_id'] as String?,
      shipperId: json['shipper_id'] as String?,
      bidAmount: _parseDouble(json['bid_amount']),
      shipperCommission: _parseDouble(json['shipper_commission']),
      driverCommission: _parseDouble(json['driver_commission']),
      totalCommission: _parseDouble(json['total_commission']),
      transactionId: json['transaction_id'] as String?,
      paystackReference: json['paystack_reference'] as String?,
      paystackAccessCode: json['paystack_access_code'] as String?,
      paystackAuthorizationUrl: json['paystack_authorization_url'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      // Related data from joins
      shipperData: _asMap(json['shipper']),
      freightPostData: _asMap(json['freight_posts']),
      bidData: _asMap(json['bids']),
      refundData: _asMap(json['payment_refunds']),
    );
  }

  /// Convert to PaymentEntity
  PaymentEntity toEntity() {
    return PaymentEntity(
      id: id,
      amount: amount,
      status: PaymentStatus.fromString(status),
      paymentMethod: paymentMethod,
      paymentChannel: paymentChannel,
      currency: currency,
      createdAt: createdAt,
      paidAt: paidAt,
      freightPostId: freightPostId,
      bidId: bidId,
      shipperId: shipperId,
      bidAmount: bidAmount,
      shipperCommission: shipperCommission,
      driverCommission: driverCommission,
      totalCommission: totalCommission,
      transactionId: transactionId,
      paystackReference: paystackReference,
      failureReason: _extractFailureReason(),
      payer: _extractPayer(),
      payee: _extractPayee(),
      shipment: _extractShipment(),
      refund: _extractRefund(),
      metadata: metadata,
    );
  }

  /// Extract failure reason from metadata or status
  String? _extractFailureReason() {
    if (status != 'failed') return null;
    return metadata?['failure_reason'] as String? ??
        metadata?['error_message'] as String?;
  }

  /// Build full name from first_name and last_name
  String? _buildFullName(Map<String, dynamic>? data) {
    if (data == null) return null;
    final first = data['first_name'] as String?;
    final last = data['last_name'] as String?;
    if (first == null && last == null) return null;
    return [first, last].whereType<String>().join(' ').trim();
  }

  /// Extract payer (shipper) info
  PaymentUserInfo? _extractPayer() {
    if (shipperData == null) return null;
    return PaymentUserInfo(
      id: shipperData!['id'] as String? ?? shipperId ?? '',
      fullName: _buildFullName(shipperData),
      phone: shipperData!['phone_number'] as String?,
      email: shipperData!['email'] as String?,
      userType: 'shipper',
    );
  }

  /// Extract payee (driver) info from bid → vehicle → driver
  PaymentUserInfo? _extractPayee() {
    if (bidData == null) return null;

    final vehicleData = bidData!['vehicles'] as Map<String, dynamic>?;
    final driverData = vehicleData?['driver'] as Map<String, dynamic>?;
    final driverId = vehicleData?['driver_id'] as String?;

    if (driverId == null && driverData == null) return null;

    return PaymentUserInfo(
      id: driverData?['id'] as String? ?? driverId ?? '',
      fullName: _buildFullName(driverData),
      phone: driverData?['phone_number'] as String?,
      email: driverData?['email'] as String?,
      userType: 'driver',
    );
  }

  /// Extract shipment info from freight post
  PaymentShipmentInfo? _extractShipment() {
    if (freightPostData == null && freightPostId == null) return null;
    return PaymentShipmentInfo(
      id: freightPostData?['id'] as String? ?? freightPostId ?? '',
      pickupLocation: freightPostData?['pickup_location_name'] as String?,
      deliveryLocation: freightPostData?['dropoff_location_name'] as String?,
      status: freightPostData?['status'] as String?,
      createdAt: _parseDateTime(freightPostData?['created_at']),
    );
  }

  /// Extract refund info if exists
  PaymentRefundInfo? _extractRefund() {
    if (refundData == null) return null;
    return PaymentRefundInfo(
      id: refundData!['id'] as String,
      refundAmount: _parseDouble(refundData!['refund_amount']),
      cancellationFee: _parseDouble(refundData!['cancellation_fee']),
      status: refundData!['status'] as String? ?? 'pending',
      reason: refundData!['cancellation_reason'] as String?,
      initiatedAt: _parseDateTime(refundData!['initiated_at']),
      processedAt: _parseDateTime(refundData!['processed_at']),
    );
  }

  /// Helper to parse double from various types
  /// Helper to safely extract a Map from a join result that may be a List or Map
  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is List && value.isNotEmpty) return value.first as Map<String, dynamic>?;
    return null;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  /// Helper to parse DateTime from various types
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Convert to JSON (for updates)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'status': status,
      'payment_method': paymentMethod,
      'payment_channel': paymentChannel,
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt?.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'freight_post_id': freightPostId,
      'bid_id': bidId,
      'shipper_id': shipperId,
      'bid_amount': bidAmount,
      'shipper_commission': shipperCommission,
      'driver_commission': driverCommission,
      'total_commission': totalCommission,
      'transaction_id': transactionId,
      'paystack_reference': paystackReference,
      'metadata': metadata,
    };
  }
}

/// Model for refund data
class RefundModel {
  final String id;
  final String paymentId;
  final String? escrowId;
  final String freightPostId;
  final String shipperId;
  final double originalAmount;
  final double refundAmount;
  final double cancellationFee;
  final String? paystackRefundReference;
  final String? paystackTransactionReference;
  final String status;
  final String? failureReason;
  final String? cancellationReason;
  final String? cancelledBy;
  final DateTime? initiatedAt;
  final DateTime? processedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  RefundModel({
    required this.id,
    required this.paymentId,
    this.escrowId,
    required this.freightPostId,
    required this.shipperId,
    required this.originalAmount,
    required this.refundAmount,
    required this.cancellationFee,
    this.paystackRefundReference,
    this.paystackTransactionReference,
    required this.status,
    this.failureReason,
    this.cancellationReason,
    this.cancelledBy,
    this.initiatedAt,
    this.processedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RefundModel.fromJson(Map<String, dynamic> json) {
    return RefundModel(
      id: json['id'] as String,
      paymentId: json['payment_id'] as String,
      escrowId: json['escrow_id'] as String?,
      freightPostId: json['freight_post_id'] as String,
      shipperId: json['shipper_id'] as String,
      originalAmount: PaymentModel._parseDouble(json['original_amount']),
      refundAmount: PaymentModel._parseDouble(json['refund_amount']),
      cancellationFee: PaymentModel._parseDouble(json['cancellation_fee']),
      paystackRefundReference: json['paystack_refund_reference'] as String?,
      paystackTransactionReference: json['paystack_transaction_reference'] as String?,
      status: json['status'] as String? ?? 'pending',
      failureReason: json['failure_reason'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      cancelledBy: json['cancelled_by'] as String?,
      initiatedAt: PaymentModel._parseDateTime(json['initiated_at']),
      processedAt: PaymentModel._parseDateTime(json['processed_at']),
      createdAt: PaymentModel._parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: PaymentModel._parseDateTime(json['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_id': paymentId,
      'escrow_id': escrowId,
      'freight_post_id': freightPostId,
      'shipper_id': shipperId,
      'original_amount': originalAmount,
      'refund_amount': refundAmount,
      'cancellation_fee': cancellationFee,
      'paystack_refund_reference': paystackRefundReference,
      'paystack_transaction_reference': paystackTransactionReference,
      'status': status,
      'failure_reason': failureReason,
      'cancellation_reason': cancellationReason,
      'cancelled_by': cancelledBy,
      'initiated_at': initiatedAt?.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
