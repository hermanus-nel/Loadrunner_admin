// lib/features/sms_usage/presentation/providers/sms_usage_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/core_providers.dart';
import '../../data/repositories/sms_usage_repository_impl.dart';
import '../../domain/repositories/sms_usage_repository.dart';

/// Repository provider
final smsUsageRepositoryProvider = Provider<SmsUsageRepository>((ref) {
  final supabase = ref.watch(supabaseProviderInstance).client;
  final jwtHandler = ref.watch(jwtRecoveryHandlerProvider);
  return SmsUsageRepositoryImpl(
    supabase: supabase,
    jwtHandler: jwtHandler,
  );
});

// ============================================================================
// SMS Usage State
// ============================================================================

class SmsUsageState {
  final List<SmsLogEntity> logs;
  final SmsLogsPagination pagination;
  final SmsLogFilters filters;
  final SmsUsageStats? stats;
  final List<DailyUsage> dailyUsage;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const SmsUsageState({
    this.logs = const [],
    this.pagination = const SmsLogsPagination(),
    this.filters = const SmsLogFilters(),
    this.stats,
    this.dailyUsage = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  SmsUsageState copyWith({
    List<SmsLogEntity>? logs,
    SmsLogsPagination? pagination,
    SmsLogFilters? filters,
    SmsUsageStats? stats,
    List<DailyUsage>? dailyUsage,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    bool clearStats = false,
  }) {
    return SmsUsageState(
      logs: logs ?? this.logs,
      pagination: pagination ?? this.pagination,
      filters: filters ?? this.filters,
      stats: clearStats ? null : (stats ?? this.stats),
      dailyUsage: dailyUsage ?? this.dailyUsage,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ============================================================================
// SMS Usage Notifier
// ============================================================================

class SmsUsageNotifier extends StateNotifier<SmsUsageState> {
  final SmsUsageRepository _repository;

  SmsUsageNotifier(this._repository) : super(const SmsUsageState());

  /// Initialize - load logs, stats, and daily usage
  Future<void> initialize() async {
    await Future.wait([
      fetchLogs(refresh: true),
      fetchStats(),
      fetchDailyUsage(),
    ]);
  }

  /// Fetch SMS logs with current filters
  Future<void> fetchLogs({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      logs: refresh ? [] : state.logs,
      pagination: refresh ? const SmsLogsPagination() : state.pagination,
    );

    final result = await _repository.fetchSmsLogs(
      filters: state.filters,
      pagination: refresh ? null : state.pagination.copyWith(page: 1),
    );

    if (result.error != null) {
      state = state.copyWith(isLoading: false, error: result.error);
      return;
    }

    state = state.copyWith(
      logs: result.logs,
      pagination: result.pagination,
      isLoading: false,
    );
  }

  /// Load more logs (pagination)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.pagination.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    final nextPage = state.pagination.page + 1;
    final result = await _repository.fetchSmsLogs(
      filters: state.filters,
      pagination: state.pagination.copyWith(page: nextPage),
    );

    if (result.error != null) {
      state = state.copyWith(isLoadingMore: false, error: result.error);
      return;
    }

    state = state.copyWith(
      logs: [...state.logs, ...result.logs],
      pagination: result.pagination,
      isLoadingMore: false,
    );
  }

  /// Fetch statistics
  Future<void> fetchStats() async {
    final result = await _repository.getSmsStats(
      startDate: state.filters.dateFrom,
      endDate: state.filters.dateTo,
    );
    if (result.stats != null) {
      state = state.copyWith(stats: result.stats);
    }
  }

  /// Fetch daily usage for chart
  Future<void> fetchDailyUsage() async {
    final result = await _repository.getDailyUsage(
      startDate: state.filters.dateFrom,
      endDate: state.filters.dateTo,
    );
    if (result.error == null) {
      state = state.copyWith(dailyUsage: result.dailyUsage);
    }
  }

  /// Update filters and refresh
  Future<void> updateFilters(SmsLogFilters filters) async {
    state = state.copyWith(filters: filters);
    await Future.wait([
      fetchLogs(refresh: true),
      fetchStats(),
      fetchDailyUsage(),
    ]);
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    state = state.copyWith(filters: const SmsLogFilters());
    await Future.wait([
      fetchLogs(refresh: true),
      fetchStats(),
      fetchDailyUsage(),
    ]);
  }

  /// Filter by type
  Future<void> filterByType(SmsType? type) async {
    final newFilters = state.filters.copyWith(
      type: type,
      clearType: type == null,
    );
    await updateFilters(newFilters);
  }

  /// Filter by status
  Future<void> filterByStatus(SmsStatus? status) async {
    final newFilters = state.filters.copyWith(
      status: status,
      clearStatus: status == null,
    );
    await updateFilters(newFilters);
  }

  /// Filter by date range
  Future<void> filterByDateRange(DateTime? from, DateTime? to) async {
    final newFilters = state.filters.copyWith(
      dateFrom: from,
      dateTo: to,
      clearDateFrom: from == null,
      clearDateTo: to == null,
    );
    await updateFilters(newFilters);
  }

  /// Filter by search query (phone number)
  Future<void> filterBySearch(String? query) async {
    final newFilters = state.filters.copyWith(
      searchQuery: query,
      clearSearchQuery: query == null || query.isEmpty,
    );
    await updateFilters(newFilters);
  }

  /// Quick filter: Today
  Future<void> filterToday() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    await filterByDateRange(startOfDay, today);
  }

  /// Quick filter: This week
  Future<void> filterThisWeek() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfDay =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    await filterByDateRange(startOfDay, now);
  }

  /// Quick filter: This month
  Future<void> filterThisMonth() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    await filterByDateRange(startOfMonth, now);
  }
}

final smsUsageNotifierProvider =
    StateNotifierProvider<SmsUsageNotifier, SmsUsageState>((ref) {
  final repository = ref.watch(smsUsageRepositoryProvider);
  return SmsUsageNotifier(repository);
});

// ============================================================================
// Additional Providers
// ============================================================================

/// Quick stats access
final smsUsageStatsProvider = FutureProvider<SmsUsageStats?>((ref) async {
  final repository = ref.watch(smsUsageRepositoryProvider);
  final result = await repository.getSmsStats();
  return result.stats;
});
