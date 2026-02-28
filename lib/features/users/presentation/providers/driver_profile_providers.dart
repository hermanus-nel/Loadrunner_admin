// lib/features/users/presentation/providers/driver_profile_providers.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/core_providers.dart';
import '../../domain/entities/driver_entity.dart';
import '../../domain/entities/driver_profile.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/entities/driver_document.dart';
import '../../domain/entities/approval_history_item.dart';
import '../../data/repositories/drivers_repository_impl.dart';
import '../../data/repositories/drivers_profile_repository.dart';
import '../providers/drivers_providers.dart';
import '../widgets/request_documents_dialog.dart';

/// Combined state for driver profile data
class DriverProfileData {
  final DriverProfile profile;
  final List<VehicleEntity> vehicles;
  final List<DriverDocument> documents;
  final List<ApprovalHistoryItem> approvalHistory;

  const DriverProfileData({
    required this.profile,
    required this.vehicles,
    required this.documents,
    required this.approvalHistory,
  });

  DriverProfileData copyWith({
    DriverProfile? profile,
    List<VehicleEntity>? vehicles,
    List<DriverDocument>? documents,
    List<ApprovalHistoryItem>? approvalHistory,
  }) {
    return DriverProfileData(
      profile: profile ?? this.profile,
      vehicles: vehicles ?? this.vehicles,
      documents: documents ?? this.documents,
      approvalHistory: approvalHistory ?? this.approvalHistory,
    );
  }
}

/// Provider family for driver profile controller
/// Each driver ID gets its own controller instance
final driverProfileControllerProvider = StateNotifierProvider.autoDispose
    .family<DriverProfileController, AsyncValue<DriverProfileData>, String>(
  (ref, driverId) {
    final repository = ref.read(driversRepositoryProvider) as DriversRepositoryImpl;
    return DriverProfileController(
      repository: repository,
      driverId: driverId,
      ref: ref,
    );
  },
);

/// Controller for driver profile with approval workflow actions
class DriverProfileController extends StateNotifier<AsyncValue<DriverProfileData>> {
  final DriversRepositoryImpl _repository;
  final String _driverId;
  final Ref _ref;

  DriverProfileController({
    required DriversRepositoryImpl repository,
    required String driverId,
    required Ref ref,
  })  : _repository = repository,
        _driverId = driverId,
        _ref = ref,
        super(const AsyncValue.loading());

