// lib/features/dashboard/data/models/dashboard_stats_model.dart

import '../../domain/entities/dashboard_stats.dart';

/// Data model for dashboard statistics
/// Handles JSON serialization/deserialization
class DashboardStatsModel extends DashboardStats {
  const DashboardStatsModel({
    required super.activeShipments,
    required super.pendingDriverApprovals,
    required super.newRegistrationsToday,
    required super.activeUsers24h,
    required super.revenueToday,
    required super.pendingDisputes,
    required super.weeklyStats,
    required super.activeShipmentsTrend,
    required super.pendingApprovalsTrend,
    required super.registrationsTrend,
    required super.activeUsersTrend,
    required super.revenueTrend,
    required super.disputesTrend,
    required super.completedShipmentsTrend,
  });

  /// Create from individual query results
  factory DashboardStatsModel.fromQueryResults({
    required int activeShipments,
    required int pendingDriverApprovals,
    required int newRegistrationsToday,
    required int activeUsers24h,
    required double revenueToday,
    required int pendingDisputes,
  }) {
    return DashboardStatsModel(
      activeShipments: activeShipments,
      pendingDriverApprovals: pendingDriverApprovals,
      newRegistrationsToday: newRegistrationsToday,
      activeUsers24h: activeUsers24h,
      revenueToday: revenueToday,
      pendingDisputes: pendingDisputes,
      weeklyStats: WeeklyStats.empty(),
      activeShipmentsTrend: TrendIndicator.empty(),
      pendingApprovalsTrend: TrendIndicator.empty(),
      registrationsTrend: TrendIndicator.empty(),
      activeUsersTrend: TrendIndicator.empty(),
      revenueTrend: TrendIndicator.empty(),
      disputesTrend: TrendIndicator.empty(),
      completedShipmentsTrend: TrendIndicator.empty(),
    );
  }

  /// Create from JSON (if using a single RPC call)
  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      activeShipments: json['active_shipments'] as int? ?? 0,
      pendingDriverApprovals: json['pending_driver_approvals'] as int? ?? 0,
      newRegistrationsToday: json['new_registrations_today'] as int? ?? 0,
      activeUsers24h: json['active_users_24h'] as int? ?? 0,
      revenueToday: (json['revenue_today'] as num?)?.toDouble() ?? 0.0,
      pendingDisputes: json['pending_disputes'] as int? ?? 0,
      weeklyStats: WeeklyStats.empty(),
      activeShipmentsTrend: TrendIndicator.empty(),
      pendingApprovalsTrend: TrendIndicator.empty(),
      registrationsTrend: TrendIndicator.empty(),
      activeUsersTrend: TrendIndicator.empty(),
      revenueTrend: TrendIndicator.empty(),
      disputesTrend: TrendIndicator.empty(),
      completedShipmentsTrend: TrendIndicator.empty(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'active_shipments': activeShipments,
      'pending_driver_approvals': pendingDriverApprovals,
      'new_registrations_today': newRegistrationsToday,
      'active_users_24h': activeUsers24h,
      'revenue_today': revenueToday,
      'pending_disputes': pendingDisputes,
    };
  }

  /// Create empty model
  factory DashboardStatsModel.empty() {
    return DashboardStatsModel(
      activeShipments: 0,
      pendingDriverApprovals: 0,
      newRegistrationsToday: 0,
      activeUsers24h: 0,
      revenueToday: 0.0,
      pendingDisputes: 0,
      weeklyStats: WeeklyStats.empty(),
      activeShipmentsTrend: TrendIndicator.empty(),
      pendingApprovalsTrend: TrendIndicator.empty(),
      registrationsTrend: TrendIndicator.empty(),
      activeUsersTrend: TrendIndicator.empty(),
      revenueTrend: TrendIndicator.empty(),
      disputesTrend: TrendIndicator.empty(),
      completedShipmentsTrend: TrendIndicator.empty(),
    );
  }
}
