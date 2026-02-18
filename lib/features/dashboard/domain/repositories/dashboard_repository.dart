// lib/features/dashboard/domain/repositories/dashboard_repository.dart

import '../entities/dashboard_stats.dart';

/// Abstract repository for dashboard statistics
abstract class DashboardRepository {
  /// Fetch all dashboard statistics including trends
  Future<DashboardStats> fetchDashboardStats();

  /// Fetch today's basic stats only (for quick refresh)
  Future<DashboardStats> fetchTodayStats();

  /// Fetch weekly aggregated statistics
  /// Returns data for the last 7 days
  Future<WeeklyStats> fetchWeeklyStats();

  /// Fetch trend data comparing current period to previous period
  /// Returns TrendIndicator with percentage change and sparkline data
  Future<Map<String, TrendIndicator>> fetchTrends();

  /// Fetch active shipments count
  /// Shipments with status: 'Bidding', 'Pickup', 'OnRoute'
  Future<int> fetchActiveShipmentsCount();

  /// Fetch pending driver approvals count
  /// Drivers with is_verified = false
  Future<int> fetchPendingDriverApprovalsCount();

  /// Fetch new registrations count for today
  /// Users created today (both drivers and shippers)
  Future<int> fetchNewRegistrationsTodayCount();

  /// Fetch active users in last 24 hours
  /// Users with last_seen within 24 hours
  Future<int> fetchActiveUsers24hCount();

  /// Fetch today's revenue
  /// Sum of completed payments today
  Future<double> fetchRevenueTodayAmount();

  /// Fetch pending disputes count
  /// Disputes with status = 'open' or 'under_review'
  Future<int> fetchPendingDisputesCount();

  /// Fetch 7-day sparkline data for a specific metric
  /// Returns list of daily values for the past 7 days
  Future<List<TrendDataPoint>> fetchSparklineData(String metricType);

  /// Fetch completed shipments count for a date range
  Future<int> fetchCompletedShipmentsCount({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Fetch total revenue for a date range
  Future<double> fetchTotalRevenue({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Fetch average delivery time in hours for completed shipments
  Future<double> fetchAverageDeliveryTime({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Fetch driver utilization rate (% of verified drivers with active shipments)
  Future<double> fetchDriverUtilizationRate();

  /// Fetch revenue sparkline data for a date range, grouped into equal buckets
  Future<List<TrendDataPoint>> fetchRevenueSparkline({
    required DateTime startDate,
    required DateTime endDate,
    required int buckets,
  });

  /// Fetch count of freight posts created in a date range
  Future<int> fetchShipmentsInRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Fetch count of user registrations in a date range
  Future<int> fetchRegistrationsInRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Fetch count of users active (last_login_at) in a date range
  Future<int> fetchActiveUsersInRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Fetch count-based sparkline for a metric over a date range
  Future<List<TrendDataPoint>> fetchCountSparkline({
    required String metricType,
    required DateTime startDate,
    required DateTime endDate,
    required int buckets,
  });
}
