// lib/features/users/presentation/providers/drivers_providers.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/driver_entity.dart';
import '../../domain/repositories/drivers_repository.dart';
import '../../data/repositories/drivers_repository_impl.dart';
import '../../../../core/services/core_providers.dart';

// ============================================================
// DRIVERS LIST STATE
// ============================================================

/// Tab index for driver list
enum DriverTab {
  all,
  pending,
  approved,
  rejected;

  String get label {
    switch (this) {
      case DriverTab.all:
        return 'All';
      case DriverTab.pending:
        return 'Pending';
      case DriverTab.approved:
        return 'Approved';
      case DriverTab.rejected:
        return 'Rejected';
    }
  }

  DriverVerificationStatus? get status {
    switch (this) {
      case DriverTab.all:
        return null;
      case DriverTab.pending:
        return DriverVerificationStatus.pending;
      case DriverTab.approved:
        return DriverVerificationStatus.approved;
      case DriverTab.rejected:
        return DriverVerificationStatus.rejected;
    }
  }
}

/// State class for drivers list
class DriversListState {
  final List<DriverEntity> drivers;
  final DriverStatusCounts counts;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final DriverTab currentTab;
  final String searchQuery;
  final bool hasMore;
  final int currentPage;

  const DriversListState({
    required this.drivers,
    required this.counts,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentTab = DriverTab.pending,
    this.searchQuery = '',
    this.hasMore = true,
    this.currentPage = 0,
  });

  factory DriversListState.initial() {
    return DriversListState(
      drivers: [],
      counts: DriverStatusCounts.empty(),
      isLoading: true,
      currentTab: DriverTab.pending,
    );
  }

  DriversListState copyWith({
    List<DriverEntity>? drivers,
    DriverStatusCounts? counts,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    DriverTab? currentTab,
    String? searchQuery,
    bool? hasMore,
    int? currentPage,
  }) {
    return DriversListState(
      drivers: drivers ?? this.drivers,
      counts: counts ?? this.counts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      currentTab: currentTab ?? this.currentTab,
      searchQuery: searchQuery ?? this.searchQuery,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  bool get hasError => error != null;
  bool get isEmpty => drivers.isEmpty && !isLoading;

  /// Get count for specific tab
  int getCountForTab(DriverTab tab) {
    switch (tab) {
      case DriverTab.all:
        return counts.total;
      case DriverTab.pending:
        return counts.pending;
      case DriverTab.approved:
        return counts.approved;
      case DriverTab.rejected:
        return counts.rejected;
    }
  }
}

// ============================================================
// DRIVERS LIST NOTIFIER
// ============================================================

/// StateNotifier for drivers list logic
class DriversListNotifier extends StateNotifier<DriversListState> {
  final DriversRepository _repository;
  Timer? _searchDebounce;
  static const int _pageSize = 20;

  DriversListNotifier(this._repository) : super(DriversListState.initial()) {
    _initialize();
  }

  /// Initialize - load counts and first page
  Future<void> _initialize() async {
    await Future.wait([
      _loadCounts(),
      _loadDrivers(refresh: true),
    ]);
  }

  /// Load driver counts
  Future<void> _loadCounts() async {
    try {
      final counts = await _repository.fetchDriverCounts();
      state = state.copyWith(counts: counts);
    } catch (e) {
      debugPrint('DriversListNotifier: Error loading counts: $e');
    }
  }

  /// Load drivers with current filters
  Future<void> _loadDrivers({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    final offset = refresh ? 0 : state.currentPage * _pageSize;
    
    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 0,
      );
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final filter = DriverFilter(
        status: state.currentTab.status,
        searchQuery: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        limit: _pageSize,
        offset: offset,
      );

      final result = await _repository.fetchDrivers(filter);

      final newDrivers = refresh 
          ? result.drivers 
          : [...state.drivers, ...result.drivers];

      state = state.copyWith(
        drivers: newDrivers,
        isLoading: false,
        isLoadingMore: false,
        hasMore: result.hasMore,
        currentPage: refresh ? 1 : state.currentPage + 1,
      );

      debugPrint('DriversListNotifier: Loaded ${newDrivers.length} drivers');
    } catch (e) {
      debugPrint('DriversListNotifier: Error loading drivers: $e');
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: 'Failed to load drivers',
      );
    }
  }

  /// Refresh drivers list
  Future<void> refresh() async {
    await _loadCounts();
    await _loadDrivers(refresh: true);
  }

  /// Load more drivers (pagination)
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    await _loadDrivers(refresh: false);
  }

  /// Change current tab
  void setTab(DriverTab tab) {
    if (state.currentTab == tab) return;
    
    state = state.copyWith(
      currentTab: tab,
      drivers: [],
      hasMore: true,
      currentPage: 0,
    );
    
    _loadDrivers(refresh: true);
  }

  /// Update search query with debounce
  void setSearchQuery(String query) {
    _searchDebounce?.cancel();
    
    state = state.copyWith(searchQuery: query);
    
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _loadDrivers(refresh: true);
    });
  }

  /// Clear search
  void clearSearch() {
    if (state.searchQuery.isEmpty) return;
    
    _searchDebounce?.cancel();
    state = state.copyWith(searchQuery: '');
    _loadDrivers(refresh: true);
  }

  /// Clear error
  void clearError() {
    if (state.hasError) {
      state = state.copyWith(error: null);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}

// ============================================================
// PROVIDERS
// ============================================================

/// Provider for DriversRepository
final driversRepositoryProvider = Provider<DriversRepository>((ref) {
  final supabaseProvider = ref.read(supabaseProviderInstance);
  final jwtHandler = ref.read(jwtRecoveryHandlerProvider);
  
  return DriversRepositoryImpl(
    supabaseProvider: supabaseProvider,
    jwtRecoveryHandler: jwtHandler,
    sessionService: ref.read(sessionServiceProvider),
  );
});

/// Provider for DriversListNotifier
final driversListNotifierProvider = 
    StateNotifierProvider<DriversListNotifier, DriversListState>((ref) {
  final repository = ref.read(driversRepositoryProvider);
  return DriversListNotifier(repository);
});

// ============================================================
// CONVENIENCE PROVIDERS
// ============================================================

/// Provider for current drivers list
final driversListProvider = Provider<List<DriverEntity>>((ref) {
  return ref.watch(driversListNotifierProvider).drivers;
});

/// Provider for driver counts
final driverCountsProvider = Provider<DriverStatusCounts>((ref) {
  return ref.watch(driversListNotifierProvider).counts;
});

/// Provider for loading state
final isDriversLoadingProvider = Provider<bool>((ref) {
  return ref.watch(driversListNotifierProvider).isLoading;
});

/// Provider for current tab
final currentDriverTabProvider = Provider<DriverTab>((ref) {
  return ref.watch(driversListNotifierProvider).currentTab;
});

/// Provider for search query
final driverSearchQueryProvider = Provider<String>((ref) {
  return ref.watch(driversListNotifierProvider).searchQuery;
});
