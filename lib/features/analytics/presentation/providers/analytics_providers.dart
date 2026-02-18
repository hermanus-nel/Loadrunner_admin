// lib/features/analytics/presentation/providers/analytics_providers.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/activity_metrics.dart';
import '../../domain/entities/financial_metrics.dart';
import '../../domain/entities/performance_metrics.dart';
import '../../domain/entities/date_range.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../data/repositories/analytics_repository_impl.dart';
import '../../../../core/services/core_providers.dart';

// ============================================================
// ANALYTICS STATE
// ============================================================

/// State class for analytics
class AnalyticsState {
  final DateRange dateRange;
  final ActivityMetrics activityMetrics;
  final FinancialMetrics financialMetrics;
  final PerformanceMetrics performanceMetrics;
  final bool isLoadingActivity;
  final bool isLoadingFinancial;
  final bool isLoadingPerformance;
  final String? error;
  final DateTime? lastRefresh;

  const AnalyticsState({
    required this.dateRange,
    required this.activityMetrics,
    required this.financialMetrics,
    required this.performanceMetrics,
    this.isLoadingActivity = false,
    this.isLoadingFinancial = false,
    this.isLoadingPerformance = false,
    this.error,
    this.lastRefresh,
  });

  factory AnalyticsState.initial() {
    return AnalyticsState(
      dateRange: DateRange.last7Days(),
      activityMetrics: ActivityMetrics.empty(),
      financialMetrics: FinancialMetrics.empty(),
      performanceMetrics: PerformanceMetrics.empty(),
      isLoadingActivity: true,
      isLoadingFinancial: true,
      isLoadingPerformance: true,
    );
  }

  bool get isLoading => isLoadingActivity || isLoadingFinancial || isLoadingPerformance;
  bool get hasError => error != null;

  AnalyticsState copyWith({
    DateRange? dateRange,
    ActivityMetrics? activityMetrics,
    FinancialMetrics? financialMetrics,
    PerformanceMetrics? performanceMetrics,
    bool? isLoadingActivity,
    bool? isLoadingFinancial,
    bool? isLoadingPerformance,
    String? error,
    DateTime? lastRefresh,
  }) {
    return AnalyticsState(
      dateRange: dateRange ?? this.dateRange,
      activityMetrics: activityMetrics ?? this.activityMetrics,
      financialMetrics: financialMetrics ?? this.financialMetrics,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
      isLoadingActivity: isLoadingActivity ?? this.isLoadingActivity,
      isLoadingFinancial: isLoadingFinancial ?? this.isLoadingFinancial,
      isLoadingPerformance: isLoadingPerformance ?? this.isLoadingPerformance,
      error: error,
      lastRefresh: lastRefresh ?? this.lastRefresh,
    );
  }
}

// ============================================================
// ANALYTICS NOTIFIER
// ============================================================

/// StateNotifier for analytics state management
class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final AnalyticsRepository _repository;

  AnalyticsNotifier(this._repository) : super(AnalyticsState.initial()) {
    // Auto-load data on init
    loadAllMetrics();
  }

  /// Update date range and reload all data
  Future<void> setDateRange(DateRange dateRange) async {
    state = state.copyWith(dateRange: dateRange);
    await loadAllMetrics();
  }

  /// Load all metrics in parallel
  Future<void> loadAllMetrics() async {
    debugPrint('AnalyticsNotifier: Loading all metrics...');

    state = state.copyWith(
      isLoadingActivity: true,
      isLoadingFinancial: true,
      isLoadingPerformance: true,
      error: null,
    );

    // Load in parallel but update state as each completes
    await Future.wait([
      _loadActivityMetrics(),
      _loadFinancialMetrics(),
      _loadPerformanceMetrics(),
    ]);

    state = state.copyWith(lastRefresh: DateTime.now());
  }

  Future<void> _loadActivityMetrics() async {
    try {
      final metrics = await _repository.fetchActivityMetrics(state.dateRange);
      state = state.copyWith(
        activityMetrics: metrics,
        isLoadingActivity: false,
      );
    } catch (e) {
      debugPrint('AnalyticsNotifier: Error loading activity metrics: $e');
      state = state.copyWith(
        isLoadingActivity: false,
        error: 'Failed to load activity metrics',
      );
    }
  }

  Future<void> _loadFinancialMetrics() async {
    try {
      final metrics = await _repository.fetchFinancialMetrics(state.dateRange);
      state = state.copyWith(
        financialMetrics: metrics,
        isLoadingFinancial: false,
      );
    } catch (e) {
      debugPrint('AnalyticsNotifier: Error loading financial metrics: $e');
      state = state.copyWith(
        isLoadingFinancial: false,
        error: 'Failed to load financial metrics',
      );
    }
  }

  Future<void> _loadPerformanceMetrics() async {
    try {
      final metrics = await _repository.fetchPerformanceMetrics(state.dateRange);
      state = state.copyWith(
        performanceMetrics: metrics,
        isLoadingPerformance: false,
      );
    } catch (e) {
      debugPrint('AnalyticsNotifier: Error loading performance metrics: $e');
      state = state.copyWith(
        isLoadingPerformance: false,
        error: 'Failed to load performance metrics',
      );
    }
  }

  /// Refresh specific tab
  Future<void> refreshActivity() async {
    state = state.copyWith(isLoadingActivity: true, error: null);
    await _loadActivityMetrics();
  }

  Future<void> refreshFinancial() async {
    state = state.copyWith(isLoadingFinancial: true, error: null);
    await _loadFinancialMetrics();
  }

  Future<void> refreshPerformance() async {
    state = state.copyWith(isLoadingPerformance: true, error: null);
    await _loadPerformanceMetrics();
  }

  /// Clear error
  void clearError() {
    if (state.hasError) {
      state = state.copyWith(error: null);
    }
  }
}

