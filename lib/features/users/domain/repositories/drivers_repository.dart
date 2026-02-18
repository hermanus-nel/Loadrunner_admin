// lib/features/users/domain/repositories/drivers_repository.dart

import '../entities/driver_entity.dart';

/// Filter options for driver queries
class DriverFilter {
  final DriverVerificationStatus? status;
  final String? searchQuery;
  final int limit;
  final int offset;

  const DriverFilter({
    this.status,
    this.searchQuery,
    this.limit = 20,
    this.offset = 0,
  });

  DriverFilter copyWith({
    DriverVerificationStatus? status,
    String? searchQuery,
    int? limit,
    int? offset,
  }) {
    return DriverFilter(
      status: status ?? this.status,
      searchQuery: searchQuery ?? this.searchQuery,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  /// Check if any filter is applied
  bool get hasFilters => status != null || (searchQuery != null && searchQuery!.isNotEmpty);

  @override
  String toString() {
    return 'DriverFilter(status: $status, search: $searchQuery, limit: $limit, offset: $offset)';
  }
}

/// Result of paginated driver fetch
class DriversResult {
  final List<DriverEntity> drivers;
  final bool hasMore;
  final int totalCount;

  const DriversResult({
    required this.drivers,
    required this.hasMore,
    required this.totalCount,
  });

  factory DriversResult.empty() {
    return const DriversResult(
      drivers: [],
      hasMore: false,
      totalCount: 0,
    );
  }
}

/// Abstract repository for driver operations
abstract class DriversRepository {
  /// Fetch drivers with optional filters and pagination
  Future<DriversResult> fetchDrivers(DriverFilter filter);

  /// Fetch driver counts by status
  Future<DriverStatusCounts> fetchDriverCounts();

  /// Fetch a single driver by ID
  Future<DriverEntity?> fetchDriverById(String driverId);

  /// Search drivers by name, phone, or email
  Future<List<DriverEntity>> searchDrivers(String query, {int limit = 20});

  /// Approve a driver
  Future<bool> approveDriver(String driverId, String adminId);

  /// Reject a driver with reason
  Future<bool> rejectDriver(String driverId, String adminId, String reason);

  /// Request additional documents from driver
  Future<bool> requestDocuments(
    String driverId,
    String adminId,
    List<String> documentTypes,
    String? message,
  );
}