  /// Load complete driver profile data
  Future<void> loadProfile() async {
    state = const AsyncValue.loading();
    
    try {
      // Fetch all data in parallel for better performance
      final results = await Future.wait([
        _repository.fetchDriverProfile(_driverId),
        _repository.fetchDriverVehicles(_driverId),
        _repository.fetchDriverDocuments(_driverId),
        _repository.fetchApprovalHistory(_driverId),
      ]);

      state = AsyncValue.data(DriverProfileData(
        profile: results[0] as DriverProfile,
        vehicles: results[1] as List<VehicleEntity>,
        documents: results[2] as List<DriverDocument>,
        approvalHistory: results[3] as List<ApprovalHistoryItem>,
      ));
    } catch (e, stack) {
      debugPrint('Error loading driver profile: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  /// Refresh only the profile data (for quick updates after actions)
  Future<void> refreshProfile() async {
    if (!state.hasValue) {
      await loadProfile();
      return;
    }

    try {
      final profile = await _repository.fetchDriverProfile(_driverId);
      final history = await _repository.fetchApprovalHistory(_driverId);
      
      state = AsyncValue.data(state.value!.copyWith(
        profile: profile,
        approvalHistory: history,
      ));
    } catch (e, stack) {
      debugPrint('Error refreshing driver profile: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  /// Get the current admin user ID
  Future<String?> _getAdminId() async {
    return await _repository.getCurrentAdminId();
  }

  // ==========================================================================
  // APPROVAL WORKFLOW ACTIONS
  // ==========================================================================

  /// Approve the driver
  /// Returns true if successful, false otherwise
  Future<bool> approveDriver({String? notes}) async {
    try {
      final adminId = await _getAdminId();
      if (adminId == null) {
        debugPrint('❌ Cannot approve: No admin ID available');
        return false;
      }

      debugPrint('🟢 Approving driver $_driverId by admin $adminId');
      
      await _repository.approveDriver(
        _driverId,
        adminId,
      );

      // Refresh profile to show updated status
      await refreshProfile();

      // Refresh drivers list so tab counts and list reflect the change
      _ref.read(driversListNotifierProvider.notifier).refresh();

      return true;
    } catch (e) {
      debugPrint('❌ Error approving driver: $e');
      return false;
    }
  }

  /// Reject the driver with a reason
  /// Returns true if successful, false otherwise
  Future<bool> rejectDriver({
    required String reason,
    String? notes,
  }) async {
    try {
      final adminId = await _getAdminId();
      if (adminId == null) {
        debugPrint('❌ Cannot reject: No admin ID available');
        return false;
      }

      debugPrint('🔴 Rejecting driver $_driverId by admin $adminId');
      debugPrint('📝 Reason: $reason');
      
      await _repository.rejectDriver(
        _driverId,
        adminId,
        reason,
      );

      // Refresh profile to show updated status
      await refreshProfile();

      // Refresh drivers list so tab counts and list reflect the change
      _ref.read(driversListNotifierProvider.notifier).refresh();

      return true;
    } catch (e) {
      debugPrint('❌ Error rejecting driver: $e');
      return false;
    }
  }

  /// Request additional documents from the driver
  /// Returns true if successful, false otherwise
  Future<bool> requestDocuments({
    required List<DocumentType> documentTypes,
    required String message,
  }) async {
    try {
      final adminId = await _getAdminId();
      if (adminId == null) {
        debugPrint('❌ Cannot request documents: No admin ID available');
        return false;
      }

      debugPrint('📤 Requesting documents from driver $_driverId');
      debugPrint('📄 Documents: ${documentTypes.map((d) => d.code).join(', ')}');
      
      await _repository.requestDocuments(
        _driverId,
        adminId,
        documentTypes.map((d) => d.code).toList(),
        message,
      );

      // Refresh profile to show updated status
      await refreshProfile();

      // Refresh drivers list so tab counts and list reflect the change
      _ref.read(driversListNotifierProvider.notifier).refresh();

      return true;
    } catch (e) {
      debugPrint('❌ Error requesting documents: $e');
      return false;
    }
  }

  // ==========================================================================
  // UTILITY METHODS
  // ==========================================================================

  /// Check if the current driver can be approved
  /// (has all required documents)
  bool get canBeApproved {
    if (!state.hasValue) return false;
    
    final profile = state.value!.profile;
    final documents = state.value!.documents;
    
    // Check status
    if (profile.verificationStatus == 'approved' ||
        profile.verificationStatus == 'suspended') {
      return false;
    }

    // Check for required documents
    final hasLicenseFront = documents.any((d) => d.docType == 'license_front');
    final hasLicenseBack = documents.any((d) => d.docType == 'license_back');

    return hasLicenseFront && hasLicenseBack;
  }

  /// Get list of missing required documents
  List<String> get missingDocuments {
    if (!state.hasValue) return [];
    
    final profile = state.value!.profile;
    final documents = state.value!.documents;
    final missing = <String>[];

    if (!documents.any((d) => d.docType == 'license_front')) {
      missing.add('Driver\'s License (Front)');
    }

    if (!documents.any((d) => d.docType == 'license_back')) {
      missing.add('Driver\'s License (Back)');
    }

    if (!documents.any((d) => d.docType == 'id_document')) {
      missing.add('National ID / Passport');
    }

    return missing;
  }
}

/// Provider for quick access to driver counts (for badges)
final driverCountsProvider = FutureProvider.autoDispose<DriverStatusCounts>((ref) async {
  final repository = ref.read(driversRepositoryProvider);
  return repository.fetchDriverCounts();
});

/// Provider for the pending bank verifications count (for badge)
final pendingBankVerificationsCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final repository = ref.read(driversProfileRepositoryProvider);
  return repository.fetchPendingBankVerificationsCount();
});
