// lib/features/dashboard/presentation/providers/dashboard_providers.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/core_providers.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';

// ============================================================
// DASHBOARD STATE
// ============================================================

/// Default auto-refresh interval
const kDefaultRefreshInterval = Duration(minutes: 5);

/// Time period for cycling stat cards
enum StatPeriod {
  day,
  week,
  month,
  year,
  total;

  String get suffix {
    switch (this) {
      case StatPeriod.day:
        return '(D)';
      case StatPeriod.week:
        return '(W)';
      case StatPeriod.month:
        return '(M)';
      case StatPeriod.year:
        return '(Y)';
      case StatPeriod.total:
        return '';
    }
  }

  StatPeriod get next {
    switch (this) {
      case StatPeriod.day:
        return StatPeriod.week;
      case StatPeriod.week:
        return StatPeriod.month;
      case StatPeriod.month:
        return StatPeriod.year;
      case StatPeriod.year:
        return StatPeriod.total;
      case StatPeriod.total:
        return StatPeriod.day;
    }
  }

  DateTime startDate(DateTime now) {
    switch (this) {
      case StatPeriod.day:
        return DateTime(now.year, now.month, now.day);
      case StatPeriod.week:
        return now.subtract(const Duration(days: 7));
      case StatPeriod.month:
        return now.subtract(const Duration(days: 30));
      case StatPeriod.year:
        return now.subtract(const Duration(days: 365));
      case StatPeriod.total:
        return DateTime(2000);
    }
  }
}

/// Which stat card is being cycled
enum StatMetric { revenue, shipments, registrations, activeUsers }

/// Cached value + sparkline for a single period
class PeriodCache {
  final double value;
  final List<TrendDataPoint> sparkline;

  const PeriodCache({required this.value, required this.sparkline});
}

/// Holds period-cycling state for a single stat card
class PeriodStatData {
  final StatPeriod period;
  final double? value;
  final List<TrendDataPoint> sparkline;
  final bool isLoading;
  final Map<StatPeriod, PeriodCache> cache;

  const PeriodStatData({
    this.period = StatPeriod.day,
    this.value,
    this.sparkline = const [],
    this.isLoading = false,
    this.cache = const {},
  });

  PeriodStatData copyWith({
    StatPeriod? period,
    double? value,
    List<TrendDataPoint>? sparkline,
    bool? isLoading,
    bool clearValue = false,
    Map<StatPeriod, PeriodCache>? cache,
  }) {
    return PeriodStatData(
      period: period ?? this.period,
      value: clearValue ? null : (value ?? this.value),
      sparkline: sparkline ?? this.sparkline,
      isLoading: isLoading ?? this.isLoading,
      cache: cache ?? this.cache,
    );
  }
}

/// State class for dashboard
class DashboardState {
  final DashboardStats stats;
  final bool isLoading;
  final bool isLoadingTrends;
  final String? error;
  final DateTime? lastRefresh;
  final Duration refreshInterval;
  final PeriodStatData revenuePeriodData;
  final PeriodStatData shipmentsPeriodData;
  final PeriodStatData registrationsPeriodData;
  final PeriodStatData activeUsersPeriodData;

  const DashboardState({
    required this.stats,
    this.isLoading = false,
    this.isLoadingTrends = false,
    this.error,
    this.lastRefresh,
    this.refreshInterval = const Duration(minutes: 5),
    this.revenuePeriodData = const PeriodStatData(),
    this.shipmentsPeriodData = const PeriodStatData(),
    this.registrationsPeriodData = const PeriodStatData(),
    this.activeUsersPeriodData = const PeriodStatData(),
  });

  factory DashboardState.initial() {
    return DashboardState(
      stats: DashboardStats.empty(),
      isLoading: true,
      isLoadingTrends: true,
    );
  }

