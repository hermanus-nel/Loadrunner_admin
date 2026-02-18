// lib/features/analytics/domain/entities/performance_metrics.dart

import 'package:flutter/foundation.dart';

/// Rating distribution data
@immutable
class RatingsDistribution {
  final int oneStar;
  final int twoStar;
  final int threeStar;
  final int fourStar;
  final int fiveStar;

  const RatingsDistribution({
    this.oneStar = 0,
    this.twoStar = 0,
    this.threeStar = 0,
    this.fourStar = 0,
    this.fiveStar = 0,
  });

  int get totalRatings => oneStar + twoStar + threeStar + fourStar + fiveStar;

  double get averageRating {
    if (totalRatings == 0) return 0;
    final sum = (oneStar * 1) +
        (twoStar * 2) +
        (threeStar * 3) +
        (fourStar * 4) +
        (fiveStar * 5);
    return sum / totalRatings;
  }

  factory RatingsDistribution.fromJson(Map<String, dynamic> json) {
    return RatingsDistribution(
      oneStar: json['one_star'] as int? ?? 0,
      twoStar: json['two_star'] as int? ?? 0,
      threeStar: json['three_star'] as int? ?? 0,
      fourStar: json['four_star'] as int? ?? 0,
      fiveStar: json['five_star'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'one_star': oneStar,
        'two_star': twoStar,
        'three_star': threeStar,
        'four_star': fourStar,
        'five_star': fiveStar,
      };

  /// Convert to bar chart data
  List<RatingBarData> toChartData() => [
        RatingBarData(stars: 5, count: fiveStar, color: 0xFF4CAF50),
        RatingBarData(stars: 4, count: fourStar, color: 0xFF8BC34A),
        RatingBarData(stars: 3, count: threeStar, color: 0xFFFFEB3B),
        RatingBarData(stars: 2, count: twoStar, color: 0xFFFF9800),
        RatingBarData(stars: 1, count: oneStar, color: 0xFFF44336),
      ];
}

/// Rating bar chart data
@immutable
class RatingBarData {
  final int stars;
  final int count;
  final int color;

  const RatingBarData({
    required this.stars,
    required this.count,
    required this.color,
  });
}

/// Time-based performance metrics
@immutable
class TimeMetrics {
  final double averageDeliveryTimeHours;
  final double averagePickupTimeHours;
  final double averageResponseTimeMinutes;
  final double onTimeDeliveryRate; // percentage
  final double averageTimeToAcceptBidMinutes;

  const TimeMetrics({
    this.averageDeliveryTimeHours = 0,
    this.averagePickupTimeHours = 0,
    this.averageResponseTimeMinutes = 0,
    this.onTimeDeliveryRate = 0,
    this.averageTimeToAcceptBidMinutes = 0,
  });

  factory TimeMetrics.fromJson(Map<String, dynamic> json) {
    return TimeMetrics(
      averageDeliveryTimeHours:
          (json['average_delivery_time_hours'] as num?)?.toDouble() ?? 0,
      averagePickupTimeHours:
          (json['average_pickup_time_hours'] as num?)?.toDouble() ?? 0,
      averageResponseTimeMinutes:
          (json['average_response_time_minutes'] as num?)?.toDouble() ?? 0,
      onTimeDeliveryRate:
          (json['on_time_delivery_rate'] as num?)?.toDouble() ?? 0,
      averageTimeToAcceptBidMinutes:
          (json['average_time_to_accept_bid_minutes'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'average_delivery_time_hours': averageDeliveryTimeHours,
        'average_pickup_time_hours': averagePickupTimeHours,
        'average_response_time_minutes': averageResponseTimeMinutes,
        'on_time_delivery_rate': onTimeDeliveryRate,
        'average_time_to_accept_bid_minutes': averageTimeToAcceptBidMinutes,
      };

  /// Format hours to readable string
  String formatHours(double hours) {
    if (hours < 1) {
      return '${(hours * 60).toStringAsFixed(0)}m';
    } else if (hours < 24) {
      return '${hours.toStringAsFixed(1)}h';
    }
    return '${(hours / 24).toStringAsFixed(1)}d';
  }

  /// Format minutes to readable string
  String formatMinutes(double minutes) {
    if (minutes < 60) {
      return '${minutes.toStringAsFixed(0)}m';
    }
    return '${(minutes / 60).toStringAsFixed(1)}h';
  }
}

/// Driver performance stats
@immutable
class DriverPerformance {
  final double averageRating;
  final int topRatedCount; // drivers with 4.5+ rating
  final int lowRatedCount; // drivers with < 3 rating
  final double deliverySuccessRate;
  final double complaintRate;

  const DriverPerformance({
    this.averageRating = 0,
    this.topRatedCount = 0,
    this.lowRatedCount = 0,
    this.deliverySuccessRate = 0,
    this.complaintRate = 0,
  });

  factory DriverPerformance.fromJson(Map<String, dynamic> json) {
    return DriverPerformance(
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      topRatedCount: json['top_rated_count'] as int? ?? 0,
      lowRatedCount: json['low_rated_count'] as int? ?? 0,
      deliverySuccessRate:
          (json['delivery_success_rate'] as num?)?.toDouble() ?? 0,
      complaintRate: (json['complaint_rate'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'average_rating': averageRating,
        'top_rated_count': topRatedCount,
        'low_rated_count': lowRatedCount,
        'delivery_success_rate': deliverySuccessRate,
        'complaint_rate': complaintRate,
      };
}

/// Platform health metrics
@immutable
class PlatformHealth {
  final double overallSuccessRate;
  final double customerSatisfactionScore;
  final double issueResolutionTimeHours;
  final int activeDisputesCount;
  final double cancellationRate;

  const PlatformHealth({
    this.overallSuccessRate = 0,
    this.customerSatisfactionScore = 0,
    this.issueResolutionTimeHours = 0,
    this.activeDisputesCount = 0,
    this.cancellationRate = 0,
  });

  factory PlatformHealth.fromJson(Map<String, dynamic> json) {
    return PlatformHealth(
      overallSuccessRate:
          (json['overall_success_rate'] as num?)?.toDouble() ?? 0,
      customerSatisfactionScore:
          (json['customer_satisfaction_score'] as num?)?.toDouble() ?? 0,
      issueResolutionTimeHours:
          (json['issue_resolution_time_hours'] as num?)?.toDouble() ?? 0,
      activeDisputesCount: json['active_disputes_count'] as int? ?? 0,
      cancellationRate: (json['cancellation_rate'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'overall_success_rate': overallSuccessRate,
        'customer_satisfaction_score': customerSatisfactionScore,
        'issue_resolution_time_hours': issueResolutionTimeHours,
        'active_disputes_count': activeDisputesCount,
        'cancellation_rate': cancellationRate,
      };
}

/// Low-rated user info for action
@immutable
class LowRatedUser {
  final String id;
  final String name;
  final String type; // 'driver' or 'shipper'
  final double averageRating;
  final int totalRatings;
  final int complaintCount;

  const LowRatedUser({
    required this.id,
    required this.name,
    required this.type,
    this.averageRating = 0,
    this.totalRatings = 0,
    this.complaintCount = 0,
  });

  factory LowRatedUser.fromJson(Map<String, dynamic> json) {
    return LowRatedUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      type: json['type'] as String? ?? 'driver',
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      totalRatings: json['total_ratings'] as int? ?? 0,
      complaintCount: json['complaint_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'average_rating': averageRating,
        'total_ratings': totalRatings,
        'complaint_count': complaintCount,
      };
}

/// Complete performance metrics
@immutable
class PerformanceMetrics {
  final RatingsDistribution ratingsDistribution;
  final TimeMetrics timeMetrics;
  final DriverPerformance driverPerformance;
  final PlatformHealth platformHealth;
  final List<LowRatedUser> lowRatedDrivers;
  final List<LowRatedUser> lowRatedShippers;

  const PerformanceMetrics({
    required this.ratingsDistribution,
    required this.timeMetrics,
    required this.driverPerformance,
    required this.platformHealth,
    required this.lowRatedDrivers,
    required this.lowRatedShippers,
  });

  factory PerformanceMetrics.empty() => PerformanceMetrics(
        ratingsDistribution: const RatingsDistribution(),
        timeMetrics: const TimeMetrics(),
        driverPerformance: const DriverPerformance(),
        platformHealth: const PlatformHealth(),
        lowRatedDrivers: const [],
        lowRatedShippers: const [],
      );

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      ratingsDistribution: json['ratings_distribution'] != null
          ? RatingsDistribution.fromJson(
              json['ratings_distribution'] as Map<String, dynamic>)
          : const RatingsDistribution(),
      timeMetrics: json['time_metrics'] != null
          ? TimeMetrics.fromJson(json['time_metrics'] as Map<String, dynamic>)
          : const TimeMetrics(),
      driverPerformance: json['driver_performance'] != null
          ? DriverPerformance.fromJson(
              json['driver_performance'] as Map<String, dynamic>)
          : const DriverPerformance(),
      platformHealth: json['platform_health'] != null
          ? PlatformHealth.fromJson(
              json['platform_health'] as Map<String, dynamic>)
          : const PlatformHealth(),
      lowRatedDrivers: (json['low_rated_drivers'] as List<dynamic>?)
              ?.map((e) => LowRatedUser.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lowRatedShippers: (json['low_rated_shippers'] as List<dynamic>?)
              ?.map((e) => LowRatedUser.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'ratings_distribution': ratingsDistribution.toJson(),
        'time_metrics': timeMetrics.toJson(),
        'driver_performance': driverPerformance.toJson(),
        'platform_health': platformHealth.toJson(),
        'low_rated_drivers': lowRatedDrivers.map((e) => e.toJson()).toList(),
        'low_rated_shippers': lowRatedShippers.map((e) => e.toJson()).toList(),
      };
}
