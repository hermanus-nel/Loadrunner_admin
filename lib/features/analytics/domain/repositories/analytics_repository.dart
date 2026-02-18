// lib/features/analytics/domain/repositories/analytics_repository.dart

import '../entities/activity_metrics.dart';
import '../entities/financial_metrics.dart';
import '../entities/performance_metrics.dart';
import '../entities/date_range.dart';

/// Abstract repository for analytics data
abstract class AnalyticsRepository {
  /// Fetch activity metrics for the given date range
  /// Includes: shipments by status, daily shipments, daily active users, user stats
  Future<ActivityMetrics> fetchActivityMetrics(DateRange dateRange);

  /// Fetch financial metrics for the given date range
  /// Includes: revenue summary, payments by status, daily revenue, top earners
  Future<FinancialMetrics> fetchFinancialMetrics(DateRange dateRange);

  /// Fetch performance metrics for the given date range
  /// Includes: ratings distribution, time metrics, driver performance, platform health
  Future<PerformanceMetrics> fetchPerformanceMetrics(DateRange dateRange);

  // ============================================================
  // ACTIVITY METRICS - Individual methods
  // ============================================================

  /// Fetch shipment counts grouped by status
  Future<ShipmentsByStatus> fetchShipmentsByStatus(DateRange dateRange);

  /// Fetch daily shipment counts for charting
  Future<List<DailyShipments>> fetchDailyShipments(DateRange dateRange);

  /// Fetch daily active users for charting
  Future<List<DailyActiveUsers>> fetchDailyActiveUsers(DateRange dateRange);

  /// Fetch user statistics
  Future<UserStats> fetchUserStats();

  /// Fetch bid statistics
  Future<Map<String, dynamic>> fetchBidStats(DateRange dateRange);

  // ============================================================
  // FINANCIAL METRICS - Individual methods
  // ============================================================

  /// Fetch revenue summary
  Future<RevenueSummary> fetchRevenueSummary(DateRange dateRange);

  /// Fetch payments grouped by status
  Future<PaymentsByStatus> fetchPaymentsByStatus(DateRange dateRange);

  /// Fetch daily revenue for charting
  Future<List<DailyRevenue>> fetchDailyRevenue(DateRange dateRange);

  /// Fetch top earning drivers
  Future<List<TopEarner>> fetchTopDrivers({
    required DateRange dateRange,
    int limit = 10,
  });

  /// Fetch top spending shippers
  Future<List<TopEarner>> fetchTopShippers({
    required DateRange dateRange,
    int limit = 10,
  });

  // ============================================================
  // PERFORMANCE METRICS - Individual methods
  // ============================================================

  /// Fetch ratings distribution
  Future<RatingsDistribution> fetchRatingsDistribution(DateRange dateRange);

  /// Fetch time-based performance metrics
  Future<TimeMetrics> fetchTimeMetrics(DateRange dateRange);

  /// Fetch driver performance stats
  Future<DriverPerformance> fetchDriverPerformance();

  /// Fetch platform health metrics
  Future<PlatformHealth> fetchPlatformHealth();

  /// Fetch low-rated drivers needing attention
  Future<List<LowRatedUser>> fetchLowRatedDrivers({double threshold = 3.0});

  /// Fetch low-rated shippers needing attention
  Future<List<LowRatedUser>> fetchLowRatedShippers({double threshold = 3.0});
}