  DashboardState copyWith({
    DashboardStats? stats,
    bool? isLoading,
    bool? isLoadingTrends,
    String? error,
    DateTime? lastRefresh,
    Duration? refreshInterval,
    PeriodStatData? revenuePeriodData,
    PeriodStatData? shipmentsPeriodData,
    PeriodStatData? registrationsPeriodData,
    PeriodStatData? activeUsersPeriodData,
  }) {
    return DashboardState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      isLoadingTrends: isLoadingTrends ?? this.isLoadingTrends,
      error: error,
      lastRefresh: lastRefresh ?? this.lastRefresh,
      refreshInterval: refreshInterval ?? this.refreshInterval,
      revenuePeriodData: revenuePeriodData ?? this.revenuePeriodData,
      shipmentsPeriodData: shipmentsPeriodData ?? this.shipmentsPeriodData,
      registrationsPeriodData:
          registrationsPeriodData ?? this.registrationsPeriodData,
      activeUsersPeriodData:
          activeUsersPeriodData ?? this.activeUsersPeriodData,
    );
  }

  /// Get period data for a specific metric
  PeriodStatData periodDataFor(StatMetric metric) {
    switch (metric) {
      case StatMetric.revenue:
        return revenuePeriodData;
      case StatMetric.shipments:
        return shipmentsPeriodData;
      case StatMetric.registrations:
        return registrationsPeriodData;
      case StatMetric.activeUsers:
        return activeUsersPeriodData;
    }
  }

  bool get hasError => error != null;
  bool get hasData => !isLoading && stats != DashboardStats.empty();
}

// ============================================================
// DASHBOARD NOTIFIER
// ============================================================

