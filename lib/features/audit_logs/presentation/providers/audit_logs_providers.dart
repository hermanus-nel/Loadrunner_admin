// lib/features/audit_logs/presentation/providers/audit_logs_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/core_providers.dart';
import '../../data/repositories/audit_logs_repository_impl.dart';
import '../../domain/entities/audit_log_entity.dart';
import '../../domain/repositories/audit_logs_repository.dart';

/// Repository provider
final auditLogsRepositoryProvider = Provider<AuditLogsRepository>((ref) {
  final supabase = ref.watch(supabaseProviderInstance).client;
  final jwtHandler = ref.watch(jwtRecoveryHandlerProvider);
  return AuditLogsRepositoryImpl(
    supabase: supabase,
    jwtHandler: jwtHandler,
  );
});

// ============================================================================
// Audit Logs List State
// ============================================================================

class AuditLogsListState {
  final List<AuditLogEntity> logs;
  final AuditLogsPagination pagination;
  final AuditLogFilters filters;
  final AuditLogsStats? stats;
  final List<AuditLogAdmin> availableAdmins;
  final List<String> availableActions;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const AuditLogsListState({
    this.logs = const [],
    this.pagination = const AuditLogsPagination(),
    this.filters = const AuditLogFilters(),
    this.stats,
    this.availableAdmins = const [],
    this.availableActions = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  AuditLogsListState copyWith({
    List<AuditLogEntity>? logs,
    AuditLogsPagination? pagination,
    AuditLogFilters? filters,
    AuditLogsStats? stats,
    List<AuditLogAdmin>? availableAdmins,
    List<String>? availableActions,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return AuditLogsListState(
      logs: logs ?? this.logs,
      pagination: pagination ?? this.pagination,
      filters: filters ?? this.filters,
      stats: stats ?? this.stats,
      availableAdmins: availableAdmins ?? this.availableAdmins,
      availableActions: availableActions ?? this.availableActions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuditLogsListNotifier extends StateNotifier<AuditLogsListState> {
  final AuditLogsRepository _repository;

  AuditLogsListNotifier(this._repository) : super(const AuditLogsListState());

  /// Initialize - load logs, admins, actions, and stats
  Future<void> initialize() async {
    await Future.wait([
      fetchLogs(refresh: true),
      fetchStats(),
      fetchAvailableAdmins(),
      fetchAvailableActions(),
    ]);
  }

  /// Fetch audit logs with current filters
  Future<void> fetchLogs({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      logs: refresh ? [] : state.logs,
      pagination: refresh ? const AuditLogsPagination() : state.pagination,
    );

    final result = await _repository.fetchAuditLogs(
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
    final result = await _repository.fetchAuditLogs(
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
    final result = await _repository.getStats();
    if (result.stats != null) {
      state = state.copyWith(stats: result.stats);
    }
  }

  /// Fetch available admins for filter dropdown
  Future<void> fetchAvailableAdmins() async {
    final result = await _repository.getActiveAdmins();
    if (result.error == null) {
      state = state.copyWith(availableAdmins: result.admins);
    }
  }

  /// Fetch available actions for filter dropdown
  Future<void> fetchAvailableActions() async {
    final actions = await _repository.getDistinctActions();
    state = state.copyWith(availableActions: actions);
  }

  /// Update filters and refresh
  Future<void> updateFilters(AuditLogFilters filters) async {
    state = state.copyWith(filters: filters);
    await fetchLogs(refresh: true);
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    state = state.copyWith(filters: const AuditLogFilters());
    await fetchLogs(refresh: true);
  }

  /// Filter by admin
  Future<void> filterByAdmin(String? adminId) async {
    final newFilters = state.filters.copyWith(
      adminId: adminId,
      clearAdminId: adminId == null,
    );
    await updateFilters(newFilters);
  }

  /// Filter by action
  Future<void> filterByAction(String? action) async {
    final newFilters = state.filters.copyWith(
      action: action,
      clearAction: action == null,
    );
    await updateFilters(newFilters);
  }

  /// Filter by category
  Future<void> filterByCategory(AuditActionCategory? category) async {
    final newFilters = state.filters.copyWith(
      category: category,
      clearCategory: category == null,
    );
    await updateFilters(newFilters);
  }

  /// Filter by target type
  Future<void> filterByTargetType(String? targetType) async {
    final newFilters = state.filters.copyWith(
      targetType: targetType,
      clearTargetType: targetType == null,
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
    final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    await filterByDateRange(startOfDay, now);
  }

  /// Quick filter: This month
  Future<void> filterThisMonth() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    await filterByDateRange(startOfMonth, now);
  }
}

final auditLogsListNotifierProvider =
    StateNotifierProvider<AuditLogsListNotifier, AuditLogsListState>((ref) {
  final repository = ref.watch(auditLogsRepositoryProvider);
  return AuditLogsListNotifier(repository);
});

// ============================================================================
// Audit Log Detail State
// ============================================================================

class AuditLogDetailState {
  final AuditLogEntity? log;
  final bool isLoading;
  final String? error;

  const AuditLogDetailState({
    this.log,
    this.isLoading = false,
    this.error,
  });

  AuditLogDetailState copyWith({
    AuditLogEntity? log,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuditLogDetailState(
      log: log ?? this.log,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuditLogDetailNotifier extends StateNotifier<AuditLogDetailState> {
  final AuditLogsRepository _repository;

  AuditLogDetailNotifier(this._repository) : super(const AuditLogDetailState());

  Future<void> fetchLogDetail(String logId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final log = await _repository.fetchAuditLogById(logId);

    if (log == null) {
      state = state.copyWith(isLoading: false, error: 'Audit log not found');
      return;
    }

    state = state.copyWith(log: log, isLoading: false);
  }

  void clear() {
    state = const AuditLogDetailState();
  }
}

final auditLogDetailNotifierProvider =
    StateNotifierProvider<AuditLogDetailNotifier, AuditLogDetailState>((ref) {
  final repository = ref.watch(auditLogsRepositoryProvider);
  return AuditLogDetailNotifier(repository);
});

// ============================================================================
// Additional Providers
// ============================================================================

/// Logs for a specific target
final logsForTargetProvider = FutureProvider.family<List<AuditLogEntity>, ({String targetType, String targetId})>(
  (ref, params) async {
    final repository = ref.watch(auditLogsRepositoryProvider);
    final result = await repository.fetchLogsForTarget(
      targetType: params.targetType,
      targetId: params.targetId,
    );
    return result.logs;
  },
);

/// Stats provider
final auditLogsStatsProvider = FutureProvider<AuditLogsStats?>((ref) async {
  final repository = ref.watch(auditLogsRepositoryProvider);
  final result = await repository.getStats();
  return result.stats;
});

/// Available admins for filter
final availableAdminsProvider = FutureProvider<List<AuditLogAdmin>>((ref) async {
  final repository = ref.watch(auditLogsRepositoryProvider);
  final result = await repository.getActiveAdmins();
  return result.admins;
});

/// Available actions for filter
final availableActionsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(auditLogsRepositoryProvider);
  return await repository.getDistinctActions();
});

/// Export logs provider
final exportLogsProvider = FutureProvider.family<String?, AuditLogFilters?>((ref, filters) async {
  final repository = ref.watch(auditLogsRepositoryProvider);
  return await repository.exportLogs(filters: filters);
});
