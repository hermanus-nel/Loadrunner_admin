// test/helpers/mock_drivers_repository.dart

import '../../lib/features/users/domain/entities/driver_entity.dart';
import '../../lib/features/users/domain/repositories/drivers_repository.dart';

/// Mock DriversRepository for testing driver approval flows
class MockDriversRepository implements DriversRepository {
  final List<DriverEntity> _drivers = [];
  bool shouldFail = false;

  // Pre-populate with test data
  void seedDrivers(List<DriverEntity> drivers) {
    _drivers
      ..clear()
      ..addAll(drivers);
  }

  @override
  Future<DriversResult> fetchDrivers(DriverFilter filter) async {
    if (shouldFail) throw Exception('Mock fetch failed');

    var filtered = List<DriverEntity>.from(_drivers);

    if (filter.status != null) {
      filtered = filtered
          .where((d) => d.verificationStatus == filter.status)
          .toList();
    }
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      final q = filter.searchQuery!.toLowerCase();
      filtered = filtered
          .where((d) =>
              d.fullName.toLowerCase().contains(q) ||
              (d.phoneNumber ?? '').toLowerCase().contains(q))
          .toList();
    }

    final totalCount = filtered.length;
    final paged = filtered.skip(filter.offset).take(filter.limit).toList();

    return DriversResult(
      drivers: paged,
      hasMore: filter.offset + paged.length < totalCount,
      totalCount: totalCount,
    );
  }

  @override
  Future<DriverStatusCounts> fetchDriverCounts() async {
    if (shouldFail) throw Exception('Mock count failed');

    int pending = 0, approved = 0, rejected = 0;
    for (final d in _drivers) {
      switch (d.verificationStatus) {
        case DriverVerificationStatus.pending:
          pending++;
          break;
        case DriverVerificationStatus.approved:
          approved++;
          break;
        case DriverVerificationStatus.rejected:
          rejected++;
          break;
      }
    }
    return DriverStatusCounts(
      total: _drivers.length,
      pending: pending,
      approved: approved,
      rejected: rejected,
    );
  }

  @override
  Future<DriverEntity?> fetchDriverById(String driverId) async {
    if (shouldFail) throw Exception('Mock fetch by id failed');
    try {
      return _drivers.firstWhere((d) => d.id == driverId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<DriverEntity>> searchDrivers(String query, {int limit = 20}) async {
    if (shouldFail) throw Exception('Mock search failed');
    final q = query.toLowerCase();
    return _drivers
        .where((d) =>
            d.fullName.toLowerCase().contains(q) ||
            (d.phoneNumber ?? '').toLowerCase().contains(q))
        .take(limit)
        .toList();
  }

  @override
  Future<bool> approveDriver(String driverId, String adminId) async {
    if (shouldFail) return false;
    final index = _drivers.indexWhere((d) => d.id == driverId);
    if (index == -1) return false;
    _drivers[index] = _drivers[index].copyWith(
      verificationStatus: DriverVerificationStatus.approved,
    );
    return true;
  }

  @override
  Future<bool> rejectDriver(String driverId, String adminId, String reason) async {
    if (shouldFail) return false;
    final index = _drivers.indexWhere((d) => d.id == driverId);
    if (index == -1) return false;
    _drivers[index] = _drivers[index].copyWith(
      verificationStatus: DriverVerificationStatus.rejected,
    );
    return true;
  }

  @override
  Future<bool> requestDocuments(
    String driverId,
    String adminId,
    List<String> documentTypes,
    String? message,
  ) async {
    if (shouldFail) return false;
    return true;
  }
}