/// StateNotifier for dashboard state management
class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;
  final ConnectivityService _connectivity;
  Timer? _autoRefreshTimer;

  DashboardNotifier(this._repository, this._connectivity)
      : super(DashboardState.initial()) {
    // Auto-load stats on init
    loadStats();
    // Auto-refresh today's stats (WiFi-only)
    _startTimer(kDefaultRefreshInterval);
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startTimer(Duration interval) {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      interval,
      (_) => _autoRefreshIfWifi(),
    );
  }

  Future<void> _autoRefreshIfWifi() async {
    final onWifi = await _connectivity.isOnWifi();
    if (!onWifi) {
      debugPrint('DashboardNotifier: Skipping auto-refresh (not on WiFi)');
      return;
    }
    await quickRefresh();
  }

  /// Load all dashboard stats including trends.
  /// Phase 1: today's stats (fast). Phase 2: trends + weekly (parallel, background).
  Future<void> loadStats() async {
    if (!mounted) return;
    debugPrint('DashboardNotifier: Loading stats...');

    state = state.copyWith(isLoading: true, isLoadingTrends: true, error: null);

    try {
      // Phase 1: Load today's stats quickly
      final todayStats = await _repository.fetchTodayStats();
      if (!mounted) return;
      state = state.copyWith(
        stats: state.stats.copyWith(
          activeShipments: todayStats.activeShipments,
          pendingDriverApprovals: todayStats.pendingDriverApprovals,
          newRegistrationsToday: todayStats.newRegistrationsToday,
          activeUsers24h: todayStats.activeUsers24h,
          revenueToday: todayStats.revenueToday,
          pendingDisputes: todayStats.pendingDisputes,
        ),
        isLoading: false,
      );

      // Phase 2: Load trends + weekly in parallel (no duplicate today-stats fetch)
      final results = await Future.wait([
        _repository.fetchTrends(),
        _repository.fetchWeeklyStats(),
      ]);
      if (!mounted) return;

      final trends = results[0] as Map<String, TrendIndicator>;
      final weeklyStats = results[1] as WeeklyStats;

      state = state.copyWith(
        stats: state.stats.copyWith(
          weeklyStats: weeklyStats,
          activeShipmentsTrend:
              trends['active_shipments'] ?? TrendIndicator.empty(),
          pendingApprovalsTrend:
              trends['pending_approvals'] ?? TrendIndicator.empty(),
          registrationsTrend:
              trends['registrations'] ?? TrendIndicator.empty(),
          activeUsersTrend:
              trends['active_users'] ?? TrendIndicator.empty(),
          revenueTrend: trends['revenue'] ?? TrendIndicator.empty(),
          disputesTrend: trends['disputes'] ?? TrendIndicator.empty(),
          completedShipmentsTrend:
              trends['completed_shipments'] ?? TrendIndicator.empty(),
        ),
        isLoadingTrends: false,
        lastRefresh: DateTime.now(),
      );

      debugPrint('DashboardNotifier: Stats loaded successfully');
    } catch (e) {
      debugPrint('DashboardNotifier: Error loading stats: $e');
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingTrends: false,
        error: 'Failed to load dashboard stats: ${e.toString()}',
      );
    }
  }

  /// Quick refresh - reload today's stats and invalidate period caches.
  /// Cached period data is cleared so the next cycle tap fetches fresh values.
  /// If a card is currently showing a non-day period, re-fetch that period.
  /// Skips if already loading (concurrency guard).
  Future<void> quickRefresh() async {
    if (state.isLoading || !mounted) return;
    debugPrint('DashboardNotifier: Quick refresh...');

    state = state.copyWith(isLoading: true, error: null);

    try {
      final todayStats = await _repository.fetchTodayStats();
      if (!mounted) return;

      // Invalidate all period caches (keep current period selection + display value)
      state = state.copyWith(
        stats: state.stats.copyWith(
          activeShipments: todayStats.activeShipments,
          pendingDriverApprovals: todayStats.pendingDriverApprovals,
          newRegistrationsToday: todayStats.newRegistrationsToday,
          activeUsers24h: todayStats.activeUsers24h,
          revenueToday: todayStats.revenueToday,
          pendingDisputes: todayStats.pendingDisputes,
        ),
        isLoading: false,
        lastRefresh: DateTime.now(),
        revenuePeriodData: state.revenuePeriodData.copyWith(cache: const {}),
        shipmentsPeriodData:
            state.shipmentsPeriodData.copyWith(cache: const {}),
        registrationsPeriodData:
            state.registrationsPeriodData.copyWith(cache: const {}),
        activeUsersPeriodData:
            state.activeUsersPeriodData.copyWith(cache: const {}),
      );

      // Re-fetch any cards currently showing a non-day period
      await _refreshActivePeriodsInBackground();
    } catch (e) {
      debugPrint('DashboardNotifier: Error in quick refresh: $e');
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to refresh: ${e.toString()}',
      );
    }
  }

  /// Re-fetch data for any metric currently on a non-day period.
  /// Runs in background so the UI stays responsive.
  Future<void> _refreshActivePeriodsInBackground() async {
    final refreshFutures = <Future<void>>[];
    for (final metric in StatMetric.values) {
      final data = state.periodDataFor(metric);
      if (data.period != StatPeriod.day) {
        refreshFutures.add(_refreshPeriodForMetric(metric, data.period));
      }
    }
    if (refreshFutures.isNotEmpty) {
      await Future.wait(refreshFutures);
    }
  }

  /// Fetch fresh value + sparkline for a specific metric/period and update state.
  Future<void> _refreshPeriodForMetric(
    StatMetric metric,
    StatPeriod period,
  ) async {
    try {
      final now = DateTime.now();
      final start = period.startDate(now);

      final results = await Future.wait([
        _fetchValueForPeriod(metric, start, now),
        _fetchSparklineForPeriod(metric, start, now),
      ]);

      if (!mounted) return;

      final fetchedValue = results[0] as double;
      final fetchedSparkline = results[1] as List<TrendDataPoint>;

      final currentData = state.periodDataFor(metric);
      final newCache = Map<StatPeriod, PeriodCache>.from(currentData.cache)
        ..[period] = PeriodCache(
          value: fetchedValue,
          sparkline: fetchedSparkline,
        );

      _updatePeriodData(
        metric,
        currentData.copyWith(
          value: fetchedValue,
          sparkline: fetchedSparkline,
          cache: newCache,
        ),
      );
    } catch (e) {
      debugPrint(
        'DashboardNotifier: Error refreshing $metric for $period: $e',
      );
    }
  }

  /// Full refresh including trends.
  /// Clears period caches so next cycle fetches fresh data.
  Future<void> fullRefresh() async {
    if (state.isLoading || state.isLoadingTrends) return;
    debugPrint('DashboardNotifier: Full refresh with trends...');
    // Reset all period selections and clear caches
    state = state.copyWith(
      revenuePeriodData: const PeriodStatData(),
      shipmentsPeriodData: const PeriodStatData(),
      registrationsPeriodData: const PeriodStatData(),
      activeUsersPeriodData: const PeriodStatData(),
    );
    await loadStats();
  }

  /// Pause auto-refresh (call when dashboard is not visible).
  void pauseAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    debugPrint('DashboardNotifier: Auto-refresh paused');
  }

  /// Resume auto-refresh (call when dashboard becomes visible).
  void resumeAutoRefresh() {
    if (_autoRefreshTimer != null) return; // already running
    _startTimer(state.refreshInterval);
    debugPrint('DashboardNotifier: Auto-refresh resumed');
  }

  /// Update the auto-refresh interval.
  void setRefreshInterval(Duration interval) {
    state = state.copyWith(refreshInterval: interval);
    if (_autoRefreshTimer != null) {
      _startTimer(interval);
    }
    debugPrint('DashboardNotifier: Refresh interval set to ${interval.inSeconds}s');
  }

  /// Refresh trends only
  Future<void> refreshTrends() async {
    debugPrint('DashboardNotifier: Refreshing trends...');

    state = state.copyWith(isLoadingTrends: true);

    try {
      final trends = await _repository.fetchTrends();
      final weeklyStats = await _repository.fetchWeeklyStats();

      state = state.copyWith(
        stats: state.stats.copyWith(
          weeklyStats: weeklyStats,
          activeShipmentsTrend:
              trends['active_shipments'] ?? TrendIndicator.empty(),
          pendingApprovalsTrend:
              trends['pending_approvals'] ?? TrendIndicator.empty(),
          registrationsTrend: trends['registrations'] ?? TrendIndicator.empty(),
          activeUsersTrend: trends['active_users'] ?? TrendIndicator.empty(),
          revenueTrend: trends['revenue'] ?? TrendIndicator.empty(),
          disputesTrend: trends['disputes'] ?? TrendIndicator.empty(),
          completedShipmentsTrend:
              trends['completed_shipments'] ?? TrendIndicator.empty(),
        ),
        isLoadingTrends: false,
      );
    } catch (e) {
      debugPrint('DashboardNotifier: Error refreshing trends: $e');
      state = state.copyWith(isLoadingTrends: false);
    }
  }

  /// Clear error
  void clearError() {
    if (state.hasError) {
      state = state.copyWith(error: null);
    }
  }

  // ============================================================
  // PERIOD CYCLING
  // ============================================================

  /// Cycle a stat card through: Day → Week → Month → Year → Total → Day
  Future<void> cyclePeriod(StatMetric metric) async {
    final current = state.periodDataFor(metric);
    if (current.isLoading) return;

    final nextPeriod = current.period.next;

    // Day period uses existing stats — no fetch needed
    if (nextPeriod == StatPeriod.day) {
      _updatePeriodData(
        metric,
        current.copyWith(
          period: nextPeriod,
          clearValue: true,
          sparkline: const [],
        ),
      );
      return;
    }

    // Check cache — skip DB query if already fetched
    final cached = current.cache[nextPeriod];
    if (cached != null) {
      _updatePeriodData(
        metric,
        current.copyWith(
          period: nextPeriod,
          value: cached.value,
          sparkline: cached.sparkline,
        ),
      );
      return;
    }

    // Fetch from DB
    _updatePeriodData(
      metric,
      current.copyWith(period: nextPeriod, isLoading: true),
    );

    try {
      final now = DateTime.now();
      final start = nextPeriod.startDate(now);

      final results = await Future.wait([
        _fetchValueForPeriod(metric, start, now),
        _fetchSparklineForPeriod(metric, start, now),
      ]);

      if (!mounted) return;

      final fetchedValue = results[0] as double;
      final fetchedSparkline = results[1] as List<TrendDataPoint>;

      // Store in cache for instant access on next visit
      final currentData = state.periodDataFor(metric);
      final newCache = Map<StatPeriod, PeriodCache>.from(currentData.cache)
        ..[nextPeriod] = PeriodCache(
          value: fetchedValue,
          sparkline: fetchedSparkline,
        );

      _updatePeriodData(
        metric,
        PeriodStatData(
          period: nextPeriod,
          value: fetchedValue,
          sparkline: fetchedSparkline,
          cache: newCache,
        ),
      );
    } catch (e) {
      debugPrint('DashboardNotifier: Error fetching $metric for period: $e');
      if (!mounted) return;
      _updatePeriodData(
        metric,
        state.periodDataFor(metric).copyWith(isLoading: false),
      );
    }
  }

  void _updatePeriodData(StatMetric metric, PeriodStatData data) {
    switch (metric) {
      case StatMetric.revenue:
        state = state.copyWith(revenuePeriodData: data);
      case StatMetric.shipments:
        state = state.copyWith(shipmentsPeriodData: data);
      case StatMetric.registrations:
        state = state.copyWith(registrationsPeriodData: data);
      case StatMetric.activeUsers:
        state = state.copyWith(activeUsersPeriodData: data);
    }
  }

  Future<double> _fetchValueForPeriod(
    StatMetric metric,
    DateTime start,
    DateTime end,
  ) async {
    switch (metric) {
      case StatMetric.revenue:
        return _repository.fetchTotalRevenue(
          startDate: start,
          endDate: end,
        );
      case StatMetric.shipments:
        final count = await _repository.fetchShipmentsInRange(
          startDate: start,
          endDate: end,
        );
        return count.toDouble();
      case StatMetric.registrations:
        final count = await _repository.fetchRegistrationsInRange(
          startDate: start,
          endDate: end,
        );
        return count.toDouble();
      case StatMetric.activeUsers:
        final count = await _repository.fetchActiveUsersInRange(
          startDate: start,
          endDate: end,
        );
        return count.toDouble();
    }
  }

  Future<List<TrendDataPoint>> _fetchSparklineForPeriod(
    StatMetric metric,
    DateTime start,
    DateTime end,
  ) async {
    if (metric == StatMetric.revenue) {
      return _repository.fetchRevenueSparkline(
        startDate: start,
        endDate: end,
        buckets: 7,
      );
    }

    final metricType = switch (metric) {
      StatMetric.shipments => 'shipments',
      StatMetric.registrations => 'registrations',
      StatMetric.activeUsers => 'active_users',
      StatMetric.revenue => 'revenue', // unreachable
    };

    return _repository.fetchCountSparkline(
      metricType: metricType,
      startDate: start,
      endDate: end,
      buckets: 7,
    );
  }
}

