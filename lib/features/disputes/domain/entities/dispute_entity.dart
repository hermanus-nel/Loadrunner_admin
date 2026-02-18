// lib/features/disputes/domain/entities/dispute_entity.dart

import 'package:flutter/foundation.dart';

/// Dispute type enum matching database dispute_type
enum DisputeType {
  damage,
  nonDelivery,
  payment,
  wrongItem,
  lateDelivery,
  overcharge,
  other;

  static DisputeType fromString(String value) {
    switch (value.toLowerCase().replaceAll('_', '')) {
      case 'damage':
        return DisputeType.damage;
      case 'nondelivery':
      case 'non_delivery':
        return DisputeType.nonDelivery;
      case 'payment':
        return DisputeType.payment;
      case 'wrongitem':
      case 'wrong_item':
        return DisputeType.wrongItem;
      case 'latedelivery':
      case 'late_delivery':
        return DisputeType.lateDelivery;
      case 'overcharge':
        return DisputeType.overcharge;
      default:
        return DisputeType.other;
    }
  }

  String get displayName {
    switch (this) {
      case DisputeType.damage:
        return 'Damage';
      case DisputeType.nonDelivery:
        return 'Non-Delivery';
      case DisputeType.payment:
        return 'Payment';
      case DisputeType.wrongItem:
        return 'Wrong Item';
      case DisputeType.lateDelivery:
        return 'Late Delivery';
      case DisputeType.overcharge:
        return 'Overcharge';
      case DisputeType.other:
        return 'Other';
    }
  }

  String toJson() {
    switch (this) {
      case DisputeType.damage:
        return 'damage';
      case DisputeType.nonDelivery:
        return 'non_delivery';
      case DisputeType.payment:
        return 'payment';
      case DisputeType.wrongItem:
        return 'wrong_item';
      case DisputeType.lateDelivery:
        return 'late_delivery';
      case DisputeType.overcharge:
        return 'overcharge';
      case DisputeType.other:
        return 'other';
    }
  }
}

/// Dispute priority enum matching database dispute_priority
enum DisputePriority {
  low,
  medium,
  high,
  urgent;

  static DisputePriority fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return DisputePriority.low;
      case 'medium':
        return DisputePriority.medium;
      case 'high':
        return DisputePriority.high;
      case 'urgent':
        return DisputePriority.urgent;
      default:
        return DisputePriority.medium;
    }
  }

  String get displayName {
    switch (this) {
      case DisputePriority.low:
        return 'Low';
      case DisputePriority.medium:
        return 'Medium';
      case DisputePriority.high:
        return 'High';
      case DisputePriority.urgent:
        return 'Urgent';
    }
  }

  String toJson() => name;

  int get sortOrder {
    switch (this) {
      case DisputePriority.urgent:
        return 0;
      case DisputePriority.high:
        return 1;
      case DisputePriority.medium:
        return 2;
      case DisputePriority.low:
        return 3;
    }
  }
}

/// Dispute status enum matching database dispute_status
enum DisputeStatus {
  open,
  investigating,
  awaitingEvidence,
  resolved,
  escalated,
  closed;

  static DisputeStatus fromString(String value) {
    switch (value.toLowerCase().replaceAll('_', '')) {
      case 'open':
        return DisputeStatus.open;
      case 'investigating':
      case 'underreview':
      case 'under_review':
        return DisputeStatus.investigating;
      case 'awaitingevidence':
      case 'awaiting_evidence':
        return DisputeStatus.awaitingEvidence;
      case 'resolved':
        return DisputeStatus.resolved;
      case 'escalated':
        return DisputeStatus.escalated;
      case 'closed':
        return DisputeStatus.closed;
      default:
        return DisputeStatus.open;
    }
  }

  String get displayName {
    switch (this) {
      case DisputeStatus.open:
        return 'Open';
      case DisputeStatus.investigating:
        return 'Investigating';
      case DisputeStatus.awaitingEvidence:
        return 'Awaiting Evidence';
      case DisputeStatus.resolved:
        return 'Resolved';
      case DisputeStatus.escalated:
        return 'Escalated';
      case DisputeStatus.closed:
        return 'Closed';
    }
  }

  String toJson() {
    switch (this) {
      case DisputeStatus.open:
        return 'open';
      case DisputeStatus.investigating:
        return 'investigating';
      case DisputeStatus.awaitingEvidence:
        return 'awaiting_evidence';
      case DisputeStatus.resolved:
        return 'resolved';
      case DisputeStatus.escalated:
        return 'escalated';
      case DisputeStatus.closed:
        return 'closed';
    }
  }

  bool get isActive =>
      this == DisputeStatus.open ||
      this == DisputeStatus.investigating ||
      this == DisputeStatus.awaitingEvidence ||
      this == DisputeStatus.escalated;
}

