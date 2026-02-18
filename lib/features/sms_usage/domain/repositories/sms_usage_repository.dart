// lib/features/sms_usage/domain/repositories/sms_usage_repository.dart

import 'package:equatable/equatable.dart';

// ============================================================================
// Enums
// ============================================================================

enum SmsType {
  otp,
  notification,
  broadcast,
  custom;

  String get displayName {
    switch (this) {
      case SmsType.otp:
        return 'OTP';
      case SmsType.notification:
        return 'Notification';
      case SmsType.broadcast:
        return 'Broadcast';
      case SmsType.custom:
        return 'Custom';
    }
  }

  static SmsType fromString(String value) {
    return SmsType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => SmsType.custom,
    );
  }
}

enum SmsStatus {
  pending,
  sent,
  delivered,
  failed;

  String get displayName {
    switch (this) {
      case SmsStatus.pending:
        return 'Pending';
      case SmsStatus.sent:
        return 'Sent';
      case SmsStatus.delivered:
        return 'Delivered';
      case SmsStatus.failed:
        return 'Failed';
    }
  }

  static SmsStatus fromString(String value) {
    return SmsStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => SmsStatus.pending,
    );
  }
}

// ============================================================================
// Entities
// ============================================================================

class SmsLogEntity extends Equatable {
  final String id;
  final String phoneNumber;
  final String? messageBody;
  final SmsType smsType;
  final SmsStatus status;
  final double? cost;
  final String? bulksmsMessageId;
  final String? errorMessage;
  final String? createdById;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  const SmsLogEntity({
    required this.id,
    required this.phoneNumber,
    this.messageBody,
    required this.smsType,
    required this.status,
    this.cost,
    this.bulksmsMessageId,
    this.errorMessage,
    this.createdById,
    this.metadata,
    required this.createdAt,
    this.deliveredAt,
  });

  String get maskedPhoneNumber {
    if (phoneNumber.length <= 4) return phoneNumber;
    final visible = phoneNumber.substring(phoneNumber.length - 4);
    final masked = '*' * (phoneNumber.length - 4);
    return '$masked$visible';
  }

  String get messagePreview {
    if (messageBody == null || messageBody!.isEmpty) return 'No message body';
    if (messageBody!.length <= 60) return messageBody!;
    return '${messageBody!.substring(0, 60)}...';
  }

  factory SmsLogEntity.fromJson(Map<String, dynamic> json) {
    return SmsLogEntity(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String? ?? '',
      messageBody: json['message_body'] as String?,
      smsType: SmsType.fromString(json['sms_type'] as String? ?? 'custom'),
      status: SmsStatus.fromString(json['status'] as String? ?? 'pending'),
      cost: (json['cost'] as num?)?.toDouble(),
      bulksmsMessageId: json['bulksms_message_id'] as String?,
      errorMessage: json['error_message'] as String?,
      createdById: json['created_by_id'] as String?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        phoneNumber,
        messageBody,
        smsType,
        status,
        cost,
        bulksmsMessageId,
        errorMessage,
        createdById,
        metadata,
        createdAt,
        deliveredAt,
      ];
}

class SmsUsageStats extends Equatable {
  final int totalSent;
  final int totalDelivered;
  final int totalFailed;
  final double totalCost;
  final double deliveryRate;
  final Map<String, int> byType;
  final Map<String, double> costByType;

  const SmsUsageStats({
    this.totalSent = 0,
    this.totalDelivered = 0,
    this.totalFailed = 0,
    this.totalCost = 0.0,
    this.deliveryRate = 0.0,
    this.byType = const {},
    this.costByType = const {},
  });

  @override
  List<Object?> get props => [
        totalSent,
        totalDelivered,
        totalFailed,
        totalCost,
        deliveryRate,
        byType,
        costByType,
      ];
}

class DailyUsage extends Equatable {
  final DateTime date;
  final int count;
  final int delivered;
  final int failed;
  final double cost;

  const DailyUsage({
    required this.date,
    this.count = 0,
    this.delivered = 0,
    this.failed = 0,
    this.cost = 0.0,
  });

  @override
  List<Object?> get props => [date, count, delivered, failed, cost];
}

class SmsLogFilters extends Equatable {
  final SmsType? type;
  final SmsStatus? status;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? searchQuery;

  const SmsLogFilters({
    this.type,
    this.status,
    this.dateFrom,
    this.dateTo,
    this.searchQuery,
  });

  bool get hasActiveFilters {
    return type != null ||
        status != null ||
        dateFrom != null ||
        dateTo != null ||
        (searchQuery != null && searchQuery!.isNotEmpty);
  }

  SmsLogFilters copyWith({
    SmsType? type,
    SmsStatus? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? searchQuery,
    bool clearType = false,
    bool clearStatus = false,
    bool clearDateFrom = false,
    bool clearDateTo = false,
    bool clearSearchQuery = false,
  }) {
    return SmsLogFilters(
      type: clearType ? null : (type ?? this.type),
      status: clearStatus ? null : (status ?? this.status),
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      searchQuery:
          clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
    );
  }

  @override
  List<Object?> get props => [type, status, dateFrom, dateTo, searchQuery];
}

class SmsLogsPagination extends Equatable {
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;

  const SmsLogsPagination({
    this.page = 1,
    this.pageSize = 50,
    this.totalCount = 0,
    this.hasMore = false,
  });

  int get offset => (page - 1) * pageSize;

  SmsLogsPagination copyWith({
    int? page,
    int? pageSize,
    int? totalCount,
    bool? hasMore,
  }) {
    return SmsLogsPagination(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [page, pageSize, totalCount, hasMore];
}

// ============================================================================
// Result typedefs
// ============================================================================

typedef SmsUsageResult = ({
  List<SmsLogEntity> logs,
  SmsLogsPagination pagination,
  String? error,
});

typedef SmsStatsResult = ({
  SmsUsageStats? stats,
  String? error,
});

typedef DailyUsageResult = ({
  List<DailyUsage> dailyUsage,
  String? error,
});

// ============================================================================
// Repository interface
// ============================================================================

abstract class SmsUsageRepository {
  Future<SmsUsageResult> fetchSmsLogs({
    SmsLogFilters? filters,
    SmsLogsPagination? pagination,
  });

  Future<SmsStatsResult> getSmsStats({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<DailyUsageResult> getDailyUsage({
    DateTime? startDate,
    DateTime? endDate,
  });
}
