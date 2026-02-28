// lib/features/users/domain/repositories/vehicles_repository.dart
import '../entities/vehicle_entity.dart';

/// Vehicle approval history item
class VehicleApprovalHistoryItem {
  final String id;
  final String vehicleId;
  final String adminId;
  final String? adminName;
  final String? previousStatus;
  final String newStatus;
  final String? action;
  final String? documentType;
  final String? reason;
  final String? notes;
  final DateTime createdAt;

  const VehicleApprovalHistoryItem({
    required this.id,
    required this.vehicleId,
    required this.adminId,
    this.adminName,
    this.previousStatus,
    required this.newStatus,
    this.action,
    this.documentType,
    this.reason,
    this.notes,
    required this.createdAt,
  });
}

/// Abstract repository for vehicle-related operations
abstract class VehiclesRepository {
  // ==========================================================================
  // VEHICLE FETCH METHODS
  // ==========================================================================

  /// Fetch full vehicle details by ID, including driver info
  Future<VehicleEntity> fetchVehicleDetails(String vehicleId);

  /// Fetch all vehicles with optional filters
  Future<List<VehicleEntity>> fetchVehicles({
    String? status,
    String? driverId,
    String? searchQuery,
    int limit = 20,
    int offset = 0,
  });

  /// Fetch vehicle counts by verification status
  Future<Map<String, int>> fetchVehicleCounts();

  // ==========================================================================
  // VEHICLE APPROVAL METHODS
  // ==========================================================================

  /// Approve a vehicle
  /// - Sets verification_status to 'approved'
  /// - Sets verified_by and verified_at
  /// - Logs action to admin audit log
  /// - Sends notification to driver
  Future<bool> approveVehicle({
    required String vehicleId,
    required String adminId,
    String? notes,
  });

  /// Reject a vehicle
  /// - Sets verification_status to 'rejected'
  /// - Sets rejection_reason
  /// - Logs action to admin audit log
  /// - Sends notification to driver with reason
  Future<bool> rejectVehicle({
    required String vehicleId,
    required String adminId,
    required String reason,
    String? notes,
  });

  /// Request additional documents for a vehicle
  /// - Sets verification_status to 'documents_requested'
  /// - Sends notification to driver with required documents
  Future<bool> requestVehicleDocuments({
    required String vehicleId,
    required String adminId,
    required List<String> documentTypes,
    required String message,
  });

  /// Mark a vehicle as under review
  /// - Sets verification_status to 'under_review'
  /// - Logs action to admin audit log
  /// - Sends notification to driver
  Future<bool> markVehicleUnderReview({
    required String vehicleId,
    required String adminId,
    String? notes,
  });

  /// Suspend an approved vehicle
  /// - Sets verification_status to 'suspended'
  /// - Sets rejection_reason to the suspension reason
  /// - Logs action to admin audit log
  /// - Sends notification to driver with reason
  Future<bool> suspendVehicle({
    required String vehicleId,
    required String adminId,
    required String reason,
    String? notes,
  });

  /// Reinstate a suspended vehicle
  /// - Sets verification_status to 'approved'
  /// - Clears rejection_reason, sets verified_by/verified_at
  /// - Logs action to admin audit log
  /// - Sends notification to driver
  Future<bool> reinstateVehicle({
    required String vehicleId,
    required String adminId,
    String? notes,
  });

  // ==========================================================================
  // VEHICLE DOCUMENT REVIEW METHODS
  // ==========================================================================

  /// Approve a specific vehicle document (Registration/Insurance/Roadworthy)
  Future<bool> approveVehicleDocument({
    required String vehicleId,
    required String docType,
    required String adminId,
  });

  /// Reject a specific vehicle document
  Future<bool> rejectVehicleDocument({
    required String vehicleId,
    required String docType,
    required String adminId,
    required String reason,
    String? notes,
  });

  /// Request re-upload for a specific vehicle document
  Future<bool> requestVehicleDocumentReupload({
    required String vehicleId,
    required String docType,
    required String adminId,
    required String reason,
    String? notes,
  });

  // ==========================================================================
  // UTILITY METHODS
  // ==========================================================================

  /// Get the current admin user ID from the session
  Future<String?> getCurrentAdminId();

  /// Check if a vehicle can be approved (has required documents)
  Future<bool> canApproveVehicle(String vehicleId);

  /// Fetch vehicle approval history from audit logs
  Future<List<VehicleApprovalHistoryItem>> fetchVehicleHistory(String vehicleId);
}
