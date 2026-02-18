// lib/features/shippers/presentation/providers/shippers_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/core_providers.dart';
import '../../data/repositories/shippers_repository_impl.dart';
import '../../domain/entities/shipper_entity.dart';
import '../../domain/repositories/shippers_repository.dart';

/// Repository provider
final shippersRepositoryProvider = Provider<ShippersRepository>((ref) {
  final supabase = ref.watch(supabaseProviderInstance).client;
  final jwtHandler = ref.watch(jwtRecoveryHandlerProvider);
  return ShippersRepositoryImpl(
    supabase: supabase,
    jwtHandler: jwtHandler,
    sessionService: ref.watch(sessionServiceProvider),
  );
});

// ============================================================================
// Shippers List State
// ============================================================================

class ShippersListState {
  final List<ShipperEntity> shippers;
  final ShippersPagination pagination;
  final ShipperFilters filters;
  final ShippersOverviewStats? overviewStats;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const ShippersListState({
    this.shippers = const [],
    this.pagination = const ShippersPagination(),
    this.filters = const ShipperFilters(),
    this.overviewStats,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  ShippersListState copyWith({
    List<ShipperEntity>? shippers,
    ShippersPagination? pagination,
    ShipperFilters? filters,
    ShippersOverviewStats? overviewStats,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return ShippersListState(
      shippers: shippers ?? this.shippers,
      pagination: pagination ?? this.pagination,
      filters: filters ?? this.filters,
      overviewStats: overviewStats ?? this.overviewStats,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ShippersListNotifier extends StateNotifier<ShippersListState> {
  final ShippersRepository _repository;

  ShippersListNotifier(this._repository) : super(const ShippersListState());

  /// Fetch shippers with current filters
  Future<void> fetchShippers({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      shippers: refresh ? [] : state.shippers,
      pagination: refresh ? const ShippersPagination() : state.pagination,
    );

    final result = await _repository.fetchShippers(
      filters: state.filters,
      pagination: refresh ? null : state.pagination.copyWith(page: 1),
    );

    if (result.error != null) {
      state = state.copyWith(isLoading: false, error: result.error);
      return;
    }

    state = state.copyWith(
      shippers: result.shippers,
      pagination: result.pagination,
      isLoading: false,
    );
  }

  /// Load more shippers (pagination)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.pagination.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    final nextPage = state.pagination.page + 1;
    final result = await _repository.fetchShippers(
      filters: state.filters,
      pagination: state.pagination.copyWith(page: nextPage),
    );

    if (result.error != null) {
      state = state.copyWith(isLoadingMore: false, error: result.error);
      return;
    }

    state = state.copyWith(
      shippers: [...state.shippers, ...result.shippers],
      pagination: result.pagination,
      isLoadingMore: false,
    );
  }

  /// Update filters and refresh list
  Future<void> updateFilters(ShipperFilters filters) async {
    state = state.copyWith(filters: filters);
    await fetchShippers(refresh: true);
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    state = state.copyWith(filters: const ShipperFilters());
    await fetchShippers(refresh: true);
  }

  /// Filter by status
  Future<void> filterByStatus(ShipperStatus? status) async {
    final newFilters = state.filters.copyWith(
      status: status,
      clearStatus: status == null,
    );
    await updateFilters(newFilters);
  }

  /// Search by query
  Future<void> search(String? query) async {
    final newFilters = state.filters.copyWith(
      searchQuery: query,
      clearSearchQuery: query == null || query.isEmpty,
    );
    await updateFilters(newFilters);
  }

  /// Filter by date range
  Future<void> filterByDateRange(DateTime? start, DateTime? end) async {
    final newFilters = state.filters.copyWith(
      registeredAfter: start,
      registeredBefore: end,
      clearRegisteredAfter: start == null,
      clearRegisteredBefore: end == null,
    );
    await updateFilters(newFilters);
  }

  /// Sort shippers
  Future<void> sortBy(ShipperSortBy sortBy, {bool? ascending}) async {
    final newFilters = state.filters.copyWith(
      sortBy: sortBy,
      sortAscending: ascending ?? !state.filters.sortAscending,
    );
    await updateFilters(newFilters);
  }

  /// Fetch overview stats
  Future<void> fetchOverviewStats() async {
    final result = await _repository.getOverviewStats();
    if (result.stats != null) {
      state = state.copyWith(overviewStats: result.stats);
    }
  }
}

final shippersListNotifierProvider =
    StateNotifierProvider<ShippersListNotifier, ShippersListState>((ref) {
  final repository = ref.watch(shippersRepositoryProvider);
  return ShippersListNotifier(repository);
});

// ============================================================================
// Shipper Detail State
// ============================================================================

class ShipperDetailState {
  final ShipperEntity? shipper;
  final List<ShipperRecentShipment> recentShipments;
  final bool isLoading;
  final bool isUpdating;
  final String? error;

  const ShipperDetailState({
    this.shipper,
    this.recentShipments = const [],
    this.isLoading = false,
    this.isUpdating = false,
    this.error,
  });

  ShipperDetailState copyWith({
    ShipperEntity? shipper,
    List<ShipperRecentShipment>? recentShipments,
    bool? isLoading,
    bool? isUpdating,
    String? error,
    bool clearError = false,
  }) {
    return ShipperDetailState(
      shipper: shipper ?? this.shipper,
      recentShipments: recentShipments ?? this.recentShipments,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ShipperDetailNotifier extends StateNotifier<ShipperDetailState> {
  final ShippersRepository _repository;

  ShipperDetailNotifier(this._repository) : super(const ShipperDetailState());

  /// Fetch shipper details
  Future<void> fetchShipperDetail(String shipperId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.fetchShipperDetail(shipperId);

    if (result.error != null) {
      state = state.copyWith(isLoading: false, error: result.error);
      return;
    }

    state = state.copyWith(
      shipper: result.shipper,
      recentShipments: result.recentShipments,
      isLoading: false,
    );
  }

  /// Suspend shipper
  Future<bool> suspendShipper(String shipperId, String reason, {DateTime? endsAt}) async {
    state = state.copyWith(isUpdating: true, clearError: true);

    final result = await _repository.suspendShipper(
      shipperId,
      reason: reason,
      endsAt: endsAt,
    );

    if (!result.success) {
      state = state.copyWith(isUpdating: false, error: result.error);
      return false;
    }

    // Refresh shipper details
    await fetchShipperDetail(shipperId);
    state = state.copyWith(isUpdating: false);
    return true;
  }

  /// Unsuspend shipper
  Future<bool> unsuspendShipper(String shipperId) async {
    state = state.copyWith(isUpdating: true, clearError: true);

    final result = await _repository.unsuspendShipper(shipperId);

    if (!result.success) {
      state = state.copyWith(isUpdating: false, error: result.error);
      return false;
    }

    // Refresh shipper details
    await fetchShipperDetail(shipperId);
    state = state.copyWith(isUpdating: false);
    return true;
  }

  /// Update shipper profile
  Future<bool> updateProfile(
    String shipperId, {
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    state = state.copyWith(isUpdating: true, clearError: true);

    final result = await _repository.updateShipperProfile(
      shipperId,
      firstName: firstName,
      lastName: lastName,
      email: email,
    );

    if (!result.success) {
      state = state.copyWith(isUpdating: false, error: result.error);
      return false;
    }

    // Refresh shipper details
    await fetchShipperDetail(shipperId);
    state = state.copyWith(isUpdating: false);
    return true;
  }

  /// Clear state
  void clear() {
    state = const ShipperDetailState();
  }
}

final shipperDetailNotifierProvider =
    StateNotifierProvider<ShipperDetailNotifier, ShipperDetailState>((ref) {
  final repository = ref.watch(shippersRepositoryProvider);
  return ShipperDetailNotifier(repository);
});

// ============================================================================
// Additional Providers
// ============================================================================

/// Overview stats provider
final shippersOverviewStatsProvider = FutureProvider<ShippersOverviewStats?>((ref) async {
  final repository = ref.watch(shippersRepositoryProvider);
  final result = await repository.getOverviewStats();
  return result.stats;
});

/// Recently active shippers provider
final recentlyActiveShippersProvider = FutureProvider<List<ShipperEntity>>((ref) async {
  final repository = ref.watch(shippersRepositoryProvider);
  final result = await repository.getRecentlyActiveShippers(limit: 10);
  return result.shippers;
});

/// New shippers provider (last 7 days)
final newShippersProvider = FutureProvider<List<ShipperEntity>>((ref) async {
  final repository = ref.watch(shippersRepositoryProvider);
  final result = await repository.getNewShippers(days: 7, limit: 10);
  return result.shippers;
});

/// Suspended shippers provider
final suspendedShippersProvider = FutureProvider<List<ShipperEntity>>((ref) async {
  final repository = ref.watch(shippersRepositoryProvider);
  final result = await repository.getSuspendedShippers();
  return result.shippers;
});

/// Search shippers provider
final shipperSearchProvider = FutureProvider.family<List<ShipperEntity>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(shippersRepositoryProvider);
  final result = await repository.searchShippers(query);
  return result.shippers;
});
