// lib/features/shippers/domain/entities/shipper_entity.dart

import 'package:equatable/equatable.dart';

/// Shipper entity representing a user with role = 'Shipper'
class ShipperEntity extends Equatable {
  final String id;
  final String phoneNumber;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? profilePhotoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  
  // Suspension info
  final bool isSuspended;
  final DateTime? suspendedAt;
  final String? suspendedReason;
  final String? suspendedBy;
  final DateTime? suspensionEndsAt;
  
  // Address info
  final String? addressName;
  
  // Statistics (computed from related tables)
  final ShipperStats? stats;

  const ShipperEntity({
    required this.id,
    required this.phoneNumber,
    this.firstName,
    this.lastName,
    this.email,
    this.profilePhotoUrl,
    required this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.isSuspended = false,
    this.suspendedAt,
    this.suspendedReason,
    this.suspendedBy,
    this.suspensionEndsAt,
    this.addressName,
    this.stats,
  });

  /// Full name combining first and last name
  String get fullName {
    final parts = [firstName, lastName].where((s) => s != null && s.isNotEmpty);
    return parts.isNotEmpty ? parts.join(' ') : 'Unknown';
  }

  /// Display name (full name or phone)
  String get displayName {
    final name = fullName;
    return name != 'Unknown' ? name : phoneNumber;
  }

  /// Initials for avatar
  String get initials {
    if (firstName != null && firstName!.isNotEmpty) {
      if (lastName != null && lastName!.isNotEmpty) {
        return '${firstName![0]}${lastName![0]}'.toUpperCase();
      }
      return firstName![0].toUpperCase();
    }
    return 'S';
  }

  /// Check if shipper is currently suspended
  bool get isCurrentlySuspended {
    if (!isSuspended) return false;
    if (suspensionEndsAt == null) return true; // Permanent suspension
    return DateTime.now().isBefore(suspensionEndsAt!);
  }

  /// Status string for display
  String get statusString {
    if (isCurrentlySuspended) return 'Suspended';
    return 'Active';
  }

  /// Check if shipper was active recently (within last 7 days)
  bool get isRecentlyActive {
    if (lastLoginAt == null) return false;
    return DateTime.now().difference(lastLoginAt!).inDays <= 7;
  }

  /// Days since registration
  int get daysSinceRegistration {
    return DateTime.now().difference(createdAt).inDays;
  }

  /// Copy with method for updating fields
  ShipperEntity copyWith({
    String? id,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? email,
    String? profilePhotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    bool? isSuspended,
    DateTime? suspendedAt,
    String? suspendedReason,
    String? suspendedBy,
    DateTime? suspensionEndsAt,
    String? addressName,
    ShipperStats? stats,
  }) {
    return ShipperEntity(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isSuspended: isSuspended ?? this.isSuspended,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      suspendedReason: suspendedReason ?? this.suspendedReason,
      suspendedBy: suspendedBy ?? this.suspendedBy,
      suspensionEndsAt: suspensionEndsAt ?? this.suspensionEndsAt,
      addressName: addressName ?? this.addressName,
      stats: stats ?? this.stats,
    );
  }

  factory ShipperEntity.fromJson(Map<String, dynamic> json) {
    return ShipperEntity(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      isSuspended: json['is_suspended'] as bool? ?? false,
      suspendedAt: json['suspended_at'] != null
          ? DateTime.parse(json['suspended_at'] as String)
          : null,
      suspendedReason: json['suspended_reason'] as String?,
      suspendedBy: json['suspended_by'] as String?,
      suspensionEndsAt: json['suspension_ends_at'] != null
          ? DateTime.parse(json['suspension_ends_at'] as String)
          : null,
      addressName: json['address_name'] as String?,
      stats: json['stats'] != null
          ? ShipperStats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'profile_photo_url': profilePhotoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'is_suspended': isSuspended,
      'suspended_at': suspendedAt?.toIso8601String(),
      'suspended_reason': suspendedReason,
      'suspended_by': suspendedBy,
      'suspension_ends_at': suspensionEndsAt?.toIso8601String(),
      'address_name': addressName,
      'stats': stats?.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        phoneNumber,
        firstName,
        lastName,
        email,
        profilePhotoUrl,
        createdAt,
        updatedAt,
        lastLoginAt,
        isSuspended,
        suspendedAt,
        suspendedReason,
        suspendedBy,
        suspensionEndsAt,
        addressName,
        stats,
      ];
}

/// Statistics for a shipper
class ShipperStats extends Equatable {
  final int totalShipments;
  final int activeShipments;
  final int completedShipments;
  final int cancelledShipments;
  final double totalSpent;
  final double averageRating;
  final int ratingsCount;
  final int disputesCount;
  final int openDisputesCount;