/// Resolution type for dispute outcomes
enum ResolutionType {
  favorShipper,
  favorDriver,
  splitDecision,
  mediated,
  noAction,
  escalated;

  static ResolutionType fromString(String value) {
    switch (value.toLowerCase().replaceAll('_', '')) {
      case 'favorshipper':
      case 'favor_shipper':
        return ResolutionType.favorShipper;
      case 'favordriver':
      case 'favor_driver':
        return ResolutionType.favorDriver;
      case 'splitdecision':
      case 'split_decision':
        return ResolutionType.splitDecision;
      case 'mediated':
        return ResolutionType.mediated;
      case 'noaction':
      case 'no_action':
        return ResolutionType.noAction;
      case 'escalated':
        return ResolutionType.escalated;
      default:
        return ResolutionType.noAction;
    }
  }

  String get displayName {
    switch (this) {
      case ResolutionType.favorShipper:
        return 'Rule in favor of Shipper';
      case ResolutionType.favorDriver:
        return 'Rule in favor of Driver';
      case ResolutionType.splitDecision:
        return 'Split Decision';
      case ResolutionType.mediated:
        return 'Mediated Resolution';
      case ResolutionType.noAction:
        return 'No Action Required';
      case ResolutionType.escalated:
        return 'Escalated to Senior Admin';
    }
  }

  String toJson() {
    switch (this) {
      case ResolutionType.favorShipper:
        return 'favor_shipper';
      case ResolutionType.favorDriver:
        return 'favor_driver';
      case ResolutionType.splitDecision:
        return 'split_decision';
      case ResolutionType.mediated:
        return 'mediated';
      case ResolutionType.noAction:
        return 'no_action';
      case ResolutionType.escalated:
        return 'escalated';
    }
  }
}

/// User info for dispute parties
@immutable
class DisputeUserInfo {
  final String id;
  final String? fullName;
  final String? phone;
  final String? email;
  final String? role;
  final String? profilePhotoUrl;

  const DisputeUserInfo({
    required this.id,
    this.fullName,
    this.phone,
    this.email,
    this.role,
    this.profilePhotoUrl,
  });

  String get displayName => fullName ?? phone ?? 'Unknown User';

  String get initials {
    if (fullName != null && fullName!.isNotEmpty) {
      final parts = fullName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return fullName![0].toUpperCase();
    }
    return '?';
  }

  factory DisputeUserInfo.fromJson(Map<String, dynamic> json) {
    final firstName = json['first_name'] as String?;
    final lastName = json['last_name'] as String?;
    String? fullName;
    if (firstName != null || lastName != null) {
      fullName = [firstName, lastName].where((s) => s != null).join(' ').trim();
      if (fullName.isEmpty) fullName = null;
    }

    return DisputeUserInfo(
      id: json['id'] as String,
      fullName: fullName,
      phone: json['phone_number'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
    );
  }
}

/// Shipment info related to dispute
@immutable
class DisputeShipmentInfo {
  final String id;
  final String? pickupLocation;
  final String? deliveryLocation;
  final String? status;
  final DateTime? createdAt;
  final double? bidAmount;

  const DisputeShipmentInfo({
    required this.id,
    this.pickupLocation,
    this.deliveryLocation,
    this.status,
    this.createdAt,
    this.bidAmount,
  });

  factory DisputeShipmentInfo.fromJson(Map<String, dynamic> json) {
    return DisputeShipmentInfo(
      id: json['id'] as String,
      pickupLocation: json['pickup_location'] as String?,
      deliveryLocation: json['delivery_location'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      bidAmount: (json['bid_amount'] as num?)?.toDouble(),
    );
  }
}

/// Main Dispute Entity
@immutable
class DisputeEntity {
  final String id;
  final String freightPostId;
  final String raisedById;
  final String raisedAgainstId;
  final DisputeType disputeType;
  final DisputePriority priority;
  final DisputeStatus status;
  final String title;
  final String description;
  final String? adminAssignedId;
  final String? resolution;
  final String? resolvedById;
  final DateTime? resolvedAt;
  final double? refundAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related entities (populated when fetching details)
  final DisputeUserInfo? raisedBy;
  final DisputeUserInfo? raisedAgainst;
  final DisputeUserInfo? adminAssigned;
  final DisputeUserInfo? resolvedBy;
  final DisputeShipmentInfo? shipment;
  final int? evidenceCount;

  const DisputeEntity({
    required this.id,
    required this.freightPostId,
    required this.raisedById,
    required this.raisedAgainstId,
    required this.disputeType,
    required this.priority,
    required this.status,
    required this.title,
    required this.description,
    this.adminAssignedId,
    this.resolution,
    this.resolvedById,
    this.resolvedAt,
    this.refundAmount,
    required this.createdAt,
    required this.updatedAt,
    this.raisedBy,
    this.raisedAgainst,
    this.adminAssigned,
    this.resolvedBy,
    this.shipment,
    this.evidenceCount,
  });

