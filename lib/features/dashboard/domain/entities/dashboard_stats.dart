// lib/features/dashboard/domain/entities/dashboard_stats.dart

import 'package:flutter/foundation.dart';

/// Data point for trend sparkline charts
@immutable
class TrendDataPoint {
  final DateTime date;
  final double value;

  const TrendDataPoint({
    required this.date,
    required this.value,
  });

  factory TrendDataPoint.fromJson(Map<String, dynamic> json) {
    return TrendDataPoint(
      date: DateTime.parse(json['date'] as String),
      value: (json['value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'value': value,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrendDataPoint &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          value == other.value;

  @override
  int get hashCode => date.hashCode ^ value.hashCode;
}

/// Trend indicator data showing week-over-week comparison
@immutable
class TrendIndicator {
  final double percentageChange;
  final bool isPositive;
  final List<TrendDataPoint> sparklineData;

  const TrendIndicator({
    required this.percentageChange,
    required this.isPositive,
    this.sparklineData = const [],
  });

  factory TrendIndicator.empty() => const TrendIndicator(
        percentageChange: 0,
        isPositive: true,
        sparklineData: [],
      );

  factory TrendIndicator.fromJson(Map<String, dynamic> json) {
    final sparklineList = (json['sparkline_data'] as List<dynamic>?)
            ?.map((e) => TrendDataPoint.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return TrendIndicator(
      percentageChange: (json['percentage_change'] as num?)?.toDouble() ?? 0,
      isPositive: json['is_positive'] as bool? ?? true,
      sparklineData: sparklineList,
    );
  }

  Map<String, dynamic> toJson() => {
        'percentage_change': percentageChange,
        'is_positive': isPositive,
        'sparkline_data': sparklineData.map((e) => e.toJson()).toList(),
      };

  String get formattedPercentage {
    return '${percentageChange.abs().toStringAsFixed(1)}%';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrendIndicator &&
          runtimeType == other.runtimeType &&
          percentageChange == other.percentageChange &&
          isPositive == other.isPositive;

  @override
  int get hashCode => percentageChange.hashCode ^ isPositive.hashCode;
}

/// Extended weekly statistics
@immutable
class WeeklyStats {
  final int completedShipments;
  final double totalRevenue;
  final double averageDeliveryTimeHours;
  final double driverUtilizationRate; // percentage of active drivers with shipments

  const WeeklyStats({
    required this.completedShipments,
    required this.totalRevenue,
    required this.averageDeliveryTimeHours,
    required this.driverUtilizationRate,
  });

  factory WeeklyStats.empty() => const WeeklyStats(
        completedShipments: 0,
        totalRevenue: 0,
        averageDeliveryTimeHours: 0,
        driverUtilizationRate: 0,
      );

  factory WeeklyStats.fromJson(Map<String, dynamic> json) {
    return WeeklyStats(
      completedShipments: json['completed_shipments'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
      averageDeliveryTimeHours:
          (json['average_delivery_time_hours'] as num?)?.toDouble() ?? 0,
      driverUtilizationRate:
          (json['driver_utilization_rate'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'completed_shipments': completedShipments,
        'total_revenue': totalRevenue,
        'average_delivery_time_hours': averageDeliveryTimeHours,
        'driver_utilization_rate': driverUtilizationRate,
      };

  /// Format revenue as ZAR with K/M suffixes
  String get formattedRevenue {
    if (totalRevenue >= 1000000) {
      return 'R${(totalRevenue / 1000000).toStringAsFixed(1)}M';
    } else if (totalRevenue >= 1000) {
      return 'R${(totalRevenue / 1000).toStringAsFixed(1)}K';
    }
    return 'R${totalRevenue.toStringAsFixed(0)}';
  }

  /// Format delivery time
  String get formattedDeliveryTime {
    if (averageDeliveryTimeHours < 1) {
      return '${(averageDeliveryTimeHours * 60).toStringAsFixed(0)}m';
    } else if (averageDeliveryTimeHours < 24) {
      return '${averageDeliveryTimeHours.toStringAsFixed(0)}h';
    }
    return '${(averageDeliveryTimeHours / 24).toStringAsFixed(0)}d';
  }

  /// Format utilization rate
  String get formattedUtilization => '${driverUtilizationRate.toStringAsFixed(0)}%';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyStats &&
          runtimeType == other.runtimeType &&
          completedShipments == other.completedShipments &&
          totalRevenue == other.totalRevenue &&
          averageDeliveryTimeHours == other.averageDeliveryTimeHours &&
          driverUtilizationRate == other.driverUtilizationRate;

  @override
  int get hashCode =>
      completedShipments.hashCode ^
      totalRevenue.hashCode ^
      averageDeliveryTimeHours.hashCode ^
      driverUtilizationRate.hashCode;
}

/// Dashboard statistics entity with trends
@immutable
class DashboardStats {
  // Today's stats
  final int activeShipments;
  final int pendingDriverApprovals;
  final int newRegistrationsToday;
  final int activeUsers24h;
  final double revenueToday;
  final int pendingDisputes;

  // Weekly stats
  final WeeklyStats weeklyStats;

  // Trends (week-over-week comparison)
  final TrendIndicator activeShipmentsTrend;
  final TrendIndicator pendingApprovalsTrend;
  final TrendIndicator registrationsTrend;
  final TrendIndicator activeUsersTrend;
  final TrendIndicator revenueTrend;
  final TrendIndicator disputesTrend;
  final TrendIndicator completedShipmentsTrend;

  const DashboardStats({
    required this.activeShipments,
    required this.pendingDriverApprovals,
    required this.newRegistrationsToday,
    required this.activeUsers24h,
    required this.revenueToday,
    required this.pendingDisputes,
    required this.weeklyStats,
    required this.activeShipmentsTrend,
    required this.pendingApprovalsTrend,
    required this.registrationsTrend,
    required this.activeUsersTrend,
    required this.revenueTrend,
    required this.disputesTrend,
    required this.completedShipmentsTrend,
  });

  factory DashboardStats.empty() => DashboardStats(
        activeShipments: 0,
        pendingDriverApprovals: 0,
        newRegistrationsToday: 0,
        activeUsers24h: 0,
        revenueToday: 0,
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

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      activeShipments: json['active_shipments'] as int? ?? 0,
      pendingDriverApprovals: json['pending_driver_approvals'] as int? ?? 0,
      newRegistrationsToday: json['new_registrations_today'] as int? ?? 0,
      activeUsers24h: json['active_users_24h'] as int? ?? 0,
      revenueToday: (json['revenue_today'] as num?)?.toDouble() ?? 0,
      pendingDisputes: json['pending_disputes'] as int? ?? 0,
      weeklyStats: json['weekly_stats'] != null
          ? WeeklyStats.fromJson(json['weekly_stats'] as Map<String, dynamic>)
          : WeeklyStats.empty(),
      activeShipmentsTrend: json['active_shipments_trend'] != null
          ? TrendIndicator.fromJson(
              json['active_shipments_trend'] as Map<String, dynamic>)
          : TrendIndicator.empty(),
      pendingApprovalsTrend: json['pending_approvals_trend'] != null
          ? TrendIndicator.fromJson(
              json['pending_approvals_trend'] as Map<String, dynamic>)
          : TrendIndicator.empty(),
      registrationsTrend: json['registrations_trend'] != null
          ? TrendIndicator.fromJson(
              json['registrations_trend'] as Map<String, dynamic>)
          : TrendIndicator.empty(),
      activeUsersTrend: json['active_users_trend'] != null
          ? TrendIndicator.fromJson(
              json['active_users_trend'] as Map<String, dynamic>)
          : TrendIndicator.empty(),
      revenueTrend: json['revenue_trend'] != null
          ? TrendIndicator.fromJson(
              json['revenue_trend'] as Map<String, dynamic>)
          : TrendIndicator.empty(),
      disputesTrend: json['disputes_trend'] != null
          ? TrendIndicator.fromJson(
              json['disputes_trend'] as Map<String, dynamic>)
          : TrendIndicator.empty(),
      completedShipmentsTrend: json['completed_shipments_trend'] != null
          ? TrendIndicator.fromJson(
              json['completed_shipments_trend'] as Map<String, dynamic>)
          : TrendIndicator.empty(),
    );
  }

  Map<String, dynamic> toJson() => {
        'active_shipments': activeShipments,
        'pending_driver_approvals': pendingDriverApprovals,
        'new_registrations_today': newRegistrationsToday,
        'active_users_24h': activeUsers24h,
        'revenue_today': revenueToday,
        'pending_disputes': pendingDisputes,
        'weekly_stats': weeklyStats.toJson(),
        'active_shipments_trend': activeShipmentsTrend.toJson(),
        'pending_approvals_trend': pendingApprovalsTrend.toJson(),
        'registrations_trend': registrationsTrend.toJson(),
        'active_users_trend': activeUsersTrend.toJson(),
        'revenue_trend': revenueTrend.toJson(),
        'disputes_trend': disputesTrend.toJson(),
        'completed_shipments_trend': completedShipmentsTrend.toJson(),
      };

  /// Format revenue as ZAR with K/M suffixes
  String get formattedRevenueToday {
    if (revenueToday >= 1000000) {
      return 'R${(revenueToday / 1000000).toStringAsFixed(1)}M';
    } else if (revenueToday >= 1000) {
      return 'R${(revenueToday / 1000).toStringAsFixed(1)}K';
    }
    return 'R${revenueToday.toStringAsFixed(0)}';
  }

  DashboardStats copyWith({
    int? activeShipments,
    int? pendingDriverApprovals,
    int? newRegistrationsToday,
    int? activeUsers24h,
    double? revenueToday,
    int? pendingDisputes,
    WeeklyStats? weeklyStats,
    TrendIndicator? activeShipmentsTrend,
    TrendIndicator? pendingApprovalsTrend,
    TrendIndicator? registrationsTrend,
    TrendIndicator? activeUsersTrend,
    TrendIndicator? revenueTrend,
    TrendIndicator? disputesTrend,
    TrendIndicator? completedShipmentsTrend,
  }) {
    return DashboardStats(
      activeShipments: activeShipments ?? this.activeShipments,
      pendingDriverApprovals:
          pendingDriverApprovals ?? this.pendingDriverApprovals,
      newRegistrationsToday:
          newRegistrationsToday ?? this.newRegistrationsToday,
      activeUsers24h: activeUsers24h ?? this.activeUsers24h,
      revenueToday: revenueToday ?? this.revenueToday,
      pendingDisputes: pendingDisputes ?? this.pendingDisputes,
      weeklyStats: weeklyStats ?? this.weeklyStats,
      activeShipmentsTrend: activeShipmentsTrend ?? this.activeShipmentsTrend,
      pendingApprovalsTrend:
          pendingApprovalsTrend ?? this.pendingApprovalsTrend,
      registrationsTrend: registrationsTrend ?? this.registrationsTrend,
      activeUsersTrend: activeUsersTrend ?? this.activeUsersTrend,
      revenueTrend: revenueTrend ?? this.revenueTrend,
      disputesTrend: disputesTrend ?? this.disputesTrend,
      completedShipmentsTrend:
          completedShipmentsTrend ?? this.completedShipmentsTrend,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardStats &&
          runtimeType == other.runtimeType &&
          activeShipments == other.activeShipments &&
          pendingDriverApprovals == other.pendingDriverApprovals &&
          newRegistrationsToday == other.newRegistrationsToday &&
          activeUsers24h == other.activeUsers24h &&
          revenueToday == other.revenueToday &&
          pendingDisputes == other.pendingDisputes;

  @override
  int get hashCode =>
      activeShipments.hashCode ^
      pendingDriverApprovals.hashCode ^
      newRegistrationsToday.hashCode ^
      activeUsers24h.hashCode ^
      revenueToday.hashCode ^
      pendingDisputes.hashCode;
}
