// lib/features/analytics/data/repositories/analytics_repository_impl.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/activity_metrics.dart';
import '../../domain/entities/financial_metrics.dart';
import '../../domain/entities/performance_metrics.dart';
import '../../domain/entities/date_range.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../../../core/services/jwt_recovery_handler.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final SupabaseClient _supabaseClient;
  final JwtRecoveryHandler _jwtRecoveryHandler;

  AnalyticsRepositoryImpl({
    required SupabaseClient supabaseClient,
    required JwtRecoveryHandler jwtRecoveryHandler,
  })  : _supabaseClient = supabaseClient,
        _jwtRecoveryHandler = jwtRecoveryHandler;

  // ============================================================
  // ACTIVITY METRICS
  // ============================================================

  @override
  Future<ActivityMetrics> fetchActivityMetrics(DateRange dateRange) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      debugPrint('AnalyticsRepository: Fetching activity metrics...');

      final results = await Future.wait([
        fetchShipmentsByStatus(dateRange),
        fetchDailyShipments(dateRange),
        fetchDailyActiveUsers(dateRange),
        fetchUserStats(),
        fetchBidStats(dateRange),
      ]);

      final bidStats = results[4] as Map<String, dynamic>;

      return ActivityMetrics(
        shipmentsByStatus: results[0] as ShipmentsByStatus,
        dailyShipments: results[1] as List<DailyShipments>,
        dailyActiveUsers: results[2] as List<DailyActiveUsers>,
        userStats: results[3] as UserStats,
        totalBids: bidStats['total_bids'] as int? ?? 0,
        avgBidsPerShipment: bidStats['avg_bids_per_shipment'] as double? ?? 0,
        bidAcceptanceRate: bidStats['bid_acceptance_rate'] as double? ?? 0,
      );
    });
  }

  @override
  Future<ShipmentsByStatus> fetchShipmentsByStatus(DateRange dateRange) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        final response = await _supabaseClient
            .from('freight_posts')
            .select('status')
            .gte('created_at', dateRange.startDate.toIso8601String())
            .lte('created_at', dateRange.endDate.toIso8601String());

        final shipments = response as List;
        
        int bidding = 0, pickup = 0, onRoute = 0, delivered = 0, cancelled = 0;
        
        for (final shipment in shipments) {
          switch (shipment['status']) {
            case 'Bidding':
              bidding++;
              break;
            case 'Pickup':
              pickup++;
              break;
            case 'OnRoute':
              onRoute++;
              break;
            case 'Delivered':
              delivered++;
              break;
            case 'Cancelled':
              cancelled++;
              break;
          }
        }

        return ShipmentsByStatus(
          bidding: bidding,
          pickup: pickup,
          onRoute: onRoute,
          delivered: delivered,
          cancelled: cancelled,
        );
      } catch (e) {
        debugPrint('AnalyticsRepository: Error fetching shipments by status: $e');
        return const ShipmentsByStatus();
      }
    });
  }

  @override
  Future<List<DailyShipments>> fetchDailyShipments(DateRange dateRange) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        final dailyData = <DailyShipments>[];
        var currentDate = DateTime(
          dateRange.startDate.year,
          dateRange.startDate.month,
          dateRange.startDate.day,
        );
        final endDate = DateTime(
          dateRange.endDate.year,
          dateRange.endDate.month,
          dateRange.endDate.day,
        );

        while (!currentDate.isAfter(endDate)) {
          final nextDate = currentDate.add(const Duration(days: 1));

          final response = await _supabaseClient
              .from('freight_posts')
              .select('status')
              .gte('created_at', currentDate.toIso8601String())
              .lt('created_at', nextDate.toIso8601String());

          final shipments = response as List;
          int count = shipments.length;
          int bidding = 0;
          int pickup = 0;
          int onRoute = 0;
          int delivered = 0;
          int cancelled = 0;

          for (final s in shipments) {
            switch (s['status']) {
              case 'Bidding':
                bidding++;
                break;
              case 'Pickup':
                pickup++;
                break;
              case 'OnRoute':
                onRoute++;
                break;
              case 'Delivered':
                delivered++;
                break;
              case 'Cancelled':
                cancelled++;
                break;
            }
          }

          dailyData.add(DailyShipments(
            date: currentDate,
            count: count,
            bidding: bidding,
            pickup: pickup,
            onRoute: onRoute,
            delivered: delivered,
            cancelled: cancelled,
          ));

          currentDate = nextDate;
        }

        return dailyData;
      } catch (e) {
        debugPrint('AnalyticsRepository: Error fetching daily shipments: $e');
        return [];
      }
    });
  }

  @override
  Future<List<DailyActiveUsers>> fetchDailyActiveUsers(DateRange dateRange) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        final dailyData = <DailyActiveUsers>[];
        var currentDate = DateTime(
          dateRange.startDate.year,
          dateRange.startDate.month,
          dateRange.startDate.day,
        );
        final endDate = DateTime(
          dateRange.endDate.year,
          dateRange.endDate.month,
          dateRange.endDate.day,
        );

        while (!currentDate.isAfter(endDate)) {
          final nextDate = currentDate.add(const Duration(days: 1));

          final response = await _supabaseClient
              .from('users')
              .select('id, role')
              .gte('last_login_at', currentDate.toIso8601String())
              .lt('last_login_at', nextDate.toIso8601String());

          final users = response as List;
          int drivers = 0;
          int shippers = 0;

          for (final user in users) {
            if (user['role'] == 'Driver') {
              drivers++;
            } else {
              shippers++;
            }
          }

          dailyData.add(DailyActiveUsers(
            date: currentDate,
            totalUsers: users.length,
            drivers: drivers,
            shippers: shippers,
          ));

          currentDate = nextDate;
        }

        return dailyData;
      } catch (e) {
        debugPrint('AnalyticsRepository: Error fetching daily active users: $e');
        return [];
      }
    });
  }

  @override
  Future<UserStats> fetchUserStats() async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final weekAgo = today.subtract(const Duration(days: 7));

        // Total users
        final usersResponse = await _supabaseClient
            .from('users')
            .select('id, role');
        final users = usersResponse as List;

        // Verified drivers
        final driversResponse = await _supabaseClient
            .from('drivers')
            .select('id')
            .eq('is_verified', true);

        // Active users today
        final activeResponse = await _supabaseClient
            .from('users')
            .select('id')
            .gte('last_login_at', today.toIso8601String());

        // New users this week
        final newUsersResponse = await _supabaseClient
            .from('users')
            .select('id')
            .gte('created_at', weekAgo.toIso8601String());

        int drivers = 0;
        int shippers = 0;
        for (final user in users) {
          if (user['role'] == 'Driver') {
            drivers++;
          } else {
            shippers++;
          }
        }

        return UserStats(
          totalUsers: users.length,
          totalDrivers: drivers,
          totalShippers: shippers,
          verifiedDrivers: (driversResponse as List).length,
          activeUsersToday: (activeResponse as List).length,
          newUsersThisWeek: (newUsersResponse as List).length,
        );
      } catch (e) {
        debugPrint('AnalyticsRepository: Error fetching user stats: $e');
        return const UserStats();
      }
    });
  }

  @override
  Future<Map<String, dynamic>> fetchBidStats(DateRange dateRange) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        final bidsResponse = await _supabaseClient
            .from('bids')
            .select('id, status, freight_post_id')
            .gte('created_at', dateRange.startDate.toIso8601String())
            .lte('created_at', dateRange.endDate.toIso8601String());

        final bids = bidsResponse as List;
        final freightPostIds = <String>{};
        int acceptedBids = 0;

        for (final bid in bids) {
          freightPostIds.add(bid['freight_post_id'] as String);
          if (bid['status'] == 'Accepted') acceptedBids++;
        }

        final avgBidsPerShipment = freightPostIds.isEmpty
            ? 0.0
            : bids.length / freightPostIds.length;

        final bidAcceptanceRate = bids.isEmpty
            ? 0.0
            : (acceptedBids / bids.length) * 100;

        return {
          'total_bids': bids.length,
          'avg_bids_per_shipment': avgBidsPerShipment,
          'bid_acceptance_rate': bidAcceptanceRate,
        };
      } catch (e) {
        debugPrint('AnalyticsRepository: Error fetching bid stats: $e');
        return {
          'total_bids': 0,
          'avg_bids_per_shipment': 0.0,
          'bid_acceptance_rate': 0.0,
        };
      }
    });
  }

  // ============================================================
  // FINANCIAL METRICS
  // ============================================================

  @override
  Future<FinancialMetrics> fetchFinancialMetrics(DateRange dateRange) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      debugPrint('AnalyticsRepository: Fetching financial metrics...');

      final results = await Future.wait([
        fetchRevenueSummary(dateRange),
        fetchPaymentsByStatus(dateRange),
        fetchDailyRevenue(dateRange),
        fetchTopDrivers(dateRange: dateRange, limit: 5),
        fetchTopShippers(dateRange: dateRange, limit: 5),
      ]);

      final paymentsByStatus = results[1] as PaymentsByStatus;
      final totalPayments = paymentsByStatus.total;
      final successRate = totalPayments > 0
          ? (paymentsByStatus.completed / totalPayments) * 100
          : 0.0;

      return FinancialMetrics(
        revenueSummary: results[0] as RevenueSummary,
        paymentsByStatus: paymentsByStatus,
        dailyRevenue: results[2] as List<DailyRevenue>,
        topDrivers: results[3] as List<TopEarner>,
        topShippers: results[4] as List<TopEarner>,
        paymentSuccessRate: successRate,
        failedPaymentsCount: 0, // Would need separate query
        outstandingPayments: paymentsByStatus.pending,
      );
    });
  }

  @override
  Future<RevenueSummary> fetchRevenueSummary(DateRange dateRange) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final weekStart = today.subtract(const Duration(days: 7));
        final monthStart = DateTime(now.year, now.month, 1);

        // Get payments in date range
        final response = await _supabaseClient
            .from('payments')
            .select('amount, total_commission, created_at')
            .eq('status', 'completed')
            .gte('created_at', dateRange.startDate.toIso8601String())
            .lte('created_at', dateRange.endDate.toIso8601String());

        final payments = response as List;
        double totalRevenue = 0;
        double totalCommission = 0;
        double todayRevenue = 0;
        double weekRevenue = 0;
        double monthRevenue = 0;

        for (final payment in payments) {
          final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
          final commission = (payment['total_commission'] as num?)?.toDouble() ?? 0;
          final createdAt = DateTime.tryParse(payment['created_at'] as String? ?? '');

          totalRevenue += amount;
          totalCommission += commission;

          if (createdAt != null) {
            if (createdAt.isAfter(today)) {
              todayRevenue += amount;
            }
            if (createdAt.isAfter(weekStart)) {
              weekRevenue += amount;
            }
            if (createdAt.isAfter(monthStart)) {
              monthRevenue += amount;
            }
          }
        }

        final avgValue = payments.isEmpty ? 0.0 : totalRevenue / payments.length;

        return RevenueSummary(
          totalRevenue: totalRevenue,
          totalCommission: totalCommission,
          averageTransactionValue: avgValue,
          totalTransactions: payments.length,
          revenueGrowth: 0, // Would need historical comparison
          todayRevenue: todayRevenue,
          thisWeekRevenue: weekRevenue,
          thisMonthRevenue: monthRevenue,
        );
      } catch (e) {
        debugPrint('AnalyticsRepository: Error fetching revenue summary: $e');
        return const RevenueSummary();
      }
    });
  }

  @override
  Future<PaymentsByStatus> fetchPaymentsByStatus(DateRange dateRange) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        final response = await _supabaseClient
            .from('payments')
            .select('status, amount')
            .gte('created_at', dateRange.startDate.toIso8601String())
            .lte('created_at', dateRange.endDate.toIso8601String());

        final payments = response as List;
        double pending = 0, completed = 0, failed = 0, refunded = 0;

        for (final payment in payments) {
          final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
          switch (payment['status']) {
            case 'pending':
              pending += amount;
              break;
            case 'completed':
              completed += amount;
              break;
            case 'failed':
              failed += amount;
              break;
            case 'refunded':
              refunded += amount;
              break;
          }
        }

        return PaymentsByStatus(
          pending: pending,
          completed: completed,
          failed: failed,
          refunded: refunded,
        );
      } catch (e) {
        debugPrint('AnalyticsRepository: Error fetching payments by status: $e');
        return const PaymentsByStatus();
      }
    });
  }

  @override
  Future<List<DailyRevenue>> fetchDailyRevenue(DateRange dateRange) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        final dailyData = <DailyRevenue>[];
        var currentDate = DateTime(
          dateRange.startDate.year,
          dateRange.startDate.month,
          dateRange.startDate.day,
        );
        final endDate = DateTime(
          dateRange.endDate.year,
          dateRange.endDate.month,
          dateRange.endDate.day,
        );

        while (!currentDate.isAfter(endDate)) {
          final nextDate = currentDate.add(const Duration(days: 1));

          final response = await _supabaseClient
              .from('payments')
              .select('amount, total_commission')
              .eq('status', 'completed')
              .gte('created_at', currentDate.toIso8601String())
              .lt('created_at', nextDate.toIso8601String());

          final payments = response as List;
          double revenue = 0;
          double commission = 0;

          for (final p in payments) {
            revenue += (p['amount'] as num?)?.toDouble() ?? 0;
            commission += (p['total_commission'] as num?)?.toDouble() ?? 0;
          }

          dailyData.add(DailyRevenue(
            date: currentDate,
            revenue: revenue,
            commission: commission,
            transactionCount: payments.length,
          ));

          currentDate = nextDate;
        }

        return dailyData;
      } catch (e) {
        debugPrint('AnalyticsRepository: Error fetching daily revenue: $e');
        return [];
      }
    });
  }

  @override
  Future<List<TopEarner>> fetchTopDrivers({
    required DateRange dateRange,
    int limit = 10,
  }) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        // This is a simplified query - in production you might use an RPC function
        final response = await _supabaseClient
            .from('driver_payouts')
            .select('driver_id, net_amount')
            .eq('status', 'success')
            .gte('created_at', dateRange.startDate.toIso8601String())
            .lte('created_at', dateRange.endDate.toIso8601String());

        final payouts = response as List;
        final earningsByDriver = <String, double>{};

        for (final payout in payouts) {
          final driverId = payout['driver_id'] as String?;
          final amount = (payout['net_amount'] as num?)?.toDouble() ?? 0;
          if (driverId != null) {
            earningsByDriver[driverId] = (earningsByDriver[driverId] ?? 0) + amount;
          }
        }

        // Sort by earnings and take top N
        final sortedDrivers = earningsByDriver.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final topDrivers = <TopEarner>[];
        for (var i = 0; i < sortedDrivers.length && i < limit; i++) {
          final entry = sortedDrivers[i];
          // Fetch driver name
          try {
            final userResponse = await _supabaseClient
                .from('users')
                .select('first_name, last_name')
                .eq('id', entry.key)
                .maybeSingle();

            final name = userResponse != null
                ? '${userResponse['first_name'] ?? ''} ${userResponse['last_name'] ?? ''}'.trim()
                : 'Unknown';

            topDrivers.add(TopEarner(
              id: entry.key,
              name: name.isEmpty ? 'Unknown' : name,
              type: 'driver',
              totalEarnings: entry.value,
            ));
          } catch (_) {
            topDrivers.add(TopEarner(
              id: entry.key,
              name: 'Unknown',
              type: 'driver',
              totalEarnings: entry.value,
            ));
          }
        }

        return topDrivers;
      } catch (e) {
        debugPrint('AnalyticsRepository: Error fetching top drivers: $e');
        return [];
      }
    });
  }

  @override
  Future<List<TopEarner>> fetchTopShippers({
    required DateRange dateRange,
    int limit = 10,
  }) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        final response = await _supabaseClient
            .from('payments')
            .select('shipper_id, amount')
            .eq('status', 'completed')
            .gte('created_at', dateRange.startDate.toIso8601String())
            .lte('created_at', dateRange.endDate.toIso8601String());

        final payments = response as List;
        final spendingByShipper = <String, double>{};

        for (final payment in payments) {
          final shipperId = payment['shipper_id'] as String?;
          final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
          if (shipperId != null) {
            spendingByShipper[shipperId] = (spendingByShipper[shipperId] ?? 0) + amount;
          }
        }

        final sortedShippers = spendingByShipper.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final topShippers = <TopEarner>[];
        for (var i = 0; i < sortedShippers.length && i < limit; i++) {
          final entry = sortedShippers[i];
          try {
            final userResponse = await _supabaseClient
                .from('users')
                .select('first_name, last_name')
                .eq('id', entry.key)
                .maybeSingle();

            final name = userResponse != null
                ? '${userResponse['first_name'] ?? ''} ${userResponse['last_name'] ?? ''}'.trim()
                : 'Unknown';

            topShippers.add(TopEarner(
              id: entry.key,
              name: name.isEmpty ? 'Unknown' : name,
              type: 'shipper',
              totalEarnings: entry.value,
            ));
          } catch (_) {
            topShippers.add(TopEarner(
              id: entry.key,
              name: 'Unknown',
              type: 'shipper',
              totalEarnings: entry.value,
            ));
          }
        }

        return topShippers;
      } catch (e) {
        debugPrint('AnalyticsRepository: Error fetching top shippers: $e');
        return [];
      }
    });
  }

  // ============================================================
  // PERFORMANCE METRICS
  // ============================================================

  @override
  Future<PerformanceMetrics> fetchPerformanceMetrics(DateRange dateRange) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      debugPrint('AnalyticsRepository: Fetching performance metrics...');

      final results = await Future.wait([
        fetchRatingsDistribution(dateRange),
        fetchTimeMetrics(dateRange),
        fetchDriverPerformance(),
        fetchPlatformHealth(),
        fetchLowRatedDrivers(),
        fetchLowRatedShippers(),
      ]);

      return PerformanceMetrics(
        ratingsDistribution: results[0] as RatingsDistribution,
        timeMetrics: results[1] as TimeMetrics,
        driverPerformance: results[2] as DriverPerformance,
        platformHealth: results[3] as PlatformHealth,
        lowRatedDrivers: results[4] as List<LowRatedUser>,
        lowRatedShippers: results[5] as List<LowRatedUser>,
      );
    });
  }

  @override
  Future<RatingsDistribution> fetchRatingsDistribution(DateRange dateRange) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        final response = await _supabaseClient
            .from('ratings')
            .select('score')
            .gte('created_at', dateRange.startDate.toIso8601String())
            .lte('created_at', dateRange.endDate.toIso8601String());

        final ratings = response as List;
        int oneStar = 0, twoStar = 0, threeStar = 0, fourStar = 0, fiveStar = 0;

        for (final rating in ratings) {
          switch (rating['score']) {
            case 1:
              oneStar++;
              break;
            case 2:
              twoStar++;
              break;
            case 3:
              threeStar++;
              break;
            case 4:
              fourStar++;
              break;
            case 5:
              fiveStar++;
              break;
          }
        }

        return RatingsDistribution(
          oneStar: oneStar,
          twoStar: twoStar,
          threeStar: threeStar,
          fourStar: fourStar,
          fiveStar: fiveStar,
        );
      } catch (e) {
        debugPrint('AnalyticsRepository: Error fetching ratings distribution: $e');
        return const RatingsDistribution();
      }
    });
  }

  @override
  Future<TimeMetrics> fetchTimeMetrics(DateRange dateRange) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        // Get delivered shipments to calculate delivery times
        final response = await _supabaseClient
            .from('freight_posts')
            .select('created_at, updated_at')
            .eq('status', 'Delivered')
            .gte('updated_at', dateRange.startDate.toIso8601String())
            .lte('updated_at', dateRange.endDate.toIso8601String());

        final shipments = response as List;
        double totalDeliveryHours = 0;
        int validCount = 0;

        for (final shipment in shipments) {
          final createdAt = DateTime.tryParse(shipment['created_at'] as String? ?? '');
          final deliveredAt = DateTime.tryParse(shipment['updated_at'] as String? ?? '');

          if (createdAt != null && deliveredAt != null) {
            final hours = deliveredAt.difference(createdAt).inMinutes / 60.0;
            totalDeliveryHours += hours;
            validCount++;
          }
        }

        final avgDeliveryTime = validCount > 0 ? totalDeliveryHours / validCount : 0.0;

        return TimeMetrics(
          averageDeliveryTimeHours: avgDeliveryTime,
          averagePickupTimeHours: 0, // Would need more specific tracking
          averageResponseTimeMinutes: 0,
          onTimeDeliveryRate: 0,
          averageTimeToAcceptBidMinutes: 0,
        );
      } catch (e) {
        debugPrint('AnalyticsRepository: Error fetching time metrics: $e');
        return const TimeMetrics();
      }
    });
  }

  @override
  Future<DriverPerformance> fetchDriverPerformance() async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        // Get all ratings for drivers
        final ratingsResponse = await _supabaseClient
            .from('ratings')
            .select('rated_user_id, score');

        final ratings = ratingsResponse as List;
        if (ratings.isEmpty) {
          return const DriverPerformance();
        }

        // Calculate average rating per driver
        final ratingsByDriver = <String, List<int>>{};
        for (final rating in ratings) {
          final driverId = rating['rated_user_id'] as String?;
          final score = rating['score'] as int?;
          if (driverId != null && score != null) {
            ratingsByDriver.putIfAbsent(driverId, () => []).add(score);
          }
        }

        double totalAvg = 0;
        int topRated = 0;
        int lowRated = 0;

        for (final entry in ratingsByDriver.entries) {
          final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
          totalAvg += avg;
          if (avg >= 4.5) topRated++;
          if (avg < 3.0) lowRated++;
        }

        final overallAvg = ratingsByDriver.isEmpty
            ? 0.0
            : totalAvg / ratingsByDriver.length;

        return DriverPerformance(
          averageRating: overallAvg,
          topRatedCount: topRated,
          lowRatedCount: lowRated,
          deliverySuccessRate: 0, // Would need more data
          complaintRate: 0,
        );
      } catch (e) {
        debugPrint('AnalyticsRepository: Error fetching driver performance: $e');
        return const DriverPerformance();
      }
    });
  }

  @override
  Future<PlatformHealth> fetchPlatformHealth() async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        // Get shipment stats
        final shipmentsResponse = await _supabaseClient
            .from('freight_posts')
            .select('status');

        final shipments = shipmentsResponse as List;
        int delivered = 0;
        int cancelled = 0;

        for (final s in shipments) {
          if (s['status'] == 'Delivered') delivered++;
          if (s['status'] == 'Cancelled') cancelled++;
        }

        final total = shipments.length;
        final successRate = total > 0 ? (delivered / total) * 100 : 0.0;
        final cancellationRate = total > 0 ? (cancelled / total) * 100 : 0.0;

        // Get dispute count
        int disputeCount = 0;
        try {
          final disputesResponse = await _supabaseClient
              .from('disputes')
              .select('id')
              .inFilter('status', ['open', 'under_review']);
          disputeCount = (disputesResponse as List).length;
        } catch (_) {}

        // Get average rating for satisfaction score
        final ratingsResponse = await _supabaseClient
            .from('ratings')
            .select('score');
        final ratings = ratingsResponse as List;
        double satisfactionScore = 0;
        if (ratings.isNotEmpty) {
          double total = 0;
          for (final r in ratings) {
            total += (r['score'] as num?)?.toDouble() ?? 0;
          }
          satisfactionScore = (total / ratings.length) * 20; // Convert 5-star to 100%
        }

        return PlatformHealth(
          overallSuccessRate: successRate,
          customerSatisfactionScore: satisfactionScore,
          issueResolutionTimeHours: 0,
          activeDisputesCount: disputeCount,
          cancellationRate: cancellationRate,
        );
      } catch (e) {
        debugPrint('AnalyticsRepository: Error fetching platform health: $e');
        return const PlatformHealth();
      }
    });
  }

  @override
  Future<List<LowRatedUser>> fetchLowRatedDrivers({double threshold = 3.0}) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        // Get drivers with their average ratings
        final ratingsResponse = await _supabaseClient
            .from('ratings')
            .select('rated_user_id, score');

        final ratings = ratingsResponse as List;
        final ratingsByUser = <String, List<int>>{};

        for (final rating in ratings) {
          final userId = rating['rated_user_id'] as String?;
          final score = rating['score'] as int?;
          if (userId != null && score != null) {
            ratingsByUser.putIfAbsent(userId, () => []).add(score);
          }
        }

        final lowRatedUsers = <LowRatedUser>[];

        for (final entry in ratingsByUser.entries) {
          final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
          if (avg < threshold) {
            try {
              final userResponse = await _supabaseClient
                  .from('users')
                  .select('first_name, last_name, role')
                  .eq('id', entry.key)
                  .maybeSingle();

              if (userResponse != null && userResponse['role'] == 'Driver') {
                final name = '${userResponse['first_name'] ?? ''} ${userResponse['last_name'] ?? ''}'.trim();
                lowRatedUsers.add(LowRatedUser(
                  id: entry.key,
                  name: name.isEmpty ? 'Unknown' : name,
                  type: 'driver',
                  averageRating: avg,
                  totalRatings: entry.value.length,
                ));
              }
            } catch (_) {}
          }
        }

        lowRatedUsers.sort((a, b) => a.averageRating.compareTo(b.averageRating));
        return lowRatedUsers.take(10).toList();
      } catch (e) {
        debugPrint('AnalyticsRepository: Error fetching low-rated drivers: $e');
        return [];
      }
    });
  }

  @override
  Future<List<LowRatedUser>> fetchLowRatedShippers({double threshold = 3.0}) async {
    return _jwtRecoveryHandler.executeWithRecovery(() async {
      try {
        final ratingsResponse = await _supabaseClient
            .from('ratings')
            .select('rated_user_id, score');

        final ratings = ratingsResponse as List;
        final ratingsByUser = <String, List<int>>{};

        for (final rating in ratings) {
          final userId = rating['rated_user_id'] as String?;
          final score = rating['score'] as int?;
          if (userId != null && score != null) {
            ratingsByUser.putIfAbsent(userId, () => []).add(score);
          }
        }

        final lowRatedUsers = <LowRatedUser>[];

        for (final entry in ratingsByUser.entries) {
          final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
          if (avg < threshold) {
            try {
              final userResponse = await _supabaseClient
                  .from('users')
                  .select('first_name, last_name, role')
                  .eq('id', entry.key)
                  .maybeSingle();

              if (userResponse != null && userResponse['role'] == 'Shipper') {
                final name = '${userResponse['first_name'] ?? ''} ${userResponse['last_name'] ?? ''}'.trim();
                lowRatedUsers.add(LowRatedUser(
                  id: entry.key,
                  name: name.isEmpty ? 'Unknown' : name,
                  type: 'shipper',
                  averageRating: avg,
                  totalRatings: entry.value.length,
                ));
              }
            } catch (_) {}
          }
        }

        lowRatedUsers.sort((a, b) => a.averageRating.compareTo(b.averageRating));
        return lowRatedUsers.take(10).toList();
      } catch (e) {
        debugPrint('AnalyticsRepository: Error fetching low-rated shippers: $e');
        return [];
      }
    });
  }
}