  const ShipperStats({
    this.totalShipments = 0,
    this.activeShipments = 0,
    this.completedShipments = 0,
    this.cancelledShipments = 0,
    this.totalSpent = 0.0,
    this.averageRating = 0.0,
    this.ratingsCount = 0,
    this.disputesCount = 0,
    this.openDisputesCount = 0,
  });

  /// Completion rate percentage
  double get completionRate {
    if (totalShipments == 0) return 0.0;
    return (completedShipments / totalShipments) * 100;
  }

  /// Cancellation rate percentage
  double get cancellationRate {
    if (totalShipments == 0) return 0.0;
    return (cancelledShipments / totalShipments) * 100;
  }

  factory ShipperStats.fromJson(Map<String, dynamic> json) {
    return ShipperStats(
      totalShipments: json['total_shipments'] as int? ?? 0,
      activeShipments: json['active_shipments'] as int? ?? 0,
      completedShipments: json['completed_shipments'] as int? ?? 0,
      cancelledShipments: json['cancelled_shipments'] as int? ?? 0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      ratingsCount: json['ratings_count'] as int? ?? 0,
      disputesCount: json['disputes_count'] as int? ?? 0,
      openDisputesCount: json['open_disputes_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_shipments': totalShipments,
      'active_shipments': activeShipments,
      'completed_shipments': completedShipments,
      'cancelled_shipments': cancelledShipments,
      'total_spent': totalSpent,
      'average_rating': averageRating,
      'ratings_count': ratingsCount,
      'disputes_count': disputesCount,
      'open_disputes_count': openDisputesCount,
    };
  }

  @override
  List<Object?> get props => [
        totalShipments,
        activeShipments,
        completedShipments,
        cancelledShipments,
        totalSpent,
        averageRating,
        ratingsCount,
        disputesCount,
        openDisputesCount,
      ];
}

/// Filter options for shipper list
class ShipperFilters extends Equatable {
  final ShipperStatus? status;
  final DateTime? registeredAfter;
  final DateTime? registeredBefore;
  final DateTime? lastActiveAfter;
  final String? searchQuery;
  final ShipperSortBy sortBy;
  final bool sortAscending;

  const ShipperFilters({
    this.status,
    this.registeredAfter,
    this.registeredBefore,
    this.lastActiveAfter,
    this.searchQuery,
    this.sortBy = ShipperSortBy.createdAt,
    this.sortAscending = false,
  });

  bool get hasActiveFilters {
    return status != null ||
        registeredAfter != null ||
        registeredBefore != null ||
        lastActiveAfter != null ||
        (searchQuery != null && searchQuery!.isNotEmpty);
  }

