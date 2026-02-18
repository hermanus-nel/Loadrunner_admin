// lib/features/shippers/domain/repositories/shippers_repository.dart

import '../entities/shipper_entity.dart';

/// Result types for repository operations
typedef ShippersResult = ({
  List<ShipperEntity> shippers,
  ShippersPagination pagination,
  String? error,
});

typedef ShipperDetailResult = ({
  ShipperEntity? shipper,
  List<ShipperRecentShipment> recentShipments,
  String? error,
});

typedef ShipperActionResult = ({
  bool success,
  String? error,
});

typedef ShippersStatsResult = ({
  ShippersOverviewStats? stats,
  String? error,
});

/// Repository interface for shipper management
abstract class ShippersRepository {
  /// Fetch paginated list of shippers with optional filters
  Future<ShippersResult> fetchShippers({
    ShipperFilters? filters,
    ShippersPagination? pagination,
  });

  /// Fetch detailed shipper profile with statistics
  Future<ShipperDetailResult> fetchShipperDetail(String shipperId);

  /// Suspend a shipper account
  /// [reason] - Reason for suspension
  /// [endsAt] - Optional end date for temporary suspension (null = permanent)
  Future<ShipperActionResult> suspendShipper(
    String shipperId, {
    required String reason,
    DateTime? endsAt,
  });

  /// Unsuspend (reactivate) a shipper account
  Future<ShipperActionResult> unsuspendShipper(String shipperId);

  /// Update shipper profile information
  Future<ShipperActionResult> updateShipperProfile(
    String shipperId, {
    String? firstName,
    String? lastName,
    String? email,
  });

  /// Get overview statistics for all shippers
  Future<ShippersStatsResult> getOverviewStats();

  /// Search shippers by name, email, or phone
  Future<ShippersResult> searchShippers(String query);

  /// Get shippers with recent activity (for dashboard)
  Future<ShippersResult> getRecentlyActiveShippers({int limit = 10});

  /// Get shippers registered recently (for dashboard)
  Future<ShippersResult> getNewShippers({int days = 7, int limit = 10});

  /// Get suspended shippers list
  Future<ShippersResult> getSuspendedShippers();
}