// ============================================================
// PROVIDERS
// ============================================================

/// Provider for AnalyticsRepository
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final supabaseProvider = ref.read(supabaseProviderInstance);
  final jwtHandler = ref.read(jwtRecoveryHandlerProvider);

  return AnalyticsRepositoryImpl(
    supabaseClient: supabaseProvider.client,
    jwtRecoveryHandler: jwtHandler,
  );
});

/// Provider for AnalyticsNotifier
final analyticsNotifierProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  final repository = ref.read(analyticsRepositoryProvider);
  return AnalyticsNotifier(repository);
});

// ============================================================
// CONVENIENCE PROVIDERS
// ============================================================

/// Provider for current date range
final analyticsDateRangeProvider = Provider<DateRange>((ref) {
  return ref.watch(analyticsNotifierProvider).dateRange;
});

/// Provider for activity metrics
final activityMetricsProvider = Provider<ActivityMetrics>((ref) {
  return ref.watch(analyticsNotifierProvider).activityMetrics;
});

/// Provider for financial metrics
final financialMetricsProvider = Provider<FinancialMetrics>((ref) {
  return ref.watch(analyticsNotifierProvider).financialMetrics;
});

/// Provider for performance metrics
final performanceMetricsProvider = Provider<PerformanceMetrics>((ref) {
  return ref.watch(analyticsNotifierProvider).performanceMetrics;
});

/// Provider for loading states
final isLoadingActivityProvider = Provider<bool>((ref) {
  return ref.watch(analyticsNotifierProvider).isLoadingActivity;
});

final isLoadingFinancialProvider = Provider<bool>((ref) {
  return ref.watch(analyticsNotifierProvider).isLoadingFinancial;
});

final isLoadingPerformanceProvider = Provider<bool>((ref) {
  return ref.watch(analyticsNotifierProvider).isLoadingPerformance;
});

/// Provider for analytics error
final analyticsErrorProvider = Provider<String?>((ref) {
  return ref.watch(analyticsNotifierProvider).error;
});

/// Provider for last refresh time
final analyticsLastRefreshProvider = Provider<DateTime?>((ref) {
  return ref.watch(analyticsNotifierProvider).lastRefresh;
});

// ============================================================
// DERIVED DATA PROVIDERS
// ============================================================

/// Provider for shipments chart data
final shipmentsChartDataProvider = Provider<List<DailyShipments>>((ref) {
  return ref.watch(activityMetricsProvider).dailyShipments;
});

/// Provider for revenue chart data
final revenueChartDataProvider = Provider<List<DailyRevenue>>((ref) {
  return ref.watch(financialMetricsProvider).dailyRevenue;
});

/// Provider for ratings chart data
final ratingsChartDataProvider = Provider<RatingsDistribution>((ref) {
  return ref.watch(performanceMetricsProvider).ratingsDistribution;
});

/// Provider for payments pie chart data
final paymentsChartDataProvider = Provider<PaymentsByStatus>((ref) {
  return ref.watch(financialMetricsProvider).paymentsByStatus;
});
