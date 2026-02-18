// lib/features/dashboard/data/repositories/dashboard_repository_impl.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../../../core/services/jwt_recovery_handler.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final SupabaseClient _supabaseClient;
  final JwtRecoveryHandler _jwtRecoveryHandler;

  DashboardRepositoryImpl({
    required SupabaseClient supabaseClient,
    required JwtRecoveryHandler jwtRecoveryHandler,
  })  : _supabaseClient = supabaseClient,
        _jwtRecoveryHandler = jwtRecoveryHandler;

  @override
  Future<DashboardStats> fetchDashboardStats() async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      debugPrint('DashboardRepository: Fetching all dashboard stats with trends...');

      // Fetch all stats in parallel
      final results = await Future.wait([
        fetchActiveShipmentsCount(),
        fetchPendingDriverApprovalsCount(),
        fetchNewRegistrationsTodayCount(),
        fetchActiveUsers24hCount(),
        fetchRevenueTodayAmount(),
        fetchPendingDisputesCount(),
        fetchWeeklyStats(),
        fetchTrends(),
      ]);

      final trends = results[7] as Map<String, TrendIndicator>;

      return DashboardStats(
        activeShipments: results[0] as int,
        pendingDriverApprovals: results[1] as int,
        newRegistrationsToday: results[2] as int,
        activeUsers24h: results[3] as int,
        revenueToday: results[4] as double,
        pendingDisputes: results[5] as int,
        weeklyStats: results[6] as WeeklyStats,
        activeShipmentsTrend:
            trends['active_shipments'] ?? TrendIndicator.empty(),
        pendingApprovalsTrend:
            trends['pending_approvals'] ?? TrendIndicator.empty(),
        registrationsTrend:
            trends['registrations'] ?? TrendIndicator.empty(),
        activeUsersTrend: trends['active_users'] ?? TrendIndicator.empty(),
        revenueTrend: trends['revenue'] ?? TrendIndicator.empty(),
        disputesTrend: trends['disputes'] ?? TrendIndicator.empty(),
        completedShipmentsTrend:
            trends['completed_shipments'] ?? TrendIndicator.empty(),
      );
    });
  }

  @override
  Future<DashboardStats> fetchTodayStats() async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      debugPrint('DashboardRepository: Fetching today stats only...');

      final results = await Future.wait([
        fetchActiveShipmentsCount(),
        fetchPendingDriverApprovalsCount(),
        fetchNewRegistrationsTodayCount(),
        fetchActiveUsers24hCount(),
        fetchRevenueTodayAmount(),
        fetchPendingDisputesCount(),
      ]);

      return DashboardStats(
        activeShipments: results[0] as int,
        pendingDriverApprovals: results[1] as int,
        newRegistrationsToday: results[2] as int,
        activeUsers24h: results[3] as int,
        revenueToday: results[4] as double,
        pendingDisputes: results[5] as int,
        weeklyStats: WeeklyStats.empty(),
        activeShipmentsTrend: TrendIndicator.empty(),
        pendingApprovalsTrend: TrendIndicator.empty(),
        registrationsTrend: TrendIndicator.empty(),
        activeUsersTrend: TrendIndicator.empty(),
        revenueTrend: TrendIndicator.empty(),
        disputesTrend: TrendIndicator.empty(),
        completedShipmentsTrend: TrendIndicator.empty(),
      );
    });
  }

  @override
  Future<WeeklyStats> fetchWeeklyStats() async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      debugPrint('DashboardRepository: Fetching weekly stats...');

      final now = DateTime.now();
      final weekStart = now.subtract(const Duration(days: 7));

      final results = await Future.wait([
        fetchCompletedShipmentsCount(startDate: weekStart, endDate: now),
        fetchTotalRevenue(startDate: weekStart, endDate: now),
        fetchAverageDeliveryTime(startDate: weekStart, endDate: now),
        fetchDriverUtilizationRate(),
      ]);

      return WeeklyStats(
        completedShipments: results[0] as int,
        totalRevenue: results[1] as double,
        averageDeliveryTimeHours: results[2] as double,
        driverUtilizationRate: results[3] as double,
      );
    });
  }

  @override
  Future<Map<String, TrendIndicator>> fetchTrends() async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      debugPrint('DashboardRepository: Fetching trends...');

      final now = DateTime.now();
      final thisWeekStart = now.subtract(const Duration(days: 7));
      final lastWeekStart = now.subtract(const Duration(days: 14));

      // Fetch sparkline data and calculate trends
      final results = await Future.wait([
        _fetchRevenueComparison(thisWeekStart, lastWeekStart, now),
        _fetchShipmentsComparison(thisWeekStart, lastWeekStart, now),
        _fetchRegistrationsComparison(thisWeekStart, lastWeekStart, now),
        fetchSparklineData('revenue'),
        fetchSparklineData('shipments'),
        fetchSparklineData('registrations'),
        fetchSparklineData('active_users'),
        fetchSparklineData('active_shipments'),
      ]);

      final revenueTrend = results[0] as _TrendData;
      final shipmentsTrend = results[1] as _TrendData;
      final registrationsTrend = results[2] as _TrendData;
      final revenueSparkline = results[3] as List<TrendDataPoint>;
      final shipmentsSparkline = results[4] as List<TrendDataPoint>;
      final registrationsSparkline = results[5] as List<TrendDataPoint>;
      final activeUsersSparkline = results[6] as List<TrendDataPoint>;
      final activeShipmentsSparkline = results[7] as List<TrendDataPoint>;

      return {
        'revenue': TrendIndicator(
          percentageChange: revenueTrend.percentageChange,
          isPositive: revenueTrend.isPositive,
          sparklineData: revenueSparkline,
        ),
        'completed_shipments': TrendIndicator(
          percentageChange: shipmentsTrend.percentageChange,
          isPositive: shipmentsTrend.isPositive,
          sparklineData: shipmentsSparkline,
        ),
        'registrations': TrendIndicator(
          percentageChange: registrationsTrend.percentageChange,
          isPositive: registrationsTrend.isPositive,
          sparklineData: registrationsSparkline,
        ),
        'active_users': TrendIndicator(
          percentageChange: 0, // Calculate if needed
          isPositive: true,
          sparklineData: activeUsersSparkline,
        ),
        'active_shipments': TrendIndicator(
          percentageChange: 0,
          isPositive: true,
          sparklineData: activeShipmentsSparkline,
        ),
        'pending_approvals': TrendIndicator.empty(),
        'disputes': TrendIndicator.empty(),
      };
    });
  }

  Future<_TrendData> _fetchRevenueComparison(
    DateTime thisWeekStart,
    DateTime lastWeekStart,
    DateTime now,
  ) async {
    try {
      // This week's commission revenue
      final thisWeekResponse = await _supabaseClient
          .from('payments')
          .select('total_commission')
          .eq('status', 'completed')
          .gte('created_at', thisWeekStart.toIso8601String())
          .lte('created_at', now.toIso8601String());

      double thisWeekRevenue = 0;
      for (final row in thisWeekResponse as List) {
        thisWeekRevenue +=
            (row['total_commission'] as num?)?.toDouble() ?? 0;
      }

      // Last week's commission revenue
      final lastWeekResponse = await _supabaseClient
          .from('payments')
          .select('total_commission')
          .eq('status', 'completed')
          .gte('created_at', lastWeekStart.toIso8601String())
          .lt('created_at', thisWeekStart.toIso8601String());

      double lastWeekRevenue = 0;
      for (final row in lastWeekResponse as List) {
        lastWeekRevenue +=
            (row['total_commission'] as num?)?.toDouble() ?? 0;
      }

      return _calculateTrend(thisWeekRevenue, lastWeekRevenue);
    } catch (e) {
      debugPrint('DashboardRepository: Error fetching revenue comparison: $e');
      return _TrendData(percentageChange: 0, isPositive: true);
    }
  }

  Future<_TrendData> _fetchShipmentsComparison(
    DateTime thisWeekStart,
    DateTime lastWeekStart,
    DateTime now,
  ) async {
    try {
      final results = await Future.wait([
        _supabaseClient
            .from('freight_posts')
            .select()
            .eq('status', 'Delivered')
            .gte('updated_at', thisWeekStart.toIso8601String())
            .lte('updated_at', now.toIso8601String())
            .count(CountOption.exact),
        _supabaseClient
            .from('freight_posts')
            .select()
            .eq('status', 'Delivered')
            .gte('updated_at', lastWeekStart.toIso8601String())
            .lt('updated_at', thisWeekStart.toIso8601String())
            .count(CountOption.exact),
      ]);

      return _calculateTrend(
        results[0].count.toDouble(),
        results[1].count.toDouble(),
      );
    } catch (e) {
      debugPrint('DashboardRepository: Error fetching shipments comparison: $e');
      return _TrendData(percentageChange: 0, isPositive: true);
    }
  }

  Future<_TrendData> _fetchRegistrationsComparison(
    DateTime thisWeekStart,
    DateTime lastWeekStart,
    DateTime now,
  ) async {
    try {
      final results = await Future.wait([
        _supabaseClient
            .from('users')
            .select()
            .gte('created_at', thisWeekStart.toIso8601String())
            .lte('created_at', now.toIso8601String())
            .count(CountOption.exact),
        _supabaseClient
            .from('users')
            .select()
            .gte('created_at', lastWeekStart.toIso8601String())
            .lt('created_at', thisWeekStart.toIso8601String())
            .count(CountOption.exact),
      ]);

      return _calculateTrend(
        results[0].count.toDouble(),
        results[1].count.toDouble(),
      );
    } catch (e) {
      debugPrint('DashboardRepository: Error fetching registrations comparison: $e');
      return _TrendData(percentageChange: 0, isPositive: true);
    }
  }

  _TrendData _calculateTrend(double current, double previous) {
    if (previous == 0) {
      return _TrendData(
        percentageChange: current > 0 ? 100 : 0,
        isPositive: current >= 0,
      );
    }

    final change = ((current - previous) / previous) * 100;
    return _TrendData(
      percentageChange: change.abs(),
      isPositive: change >= 0,
    );
  }

  @override
  Future<List<TrendDataPoint>> fetchSparklineData(String metricType) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      debugPrint('DashboardRepository: Fetching sparkline data for $metricType...');

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(const Duration(days: 6));
      final dayAfterToday = today.add(const Duration(days: 1));

      try {
        // Single query fetching all 7 days of data at once
        switch (metricType) {
          case 'revenue':
            final response = await _supabaseClient
                .from('payments')
                .select('total_commission, created_at')
                .eq('status', 'completed')
                .gte('created_at', weekStart.toIso8601String())
                .lt('created_at', dayAfterToday.toIso8601String());

            return _groupByDay(
              rows: response as List,
              dateField: 'created_at',
              weekStart: weekStart,
              valueExtractor: (rows) {
                double sum = 0;
                for (final row in rows) {
                  sum += (row['total_commission'] as num?)?.toDouble() ?? 0;
                }
                return sum;
              },
            );

          case 'shipments':
            final response = await _supabaseClient
                .from('freight_posts')
                .select('updated_at')
                .eq('status', 'Delivered')
                .gte('updated_at', weekStart.toIso8601String())
                .lt('updated_at', dayAfterToday.toIso8601String());

            return _groupByDay(
              rows: response as List,
              dateField: 'updated_at',
              weekStart: weekStart,
              valueExtractor: (rows) => rows.length.toDouble(),
            );

          case 'registrations':
            final response = await _supabaseClient
                .from('users')
                .select('created_at')
                .gte('created_at', weekStart.toIso8601String())
                .lt('created_at', dayAfterToday.toIso8601String());

            return _groupByDay(
              rows: response as List,
              dateField: 'created_at',
              weekStart: weekStart,
              valueExtractor: (rows) => rows.length.toDouble(),
            );

          case 'active_users':
            final response = await _supabaseClient
                .from('users')
                .select('last_login_at')
                .gte('last_login_at', weekStart.toIso8601String())
                .lt('last_login_at', dayAfterToday.toIso8601String());

            return _groupByDay(
              rows: response as List,
              dateField: 'last_login_at',
              weekStart: weekStart,
              valueExtractor: (rows) => rows.length.toDouble(),
            );

          case 'active_shipments':
            final response = await _supabaseClient
                .from('freight_posts')
                .select('created_at')
                .inFilter('status', ['Bidding', 'Pickup', 'OnRoute'])
                .gte('created_at', weekStart.toIso8601String())
                .lt('created_at', dayAfterToday.toIso8601String());

            return _groupByDay(
              rows: response as List,
              dateField: 'created_at',
              weekStart: weekStart,
              valueExtractor: (rows) => rows.length.toDouble(),
            );

          default:
            return _emptySparkline(weekStart);
        }
      } catch (e) {
        debugPrint('DashboardRepository: Error fetching sparkline data for $metricType: $e');
        return _emptySparkline(weekStart);
      }
    });
  }

  /// Groups rows by day and produces 7 TrendDataPoints.
  List<TrendDataPoint> _groupByDay({
    required List<dynamic> rows,
    required String dateField,
    required DateTime weekStart,
    required double Function(List<dynamic> dayRows) valueExtractor,
  }) {
    // Bucket rows by day offset (0-6)
    final buckets = <int, List<dynamic>>{};
    for (final row in rows) {
      final dateStr = row[dateField] as String?;
      if (dateStr == null) continue;
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;
      final dayOffset = DateTime(date.year, date.month, date.day)
          .difference(weekStart)
          .inDays;
      if (dayOffset >= 0 && dayOffset < 7) {
        (buckets[dayOffset] ??= []).add(row);
      }
    }

    return List.generate(7, (i) {
      final date = weekStart.add(Duration(days: i));
      final dayRows = buckets[i] ?? [];
      return TrendDataPoint(
        date: date,
        value: dayRows.isEmpty ? 0 : valueExtractor(dayRows),
      );
    });
  }

  List<TrendDataPoint> _emptySparkline(DateTime weekStart) {
    return List.generate(7, (i) {
      return TrendDataPoint(
        date: weekStart.add(Duration(days: i)),
        value: 0,
      );
    });
  }

  @override
  Future<int> fetchActiveShipmentsCount() async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        final response = await _supabaseClient
            .from('freight_posts')
            .select()
            .inFilter('status', ['Bidding', 'Pickup', 'OnRoute'])
            .count(CountOption.exact);

        final count = response.count;
        debugPrint('DashboardRepository: Active shipments: $count');
        return count;
      } catch (e) {
        debugPrint('DashboardRepository: Error fetching active shipments: $e');
        return 0;
      }
    });
  }

  @override
  Future<int> fetchPendingDriverApprovalsCount() async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        final response = await _supabaseClient
            .from('users')
            .select()
            .eq('role', 'Driver')
            .eq('driver_verification_status', 'pending')
            .count(CountOption.exact);

        final count = response.count;
        debugPrint('DashboardRepository: Pending driver approvals: $count');
        return count;
      } catch (e) {
        debugPrint('DashboardRepository: Error fetching pending approvals: $e');
        return 0;
      }
    });
  }

  @override
  Future<int> fetchNewRegistrationsTodayCount() async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        final todayStart = DateTime.now().toUtc();
        final today = DateTime(todayStart.year, todayStart.month, todayStart.day);

        final response = await _supabaseClient
            .from('users')
            .select()
            .gte('created_at', today.toIso8601String())
            .count(CountOption.exact);

        final count = response.count;
        debugPrint('DashboardRepository: New registrations today: $count');
        return count;
      } catch (e) {
        debugPrint('DashboardRepository: Error fetching new registrations: $e');
        return 0;
      }
    });
  }

  @override
  Future<int> fetchActiveUsers24hCount() async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        final yesterday = DateTime.now().subtract(const Duration(hours: 24));

        final response = await _supabaseClient
            .from('users')
            .select()
            .gte('last_login_at', yesterday.toIso8601String())
            .count(CountOption.exact);

        final count = response.count;
        debugPrint('DashboardRepository: Active users (24h): $count');
        return count;
      } catch (e) {
        debugPrint('DashboardRepository: Error fetching active users: $e');
        return 0;
      }
    });
  }

  @override
  Future<double> fetchRevenueTodayAmount() async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        // Today's commission revenue from completed payments
        final todayStart = DateTime.now().toUtc();
        final today = DateTime(todayStart.year, todayStart.month, todayStart.day);

        final response = await _supabaseClient
            .from('payments')
            .select('total_commission')
            .eq('status', 'completed')
            .gte('created_at', today.toIso8601String());

        double totalRevenue = 0;
        for (final row in response as List) {
          final commission = row['total_commission'];
          if (commission != null) {
            totalRevenue += (commission as num).toDouble();
          }
        }

        debugPrint('DashboardRepository: Commission today: R $totalRevenue');
        return totalRevenue;
      } catch (e) {
        debugPrint('DashboardRepository: Error fetching revenue: $e');
        return 0.0;
      }
    });
  }

  @override
  Future<int> fetchPendingDisputesCount() async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        final response = await _supabaseClient
            .from('disputes')
            .select()
            .inFilter('status', ['open', 'under_review'])
            .count(CountOption.exact);

        final count = response.count;
        debugPrint('DashboardRepository: Pending disputes: $count');
        return count;
      } catch (e) {
        // disputes table might not exist yet
        debugPrint('DashboardRepository: Error fetching disputes: $e');
        return 0;
      }
    });
  }

  @override
  Future<int> fetchCompletedShipmentsCount({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        final response = await _supabaseClient
            .from('freight_posts')
            .select()
            .eq('status', 'Delivered')
            .gte('updated_at', startDate.toIso8601String())
            .lte('updated_at', endDate.toIso8601String())
            .count(CountOption.exact);

        final count = response.count;
        debugPrint('DashboardRepository: Completed shipments ($startDate - $endDate): $count');
        return count;
      } catch (e) {
        debugPrint('DashboardRepository: Error fetching completed shipments: $e');
        return 0;
      }
    });
  }

  @override
  Future<double> fetchTotalRevenue({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        final response = await _supabaseClient
            .from('payments')
            .select('total_commission')
            .eq('status', 'completed')
            .gte('created_at', startDate.toIso8601String())
            .lte('created_at', endDate.toIso8601String());

        double total = 0;
        for (final row in response as List) {
          total += (row['total_commission'] as num?)?.toDouble() ?? 0;
        }

        debugPrint('DashboardRepository: Total commission ($startDate - $endDate): R $total');
        return total;
      } catch (e) {
        debugPrint('DashboardRepository: Error fetching total revenue: $e');
        return 0.0;
      }
    });
  }

  @override
  Future<double> fetchAverageDeliveryTime({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        // Get delivered shipments with pickup and delivery confirmation times
        final response = await _supabaseClient
            .from('freight_posts')
            .select('pickup_confirmed_at, delivery_confirmed_at')
            .eq('status', 'Delivered')
            .gte('delivery_confirmed_at', startDate.toIso8601String())
            .lte('delivery_confirmed_at', endDate.toIso8601String());

        final shipments = response as List;
        if (shipments.isEmpty) return 0.0;

        double totalHours = 0;
        int validCount = 0;

        for (final shipment in shipments) {
          final pickedUpAt = DateTime.tryParse(
            shipment['pickup_confirmed_at'] as String? ?? '',
          );
          final deliveredAt = DateTime.tryParse(
            shipment['delivery_confirmed_at'] as String? ?? '',
          );

          if (pickedUpAt != null && deliveredAt != null) {
            final duration = deliveredAt.difference(pickedUpAt);
            totalHours += duration.inMinutes / 60.0;
            validCount++;
          }
        }

        final average = validCount > 0 ? totalHours / validCount : 0.0;
        debugPrint('DashboardRepository: Average delivery time: ${average.toStringAsFixed(1)}h');
        return average;
      } catch (e) {
        debugPrint('DashboardRepository: Error fetching average delivery time: $e');
        return 0.0;
      }
    });
  }

  @override
  Future<double> fetchDriverUtilizationRate() async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        // Count total approved drivers
        final driversResponse = await _supabaseClient
            .from('users')
            .select()
            .eq('role', 'Driver')
            .eq('driver_verification_status', 'approved')
            .count(CountOption.exact);

        final totalDrivers = driversResponse.count;
        if (totalDrivers == 0) return 0.0;

        // Get drivers with accepted bids
        final activeBidsResponse = await _supabaseClient
            .from('bids')
            .select('driver_id, freight_post_id')
            .eq('status', 'Accepted');

        final bids = activeBidsResponse as List;
        if (bids.isEmpty) return 0.0;

        // Collect unique freight_post_ids to check in a single batch query
        final freightPostIds = <String>{};
        final bidsByFreightPost = <String, Set<String>>{};

        for (final bid in bids) {
          final driverId = bid['driver_id'] as Object?;
          final freightPostId = bid['freight_post_id'] as Object?;
          if (driverId != null && freightPostId != null) {
            final fpId = freightPostId.toString();
            freightPostIds.add(fpId);
            (bidsByFreightPost[fpId] ??= {}).add(driverId.toString());
          }
        }

        if (freightPostIds.isEmpty) return 0.0;

        // Single batch query: find which freight posts are active
        final activeFreightResponse = await _supabaseClient
            .from('freight_posts')
            .select('id')
            .inFilter('id', freightPostIds.toList())
            .inFilter('status', ['Pickup', 'OnRoute']);

        final activeDriverIds = <String>{};
        for (final freight in activeFreightResponse as List) {
          final fpId = freight['id'].toString();
          final drivers = bidsByFreightPost[fpId];
          if (drivers != null) {
            activeDriverIds.addAll(drivers);
          }
        }

        final rate = (activeDriverIds.length / totalDrivers) * 100;
        debugPrint('DashboardRepository: Driver utilization: ${rate.toStringAsFixed(1)}%');
        return rate;
      } catch (e) {
        debugPrint('DashboardRepository: Error fetching driver utilization: $e');
        return 0.0;
      }
    });
  }

  @override
  Future<List<TrendDataPoint>> fetchRevenueSparkline({
    required DateTime startDate,
    required DateTime endDate,
    required int buckets,
  }) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        final response = await _supabaseClient
            .from('payments')
            .select('total_commission, created_at')
            .eq('status', 'completed')
            .gte('created_at', startDate.toIso8601String())
            .lte('created_at', endDate.toIso8601String());

        final totalMs = endDate.difference(startDate).inMilliseconds;
        if (totalMs <= 0 || buckets <= 0) return [];
        final bucketMs = totalMs ~/ buckets;
        final bucketValues = List<double>.filled(buckets, 0);

        for (final row in response as List) {
          final dateStr = row['created_at'] as String?;
          if (dateStr == null) continue;
          final date = DateTime.tryParse(dateStr);
          if (date == null) continue;
          final offsetMs = date.difference(startDate).inMilliseconds;
          final index = (offsetMs ~/ bucketMs).clamp(0, buckets - 1);
          bucketValues[index] +=
              (row['total_commission'] as num?)?.toDouble() ?? 0;
        }

        return List.generate(buckets, (i) {
          return TrendDataPoint(
            date: startDate.add(Duration(milliseconds: bucketMs * i)),
            value: bucketValues[i],
          );
        });
      } catch (e) {
        debugPrint(
            'DashboardRepository: Error fetching revenue sparkline: $e');
        return [];
      }
    });
  }

  @override
  Future<int> fetchShipmentsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        final response = await _supabaseClient
            .from('freight_posts')
            .select()
            .gte('created_at', startDate.toIso8601String())
            .lte('created_at', endDate.toIso8601String())
            .count(CountOption.exact);
        return response.count;
      } catch (e) {
        debugPrint(
            'DashboardRepository: Error fetching shipments in range: $e');
        return 0;
      }
    });
  }

  @override
  Future<int> fetchRegistrationsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        final response = await _supabaseClient
            .from('users')
            .select()
            .gte('created_at', startDate.toIso8601String())
            .lte('created_at', endDate.toIso8601String())
            .count(CountOption.exact);
        return response.count;
      } catch (e) {
        debugPrint(
            'DashboardRepository: Error fetching registrations in range: $e');
        return 0;
      }
    });
  }

  @override
  Future<int> fetchActiveUsersInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        final response = await _supabaseClient
            .from('users')
            .select()
            .gte('last_login_at', startDate.toIso8601String())
            .lte('last_login_at', endDate.toIso8601String())
            .count(CountOption.exact);
        return response.count;
      } catch (e) {
        debugPrint(
            'DashboardRepository: Error fetching active users in range: $e');
        return 0;
      }
    });
  }

  @override
  Future<List<TrendDataPoint>> fetchCountSparkline({
    required String metricType,
    required DateTime startDate,
    required DateTime endDate,
    required int buckets,
  }) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        final String table;
        final String dateField;

        switch (metricType) {
          case 'shipments':
            table = 'freight_posts';
            dateField = 'created_at';
          case 'registrations':
            table = 'users';
            dateField = 'created_at';
          case 'active_users':
            table = 'users';
            dateField = 'last_login_at';
          default:
            return [];
        }

        final response = await _supabaseClient
            .from(table)
            .select(dateField)
            .gte(dateField, startDate.toIso8601String())
            .lte(dateField, endDate.toIso8601String());

        final totalMs = endDate.difference(startDate).inMilliseconds;
        if (totalMs <= 0 || buckets <= 0) return [];
        final bucketMs = totalMs ~/ buckets;
        final bucketCounts = List<int>.filled(buckets, 0);

        for (final row in response as List) {
          final dateStr = row[dateField] as String?;
          if (dateStr == null) continue;
          final date = DateTime.tryParse(dateStr);
          if (date == null) continue;
          final offsetMs = date.difference(startDate).inMilliseconds;
          final index = (offsetMs ~/ bucketMs).clamp(0, buckets - 1);
          bucketCounts[index]++;
        }

        return List.generate(buckets, (i) {
          return TrendDataPoint(
            date: startDate.add(Duration(milliseconds: bucketMs * i)),
            value: bucketCounts[i].toDouble(),
          );
        });
      } catch (e) {
        debugPrint(
            'DashboardRepository: Error fetching count sparkline: $e');
        return [];
      }
    });
  }
}

/// Internal class to hold trend calculation data
class _TrendData {
  final double percentageChange;
  final bool isPositive;

  _TrendData({
    required this.percentageChange,
    required this.isPositive,
  });
}