  ShipperFilters copyWith({
    ShipperStatus? status,
    DateTime? registeredAfter,
    DateTime? registeredBefore,
    DateTime? lastActiveAfter,
    String? searchQuery,
    ShipperSortBy? sortBy,
    bool? sortAscending,
    bool clearStatus = false,
    bool clearRegisteredAfter = false,
    bool clearRegisteredBefore = false,
    bool clearLastActiveAfter = false,
    bool clearSearchQuery = false,
  }) {
    return ShipperFilters(
      status: clearStatus ? null : (status ?? this.status),
      registeredAfter: clearRegisteredAfter ? null : (registeredAfter ?? this.registeredAfter),
      registeredBefore: clearRegisteredBefore ? null : (registeredBefore ?? this.registeredBefore),
      lastActiveAfter: clearLastActiveAfter ? null : (lastActiveAfter ?? this.lastActiveAfter),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  @override
  List<Object?> get props => [
        status,
        registeredAfter,
        registeredBefore,
        lastActiveAfter,
        searchQuery,
        sortBy,
        sortAscending,
      ];
}

/// Status filter for shippers
enum ShipperStatus {
  active,
  suspended,
  inactive, // No login in 30+ days
}

extension ShipperStatusExtension on ShipperStatus {
  String get displayName {
    switch (this) {
      case ShipperStatus.active:
        return 'Active';
      case ShipperStatus.suspended:
        return 'Suspended';
      case ShipperStatus.inactive:
        return 'Inactive';
    }
  }
}

/// Sort options for shipper list
enum ShipperSortBy {
  createdAt,
  lastLoginAt,
  name,
  totalShipments,
  totalSpent,
}

extension ShipperSortByExtension on ShipperSortBy {
  String get displayName {
    switch (this) {
      case ShipperSortBy.createdAt:
        return 'Registration Date';
      case ShipperSortBy.lastLoginAt:
        return 'Last Active';
      case ShipperSortBy.name:
        return 'Name';
      case ShipperSortBy.totalShipments:
        return 'Total Shipments';
      case ShipperSortBy.totalSpent:
        return 'Total Spent';
    }
  }

  String get columnName {
    switch (this) {
      case ShipperSortBy.createdAt:
        return 'created_at';
      case ShipperSortBy.lastLoginAt:
        return 'last_login_at';
      case ShipperSortBy.name:
        return 'first_name';
      case ShipperSortBy.totalShipments:
        return 'created_at'; // Will sort in code for computed fields
      case ShipperSortBy.totalSpent:
        return 'created_at'; // Will sort in code for computed fields
    }
  }
}

/// Pagination info for shipper list
class ShippersPagination extends Equatable {
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;

  const ShippersPagination({
    this.page = 1,
    this.pageSize = 20,
    this.totalCount = 0,
    this.hasMore = false,
  });

  int get offset => (page - 1) * pageSize;

  int get totalPages => (totalCount / pageSize).ceil();

  ShippersPagination copyWith({
    int? page,
    int? pageSize,
    int? totalCount,
    bool? hasMore,
  }) {
    return ShippersPagination(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [page, pageSize, totalCount, hasMore];
}

/// Overall shipper statistics for admin dashboard
class ShippersOverviewStats extends Equatable {
  final int totalShippers;
  final int activeShippers;
  final int suspendedShippers;
  final int newThisMonth;
  final int newThisWeek;
  final double totalRevenue;

  const ShippersOverviewStats({
    this.totalShippers = 0,
    this.activeShippers = 0,
    this.suspendedShippers = 0,
    this.newThisMonth = 0,
    this.newThisWeek = 0,
    this.totalRevenue = 0.0,
  });

  factory ShippersOverviewStats.fromJson(Map<String, dynamic> json) {
    return ShippersOverviewStats(
      totalShippers: json['total_shippers'] as int? ?? 0,
      activeShippers: json['active_shippers'] as int? ?? 0,
      suspendedShippers: json['suspended_shippers'] as int? ?? 0,
      newThisMonth: json['new_this_month'] as int? ?? 0,
      newThisWeek: json['new_this_week'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
        totalShippers,
        activeShippers,
        suspendedShippers,
        newThisMonth,
        newThisWeek,
        totalRevenue,
      ];
}

/// Recent shipment for shipper profile
class ShipperRecentShipment extends Equatable {
  final String id;
  final String pickupLocation;
  final String deliveryLocation;
  final String status;
  final double? amount;
  final DateTime createdAt;

  const ShipperRecentShipment({
    required this.id,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.status,
    this.amount,
    required this.createdAt,
  });

  factory ShipperRecentShipment.fromJson(Map<String, dynamic> json) {
    return ShipperRecentShipment(
      id: json['id'] as String,
      pickupLocation: json['pickup_location_name'] as String? ?? 'Unknown',
      deliveryLocation: json['dropoff_location_name'] as String? ?? 'Unknown',
      status: json['status'] as String? ?? 'Unknown',
      amount: (json['amount'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, pickupLocation, deliveryLocation, status, amount, createdAt];
}
