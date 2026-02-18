// lib/features/users/presentation/providers/vehicle_providers.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/core_providers.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../data/repositories/vehicles_repository_impl.dart';

import '../../domain/repositories/vehicles_repository.dart';

/// Provider for the vehicles repository
final vehiclesRepositoryProvider = Provider<VehiclesRepositoryImpl>((ref) {
  final supabaseProvider = ref.read(supabaseProviderInstance);
  final jwtRecoveryHandler = ref.read(jwtRecoveryHandlerProvider);

  return VehiclesRepositoryImpl(
    supabaseProvider: supabaseProvider,
    jwtRecoveryHandler: jwtRecoveryHandler,
    sessionService: ref.read(sessionServiceProvider),
  );
});

/// State for the vehicle detail screen
class VehicleDetailState {
  final VehicleEntity? vehicle;
  final List<VehicleApprovalHistoryItem> history;
  final bool isLoading;
  final String? error;
  final bool isProcessing;

  const VehicleDetailState({
    this.vehicle,
    this.history = const [],
    this.isLoading = false,
    this.error,
    this.isProcessing = false,
  });

  VehicleDetailState copyWith({
    VehicleEntity? vehicle,
    List<VehicleApprovalHistoryItem>? history,
    bool? isLoading,
    String? error,
    bool? isProcessing,
  }) {
    return VehicleDetailState(
      vehicle: vehicle ?? this.vehicle,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

/// Provider family for vehicle detail controller
/// Each vehicle ID gets its own controller instance
final vehicleDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<VehicleDetailController, VehicleDetailState, String>(
  (ref, vehicleId) {
    final repository = ref.read(vehiclesRepositoryProvider);
    return VehicleDetailController(
      repository: repository,
      vehicleId: vehicleId,
    );
  },
);

/// Controller for vehicle detail with approval workflow actions
class VehicleDetailController extends StateNotifier<VehicleDetailState> {
  final VehiclesRepositoryImpl _repository;
  final String _vehicleId;

  VehicleDetailController({
    required VehiclesRepositoryImpl repository,
    required String vehicleId,
  })  : _repository = repository,
        _vehicleId = vehicleId,
        super(const VehicleDetailState(isLoading: true));

  /// Load vehicle details
  Future<void> loadVehicle() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final vehicle = await _repository.fetchVehicleDetails(_vehicleId);
      final history = await _repository.fetchVehicleHistory(_vehicleId);
      state = state.copyWith(
        vehicle: vehicle,
        history: history,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading vehicle: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh vehicle data
  Future<void> refreshVehicle() async {
    try {
      final vehicle = await _repository.fetchVehicleDetails(_vehicleId);
      final history = await _repository.fetchVehicleHistory(_vehicleId);
      state = state.copyWith(vehicle: vehicle, history: history);
    } catch (e) {
      debugPrint('Error refreshing vehicle: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Get the current admin user ID
  Future<String?> _getAdminId() async {
    return await _repository.getCurrentAdminId();
  }

  // ==========================================================================
  // APPROVAL WORKFLOW ACTIONS
  // ==========================================================================

  /// Approve the vehicle
  /// Returns true if successful, false otherwise
  Future<bool> approveVehicle({String? notes}) async {
    state = state.copyWith(isProcessing: true);

    try {
      final adminId = await _getAdminId();
      if (adminId == null) {
        debugPrint('❌ Cannot approve: No admin ID available');
        state = state.copyWith(isProcessing: false);
        return false;
      }

      debugPrint('🟢 Approving vehicle $_vehicleId by admin $adminId');

      final success = await _repository.approveVehicle(
        vehicleId: _vehicleId,
        adminId: adminId,
        notes: notes,
      );

      if (success) {
        await refreshVehicle();
      }

      state = state.copyWith(isProcessing: false);
      return success;
    } catch (e) {
      debugPrint('❌ Error approving vehicle: $e');
      state = state.copyWith(isProcessing: false);
      return false;
    }
  }

  /// Reject the vehicle with a reason
  /// Returns true if successful, false otherwise
  Future<bool> rejectVehicle({
    required String reason,
    String? notes,
  }) async {
    state = state.copyWith(isProcessing: true);

    try {
      final adminId = await _getAdminId();
      if (adminId == null) {
        debugPrint('❌ Cannot reject: No admin ID available');
        state = state.copyWith(isProcessing: false);
        return false;
      }

      debugPrint('🔴 Rejecting vehicle $_vehicleId by admin $adminId');
      debugPrint('📝 Reason: $reason');

      final success = await _repository.rejectVehicle(
        vehicleId: _vehicleId,
        adminId: adminId,
        reason: reason,
        notes: notes,
      );

      if (success) {
        await refreshVehicle();
      }

      state = state.copyWith(isProcessing: false);
      return success;
    } catch (e) {
      debugPrint('❌ Error rejecting vehicle: $e');
      state = state.copyWith(isProcessing: false);
      return false;
    }
  }

  /// Request additional documents for the vehicle
  /// Returns true if successful, false otherwise
  Future<bool> requestDocuments({
    required List<String> documentTypes,
    required String message,
  }) async {
    state = state.copyWith(isProcessing: true);

    try {
      final adminId = await _getAdminId();
      if (adminId == null) {
        debugPrint('❌ Cannot request documents: No admin ID available');
        state = state.copyWith(isProcessing: false);
        return false;
      }

      debugPrint('📤 Requesting documents for vehicle $_vehicleId');

      final success = await _repository.requestVehicleDocuments(
        vehicleId: _vehicleId,
        adminId: adminId,
        documentTypes: documentTypes,
        message: message,
      );

      if (success) {
        await refreshVehicle();
      }

      state = state.copyWith(isProcessing: false);
      return success;
    } catch (e) {
      debugPrint('❌ Error requesting documents: $e');
      state = state.copyWith(isProcessing: false);
      return false;
    }
  }

  /// Mark the vehicle as under review
  /// Returns true if successful, false otherwise
  Future<bool> markUnderReview({String? notes}) async {
    state = state.copyWith(isProcessing: true);

    try {
      final adminId = await _getAdminId();
      if (adminId == null) {
        debugPrint('❌ Cannot mark under review: No admin ID available');
        state = state.copyWith(isProcessing: false);
        return false;
      }

      debugPrint('🔵 Marking vehicle $_vehicleId as under review by admin $adminId');

      final success = await _repository.markVehicleUnderReview(
        vehicleId: _vehicleId,
        adminId: adminId,
        notes: notes,
      );

      if (success) {
        await refreshVehicle();
      }

      state = state.copyWith(isProcessing: false);
      return success;
    } catch (e) {
      debugPrint('❌ Error marking vehicle under review: $e');
      state = state.copyWith(isProcessing: false);
      return false;
    }
  }

  /// Suspend the vehicle with a reason
  /// Returns true if successful, false otherwise
  Future<bool> suspendVehicle({
    required String reason,
    String? notes,
  }) async {
    state = state.copyWith(isProcessing: true);

    try {
      final adminId = await _getAdminId();
      if (adminId == null) {
        debugPrint('❌ Cannot suspend: No admin ID available');
        state = state.copyWith(isProcessing: false);
        return false;
      }

      debugPrint('🟤 Suspending vehicle $_vehicleId by admin $adminId');

      final success = await _repository.suspendVehicle(
        vehicleId: _vehicleId,
        adminId: adminId,
        reason: reason,
        notes: notes,
      );

      if (success) {
        await refreshVehicle();
      }

      state = state.copyWith(isProcessing: false);
      return success;
    } catch (e) {
      debugPrint('❌ Error suspending vehicle: $e');
      state = state.copyWith(isProcessing: false);
      return false;
    }
  }

  /// Reinstate a suspended vehicle
  /// Returns true if successful, false otherwise
  Future<bool> reinstateVehicle({String? notes}) async {
    state = state.copyWith(isProcessing: true);

    try {
      final adminId = await _getAdminId();
      if (adminId == null) {
        debugPrint('❌ Cannot reinstate: No admin ID available');
        state = state.copyWith(isProcessing: false);
        return false;
      }

      debugPrint('🟢 Reinstating vehicle $_vehicleId by admin $adminId');

      final success = await _repository.reinstateVehicle(
        vehicleId: _vehicleId,
        adminId: adminId,
        notes: notes,
      );

      if (success) {
        await refreshVehicle();
      }

      state = state.copyWith(isProcessing: false);
      return success;
    } catch (e) {
      debugPrint('❌ Error reinstating vehicle: $e');
      state = state.copyWith(isProcessing: false);
      return false;
    }
  }

  // ==========================================================================
  // UTILITY METHODS
  // ==========================================================================

  /// Check if the current vehicle can be approved
  bool get canBeApproved {
    final vehicle = state.vehicle;
    if (vehicle == null) return false;

    // Check status
    if (vehicle.isApproved) return false;

    // Check for required documents
    return vehicle.photoUrl != null &&
        vehicle.registrationDocumentUrl != null &&
        vehicle.insuranceDocumentUrl != null;
  }

  /// Get list of missing required documents
  List<String> get missingDocuments {
    final vehicle = state.vehicle;
    if (vehicle == null) return [];

    final missing = <String>[];
    if (vehicle.photoUrl == null) missing.add('Vehicle Photo');
    if (vehicle.registrationDocumentUrl == null) missing.add('Registration Document');
    if (vehicle.insuranceDocumentUrl == null) missing.add('Insurance Document');

    return missing;
  }
}

/// Provider for vehicle counts (for badges)
final vehicleCountsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final repository = ref.read(vehiclesRepositoryProvider);
  return repository.fetchVehicleCounts();
});

/// State for vehicles list
class VehiclesListState {
  final List<VehicleEntity> vehicles;
  final bool isLoading;
  final String? error;
  final String currentTab;
  final String searchQuery;
  final bool hasMore;
  final int offset;

  const VehiclesListState({
    this.vehicles = const [],
    this.isLoading = false,
    this.error,
    this.currentTab = 'all',
    this.searchQuery = '',
    this.hasMore = true,
    this.offset = 0,
  });

  VehiclesListState copyWith({
    List<VehicleEntity>? vehicles,
    bool? isLoading,
    String? error,
    String? currentTab,
    String? searchQuery,
    bool? hasMore,
    int? offset,
  }) {
    return VehiclesListState(
      vehicles: vehicles ?? this.vehicles,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentTab: currentTab ?? this.currentTab,
      searchQuery: searchQuery ?? this.searchQuery,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
    );
  }
}

/// Provider for vehicles list controller
final vehiclesListControllerProvider =
    StateNotifierProvider.autoDispose<VehiclesListController, VehiclesListState>(
  (ref) {
    final repository = ref.read(vehiclesRepositoryProvider);
    return VehiclesListController(repository: repository);
  },
);

/// Controller for vehicles list
class VehiclesListController extends StateNotifier<VehiclesListState> {
  final VehiclesRepositoryImpl _repository;
  static const int _pageSize = 20;

  VehiclesListController({
    required VehiclesRepositoryImpl repository,
  })  : _repository = repository,
        super(const VehiclesListState());

  /// Load vehicles with current filters
  Future<void> loadVehicles({bool refresh = false}) async {
    if (state.isLoading) return;

    final offset = refresh ? 0 : state.offset;
    state = state.copyWith(
      isLoading: true,
      error: null,
      offset: offset,
    );

    try {
      final status = state.currentTab == 'all' ? null : state.currentTab;
      final vehicles = await _repository.fetchVehicles(
        status: status,
        searchQuery: state.searchQuery.isEmpty ? null : state.searchQuery,
        limit: _pageSize,
        offset: offset,
      );

      final newVehicles = refresh
          ? vehicles
          : [...state.vehicles, ...vehicles];

      state = state.copyWith(
        vehicles: newVehicles,
        isLoading: false,
        hasMore: vehicles.length >= _pageSize,
        offset: offset + vehicles.length,
      );
    } catch (e) {
      debugPrint('Error loading vehicles: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Change the current tab
  void changeTab(String tab) {
    if (tab != state.currentTab) {
      state = state.copyWith(
        currentTab: tab,
        vehicles: [],
        offset: 0,
        hasMore: true,
      );
      loadVehicles();
    }
  }

  /// Update search query
  void setSearchQuery(String query) {
    if (query != state.searchQuery) {
      state = state.copyWith(
        searchQuery: query,
        vehicles: [],
        offset: 0,
        hasMore: true,
      );
      loadVehicles();
    }
  }

  /// Load more vehicles (pagination)
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    await loadVehicles();
  }

  /// Refresh the list
  Future<void> refresh() async {
    await loadVehicles(refresh: true);
  }
}