// ============================================================
// PROVIDERS
// ============================================================

/// Provider for DashboardRepository
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final supabaseProvider = ref.read(supabaseProviderInstance);
  final jwtHandler = ref.read(jwtRecoveryHandlerProvider);

  return DashboardRepositoryImpl(
    supabaseClient: supabaseProvider.client,
    jwtRecoveryHandler: jwtHandler,
  );
});

/// Provider for DashboardNotifier
final dashboardNotifierProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final repository = ref.read(dashboardRepositoryProvider);
  return DashboardNotifier(repository, ConnectivityService.instance);
});

// ============================================================
// CONVENIENCE PROVIDERS
// ============================================================

/// Provider for dashboard stats
final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  return ref.watch(dashboardNotifierProvider).stats;
});

/// Provider for dashboard loading state
final isDashboardLoadingProvider = Provider<bool>((ref) {
  return ref.watch(dashboardNotifierProvider).isLoading;
});

/// Provider for trends loading state
final isTrendsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(dashboardNotifierProvider).isLoadingTrends;
});

/// Provider for dashboard error
final dashboardErrorProvider = Provider<String?>((ref) {
  return ref.watch(dashboardNotifierProvider).error;
});

/// Provider for last refresh time
final dashboardLastRefreshProvider = Provider<DateTime?>((ref) {
  return ref.watch(dashboardNotifierProvider).lastRefresh;
});