  /// Check if dispute is still open/active
  bool get isActive => status.isActive;

  /// Check if dispute is resolved
  bool get isResolved =>
      status == DisputeStatus.resolved || status == DisputeStatus.closed;

  /// Check if dispute is urgent
  bool get isUrgent => priority == DisputePriority.urgent;

  /// Check if dispute has refund
  bool get hasRefund => refundAmount != null && refundAmount! > 0;

  /// Get age of dispute in days
  int get ageInDays => DateTime.now().difference(createdAt).inDays;

  /// Get resolution time in days (if resolved)
  int? get resolutionTimeInDays {
    if (resolvedAt == null) return null;
    return resolvedAt!.difference(createdAt).inDays;
  }

  /// Copy with method for immutability
  DisputeEntity copyWith({
    String? id,
    String? freightPostId,
    String? raisedById,
    String? raisedAgainstId,
    DisputeType? disputeType,
    DisputePriority? priority,
    DisputeStatus? status,
    String? title,
    String? description,
    String? adminAssignedId,
    String? resolution,
    String? resolvedById,
    DateTime? resolvedAt,
    double? refundAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DisputeUserInfo? raisedBy,
    DisputeUserInfo? raisedAgainst,
    DisputeUserInfo? adminAssigned,
    DisputeUserInfo? resolvedBy,
    DisputeShipmentInfo? shipment,
    int? evidenceCount,
  }) {
    return DisputeEntity(
      id: id ?? this.id,
      freightPostId: freightPostId ?? this.freightPostId,
      raisedById: raisedById ?? this.raisedById,
      raisedAgainstId: raisedAgainstId ?? this.raisedAgainstId,
      disputeType: disputeType ?? this.disputeType,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      adminAssignedId: adminAssignedId ?? this.adminAssignedId,
      resolution: resolution ?? this.resolution,
      resolvedById: resolvedById ?? this.resolvedById,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      refundAmount: refundAmount ?? this.refundAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      raisedBy: raisedBy ?? this.raisedBy,
      raisedAgainst: raisedAgainst ?? this.raisedAgainst,
      adminAssigned: adminAssigned ?? this.adminAssigned,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      shipment: shipment ?? this.shipment,
      evidenceCount: evidenceCount ?? this.evidenceCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DisputeEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Filter options for fetching disputes
@immutable
class DisputeFilters {
  final DisputeStatus? status;
  final DisputeType? type;
  final DisputePriority? priority;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;
  final bool? assignedToMe;

  const DisputeFilters({
    this.status,
    this.type,
    this.priority,
    this.startDate,
    this.endDate,
    this.searchQuery,
    this.assignedToMe,
  });

  DisputeFilters copyWith({
    DisputeStatus? status,
    DisputeType? type,
    DisputePriority? priority,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    bool? assignedToMe,
    bool clearStatus = false,
    bool clearType = false,
    bool clearPriority = false,
    bool clearDates = false,
    bool clearSearch = false,
  }) {
    return DisputeFilters(
      status: clearStatus ? null : (status ?? this.status),
      type: clearType ? null : (type ?? this.type),
      priority: clearPriority ? null : (priority ?? this.priority),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      assignedToMe: assignedToMe ?? this.assignedToMe,
    );
  }

  bool get hasActiveFilters =>
      status != null ||
      type != null ||
      priority != null ||
      startDate != null ||
      endDate != null ||
      (searchQuery != null && searchQuery!.isNotEmpty) ||
      assignedToMe == true;
}

/// Pagination info for disputes list
@immutable
class DisputesPagination {
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;

  const DisputesPagination({
    this.page = 1,
    this.pageSize = 20,
    this.totalCount = 0,
    this.hasMore = false,
  });

  DisputesPagination copyWith({
    int? page,
    int? pageSize,
    int? totalCount,
    bool? hasMore,
  }) {
    return DisputesPagination(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Statistics for disputes
@immutable
class DisputeStats {
  final int totalDisputes;
  final int openDisputes;
  final int investigatingDisputes;
  final int resolvedDisputes;
  final int escalatedDisputes;
  final int urgentDisputes;
  final double averageResolutionDays;
  final double resolutionRate;

  const DisputeStats({
    this.totalDisputes = 0,
    this.openDisputes = 0,
    this.investigatingDisputes = 0,
    this.resolvedDisputes = 0,
    this.escalatedDisputes = 0,
    this.urgentDisputes = 0,
    this.averageResolutionDays = 0,
    this.resolutionRate = 0,
  });

  factory DisputeStats.empty() => const DisputeStats();
}
