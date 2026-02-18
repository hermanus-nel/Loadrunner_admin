// lib/features/analytics/domain/entities/activity_metrics.dart

import 'package:flutter/foundation.dart';

/// Shipment count by status
@immutable
class ShipmentsByStatus {
  final int bidding;
  final int pickup;
  final int onRoute;
  final int delivered;
  final int cancelled;

  const ShipmentsByStatus({
    this.bidding = 0,
    this.pickup = 0,
    this.onRoute = 0,
    this.delivered = 0,
    this.cancelled = 0,
  });

  int get total => bidding + pickup + onRoute + delivered + cancelled;
  int get active => bidding + pickup + onRoute;

  factory ShipmentsByStatus.fromJson(Map<String, dynamic> json) {
    return ShipmentsByStatus(
      bidding: json['bidding'] as int? ?? 0,
      pickup: json['pickup'] as int? ?? 0,
      onRoute: json['on_route'] as int? ?? 0,
      delivered: json['delivered'] as int? ?? 0,
      cancelled: json['cancelled'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'bidding': bidding,
        'pickup': pickup,
        'on_route': onRoute,
        'delivered': delivered,
        'cancelled': cancelled,
      };

  /// Convert to chart data format
  List<ChartDataPoint> toChartData() => [
        ChartDataPoint(label: 'Bidding', value: bidding.toDouble(), color: 0xFF4CAF50),
        ChartDataPoint(label: 'Pickup', value: pickup.toDouble(), color: 0xFFFF6B00),
        ChartDataPoint(label: 'On Route', value: onRoute.toDouble(), color: 0xFF216A91),
        ChartDataPoint(label: 'Delivered', value: delivered.toDouble(), color: 0xFF9E9E9E),
        ChartDataPoint(label: 'Cancelled', value: cancelled.toDouble(), color: 0xFFB00020),
      ];
}

/// Daily shipment data point
@immutable
class DailyShipments {
  final DateTime date;
  final int count;
  final int bidding;
  final int pickup;
  final int onRoute;
  final int delivered;
  final int cancelled;

  const DailyShipments({
    required this.date,
    this.count = 0,
    this.bidding = 0,
    this.pickup = 0,
    this.onRoute = 0,
    this.delivered = 0,
    this.cancelled = 0,
  });

  factory DailyShipments.fromJson(Map<String, dynamic> json) {
    return DailyShipments(
      date: DateTime.parse(json['date'] as String),
      count: json['count'] as int? ?? 0,
      bidding: json['bidding'] as int? ?? 0,
      pickup: json['pickup'] as int? ?? 0,
      onRoute: json['on_route'] as int? ?? 0,
      delivered: json['delivered'] as int? ?? 0,
      cancelled: json['cancelled'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'count': count,
        'bidding': bidding,
        'pickup': pickup,
        'on_route': onRoute,
        'delivered': delivered,
        'cancelled': cancelled,
      };
}

/// Daily active users data point
@immutable
class DailyActiveUsers {
  final DateTime date;
  final int totalUsers;
  final int drivers;
  final int shippers;

  const DailyActiveUsers({
    required this.date,
    this.totalUsers = 0,
    this.drivers = 0,
    this.shippers = 0,
  });

  factory DailyActiveUsers.fromJson(Map<String, dynamic> json) {
    return DailyActiveUsers(
      date: DateTime.parse(json['date'] as String),
      totalUsers: json['total_users'] as int? ?? 0,
      drivers: json['drivers'] as int? ?? 0,
      shippers: json['shippers'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'total_users': totalUsers,
        'drivers': drivers,
        'shippers': shippers,
      };
}

/// User statistics
@immutable
class UserStats {
  final int totalUsers;
  final int totalDrivers;
  final int totalShippers;
  final int verifiedDrivers;
  final int activeUsersToday;
  final int newUsersThisWeek;

  const UserStats({
    this.totalUsers = 0,
    this.totalDrivers = 0,
    this.totalShippers = 0,
    this.verifiedDrivers = 0,
    this.activeUsersToday = 0,
    this.newUsersThisWeek = 0,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalUsers: json['total_users'] as int? ?? 0,
      totalDrivers: json['total_drivers'] as int? ?? 0,
      totalShippers: json['total_shippers'] as int? ?? 0,
      verifiedDrivers: json['verified_drivers'] as int? ?? 0,
      activeUsersToday: json['active_users_today'] as int? ?? 0,
      newUsersThisWeek: json['new_users_this_week'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_users': totalUsers,
        'total_drivers': totalDrivers,
        'total_shippers': totalShippers,
        'verified_drivers': verifiedDrivers,
        'active_users_today': activeUsersToday,
        'new_users_this_week': newUsersThisWeek,
      };
}

/// Complete activity metrics
@immutable
class ActivityMetrics {
  final ShipmentsByStatus shipmentsByStatus;
  final List<DailyShipments> dailyShipments;
  final List<DailyActiveUsers> dailyActiveUsers;
  final UserStats userStats;
  final int totalBids;
  final double avgBidsPerShipment;
  final double bidAcceptanceRate;

  const ActivityMetrics({
    required this.shipmentsByStatus,
    required this.dailyShipments,
    required this.dailyActiveUsers,
    required this.userStats,
    this.totalBids = 0,
    this.avgBidsPerShipment = 0,
    this.bidAcceptanceRate = 0,
  });

  factory ActivityMetrics.empty() => ActivityMetrics(
        shipmentsByStatus: const ShipmentsByStatus(),
        dailyShipments: const [],
        dailyActiveUsers: const [],
        userStats: const UserStats(),
      );

  factory ActivityMetrics.fromJson(Map<String, dynamic> json) {
    return ActivityMetrics(
      shipmentsByStatus: json['shipments_by_status'] != null
          ? ShipmentsByStatus.fromJson(
              json['shipments_by_status'] as Map<String, dynamic>)
          : const ShipmentsByStatus(),
      dailyShipments: (json['daily_shipments'] as List<dynamic>?)
              ?.map((e) => DailyShipments.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      dailyActiveUsers: (json['daily_active_users'] as List<dynamic>?)
              ?.map((e) => DailyActiveUsers.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      userStats: json['user_stats'] != null
          ? UserStats.fromJson(json['user_stats'] as Map<String, dynamic>)
          : const UserStats(),
      totalBids: json['total_bids'] as int? ?? 0,
      avgBidsPerShipment:
          (json['avg_bids_per_shipment'] as num?)?.toDouble() ?? 0,
      bidAcceptanceRate:
          (json['bid_acceptance_rate'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'shipments_by_status': shipmentsByStatus.toJson(),
        'daily_shipments': dailyShipments.map((e) => e.toJson()).toList(),
        'daily_active_users': dailyActiveUsers.map((e) => e.toJson()).toList(),
        'user_stats': userStats.toJson(),
        'total_bids': totalBids,
        'avg_bids_per_shipment': avgBidsPerShipment,
        'bid_acceptance_rate': bidAcceptanceRate,
      };
}

/// Generic chart data point
@immutable
class ChartDataPoint {
  final String label;
  final double value;
  final int color;

  const ChartDataPoint({
    required this.label,
    required this.value,
    required this.color,
  });
}