/// Provider for weekly stats
final weeklyStatsProvider = Provider<WeeklyStats>((ref) {
  return ref.watch(dashboardStatsProvider).weeklyStats;
});

/// Provider for active shipments count
final activeShipmentsCountProvider = Provider<int>((ref) {
  return ref.watch(dashboardStatsProvider).activeShipments;
});

/// Provider for pending approvals count
final pendingApprovalsCountProvider = Provider<int>((ref) {
  return ref.watch(dashboardStatsProvider).pendingDriverApprovals;
});

/// Provider for new registrations today count
final newRegistrationsTodayProvider = Provider<int>((ref) {
  return ref.watch(dashboardStatsProvider).newRegistrationsToday;
});

/// Provider for active users in 24h count
final activeUsers24hProvider = Provider<int>((ref) {
  return ref.watch(dashboardStatsProvider).activeUsers24h;
});

/// Provider for today's revenue
final revenueTodayProvider = Provider<double>((ref) {
  return ref.watch(dashboardStatsProvider).revenueToday;
});

/// Provider for pending disputes count
final pendingDisputesProvider = Provider<int>((ref) {
  return ref.watch(dashboardStatsProvider).pendingDisputes;
});

// ============================================================
// TREND PROVIDERS
// ============================================================

/// Provider for revenue trend
final revenueTrendProvider = Provider<TrendIndicator>((ref) {
  return ref.watch(dashboardStatsProvider).revenueTrend;
});

/// Provider for shipments trend
final shipmentsTrendProvider = Provider<TrendIndicator>((ref) {
  return ref.watch(dashboardStatsProvider).completedShipmentsTrend;
});

/// Provider for registrations trend
final registrationsTrendProvider = Provider<TrendIndicator>((ref) {
  return ref.watch(dashboardStatsProvider).registrationsTrend;
});

/// Provider for active users trend
final activeUsersTrendProvider = Provider<TrendIndicator>((ref) {
  return ref.watch(dashboardStatsProvider).activeUsersTrend;
});
