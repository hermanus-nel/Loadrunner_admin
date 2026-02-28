// lib/features/users/data/repositories/drivers_repository_impl.dart
import 'package:flutter/foundation.dart';
import '../../../../core/services/jwt_recovery_handler.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/services/supabase_provider.dart';
import '../../domain/entities/approval_history_item.dart';
import '../../domain/entities/driver_document.dart';
import '../../domain/entities/driver_entity.dart';
import '../../domain/entities/driver_profile.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/repositories/drivers_repository.dart';
import '../../presentation/widgets/request_documents_dialog.dart';
import '../models/approval_history_model.dart';
import '../models/driver_document_model.dart';
import '../models/driver_model.dart';
import '../models/driver_profile_model.dart';
import '../models/vehicle_model.dart';

/// Implementation of DriversRepository using Supabase
class DriversRepositoryImpl implements DriversRepository {
  final SupabaseProvider _supabaseProvider;
  final JwtRecoveryHandler _jwtRecoveryHandler;
  final SessionService _sessionService;

  DriversRepositoryImpl({
    required SupabaseProvider supabaseProvider,
    required JwtRecoveryHandler jwtRecoveryHandler,
    required SessionService sessionService,
  })  : _supabaseProvider = supabaseProvider,
        _jwtRecoveryHandler = jwtRecoveryHandler,
        _sessionService = sessionService;

  // ==========================================================================
  // DRIVER LIST METHODS (from Step 11)
  // ==========================================================================

  @override
  Future<DriversResult> fetchDrivers(DriverFilter filter) async {
    try {
      final response = await _jwtRecoveryHandler.executeWithRecovery(
        () async {
          var query = _supabaseProvider.client
              .from('users')
              .select('''
                id,
                first_name,
                last_name,
                phone_number,
                email,
                profile_photo_url,
                driver_verification_status,
                created_at,
                updated_at,
                vehicles!vehicles_driver_id_fkey(count)
              ''')
              .eq('role', 'Driver');

          // Apply status filter
          if (filter.status != null) {
            query = query.eq('driver_verification_status', filter.status!.statusName);
          }

          // Apply search filter
          if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
            final searchTerm = '%${filter.searchQuery}%';
            query = query.or(
              'first_name.ilike.$searchTerm,'
              'last_name.ilike.$searchTerm,'
              'phone_number.ilike.$searchTerm,'
              'email.ilike.$searchTerm',
            );
          }

          return query
              .order('created_at', ascending: false)
              .range(filter.offset, filter.offset + filter.limit - 1);
        },
        'fetch drivers',
      );

      final List<dynamic> data = response as List<dynamic>;
      final drivers = data
          .map((json) =>
              DriverModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return DriversResult(
        drivers: drivers,
        hasMore: drivers.length >= filter.limit,
        totalCount: drivers.length,
      );
    } catch (e) {
      debugPrint('Error fetching drivers: $e');
      rethrow;
    }
  }

  @override
  Future<DriverStatusCounts> fetchDriverCounts() async {
    try {
      final response = await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client
            .from('users')
            .select('driver_verification_status')
            .eq('role', 'Driver'),
        'fetch driver counts',
      );

      final List<dynamic> data = response as List<dynamic>;
      int pending = 0;
      int approved = 0;
      int rejected = 0;

      for (final item in data) {
        final row = item as Map<String, dynamic>;
        final status = row['driver_verification_status'] as String? ?? 'pending';
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'approved':
            approved++;
            break;
          case 'rejected':
            rejected++;
            break;
        }
      }

      return DriverStatusCounts(
        total: data.length,
        pending: pending,
        approved: approved,
        rejected: rejected,
      );
    } catch (e) {
      debugPrint('Error fetching driver counts: $e');
      rethrow;
    }
  }

  @override
  Future<DriverEntity?> fetchDriverById(String driverId) async {
    try {
      final response = await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client
            .from('users')
            .select('''
              id,
              first_name,
              last_name,
              phone_number,
              email,
              profile_photo_url,
              driver_verification_status,
              created_at,
              updated_at
            ''')
            .eq('id', driverId)
            .eq('role', 'Driver')
            .maybeSingle(),
        'fetch driver by id',
      );

      if (response == null) return null;
      final map = response as Map<String, dynamic>;
      return DriverModel.fromJson(map);
    } catch (e) {
      debugPrint('Error fetching driver by id: $e');
      rethrow;
    }
  }

  @override
  Future<List<DriverEntity>> searchDrivers(String query, {int limit = 20}) async {
    try {
      final searchTerm = '%$query%';
      final response = await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client
            .from('users')
            .select('''
              id,
              first_name,
              last_name,
              phone_number,
              email,
              profile_photo_url,
              driver_verification_status,
              created_at,
              updated_at
            ''')
            .eq('role', 'Driver')
            .or(
              'first_name.ilike.$searchTerm,'
              'last_name.ilike.$searchTerm,'
              'phone_number.ilike.$searchTerm,'
              'email.ilike.$searchTerm',
            )
            .order('created_at', ascending: false)
            .limit(limit),
        'search drivers',
      );

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) =>
              DriverModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error searching drivers: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // DRIVER PROFILE METHODS (from Step 12)
  // ==========================================================================

  Future<DriverProfile> fetchDriverProfile(String driverId) async {
    try {
      final response = await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client
            .from('users')
            .select('''
              id,
              first_name,
              last_name,
              phone_number,
              email,
              profile_photo_url,
              dob,
              id_no,
              driver_verification_status,
              verification_notes,
              driver_verified_at,
              driver_verified_by,
              created_at,
              updated_at,
              address_name,
              is_suspended,
              suspended_at,
              suspended_reason,
              suspended_by,
              suspension_ends_at
            ''')
            .eq('id', driverId)
            .single(),
        'fetch driver profile',
      );

      return DriverProfileModel.fromJson(response as Map<String, dynamic>).toEntity();
    } catch (e) {
      debugPrint('Error fetching driver profile: $e');
      rethrow;
    }
  }

  Future<List<VehicleEntity>> fetchDriverVehicles(String driverId) async {
    try {
      final response = await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client
            .from('vehicles')
            .select('''
              id,
              driver_id,
              make,
              model,
              year,
              color,
              license_plate,
              type,
              capacity_tons,
              photo_url,
              insurance_document_url,
              registration_document_url,
              roadworthy_certificate_url,
              additional_photos,
              verification_status,
              rejection_reason,
              admin_notes,
              verified_by,
              verified_at,
              created_at
            ''')
            .eq('driver_id', driverId)
            .order('created_at', ascending: false),
        'fetch driver vehicles',
      );

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) =>
              VehicleModel.fromJson(json as Map<String, dynamic>).toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error fetching driver vehicles: $e');
      rethrow;
    }
  }

  Future<List<DriverDocument>> fetchDriverDocuments(String driverId) async {
    try {
      // Use adminClient to bypass RLS — driver_docs has no admin read policy
      final response = await _supabaseProvider.adminClient
          .from('driver_docs')
          .select('''
            id,
            driver_id,
            doc_type,
            doc_url,
            verification_status,
            verified_at,
            verified_by,
            rejection_reason,
            admin_notes,
            expiry_date,
            created_at,
            modified_at
          ''')
          .eq('driver_id', driverId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) =>
              DriverDocumentModel.fromJson(json as Map<String, dynamic>).toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error fetching driver documents: $e');
      rethrow;
    }
  }

  Future<List<ApprovalHistoryItem>> fetchApprovalHistory(String driverId) async {
    try {
      final response = await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client
            .from('driver_approval_history')
            .select('''
              id,
              driver_id,
              admin_id,
              previous_status,
              new_status,
              reason,
              notes,
              documents_reviewed,
              created_at,
              admin:users!driver_approval_history_admin_id_fkey(
                first_name,
                last_name
              )
            ''')
            .eq('driver_id', driverId)
            .order('created_at', ascending: false),
        'fetch approval history',
      );

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) =>
              ApprovalHistoryModel.fromJson(json as Map<String, dynamic>).toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error fetching approval history: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // APPROVAL WORKFLOW METHODS (Step 14 - NEW)
  // ==========================================================================

  /// Approve a driver
  /// Uses the database function update_driver_verification which handles:
  /// - Updating user's driver_verification_status to 'approved'
  /// - Setting driver_verified_by and driver_verified_at
  /// - Logging to driver_approval_history
  /// - Logging admin action
  @override
  Future<bool> approveDriver(String driverId, String adminId) async {
    try {
      debugPrint('Approving driver: $driverId by admin: $adminId');

      final response = await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client.rpc(
          'update_driver_verification',
          params: {
            'p_driver_id': driverId,
            'p_admin_id': adminId,
            'p_new_status': 'approved',
            'p_reason': null,
            'p_notes': null,
          },
        ),
        'approve driver',
      );

      debugPrint('Driver approved successfully: $response');

      // Send notification to driver
      await _sendApprovalNotification(
        driverId: driverId,
      );

      return true;
    } catch (e) {
      debugPrint('Error approving driver: $e');
      rethrow;
    }
  }

  /// Reject a driver with a reason
  /// Uses the database function update_driver_verification
  @override
  Future<bool> rejectDriver(String driverId, String adminId, String reason) async {
    try {
      debugPrint('Rejecting driver: $driverId by admin: $adminId');
      debugPrint('Reason: $reason');

      final response = await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client.rpc(
          'update_driver_verification',
          params: {
            'p_driver_id': driverId,
            'p_admin_id': adminId,
            'p_new_status': 'rejected',
            'p_reason': reason,
            'p_notes': null,
          },
        ),
        'reject driver',
      );

      debugPrint('Driver rejected successfully: $response');

      // Send notification to driver
      await _sendRejectionNotification(
        driverId: driverId,
        reason: reason,
      );

      return true;
    } catch (e) {
      debugPrint('Error rejecting driver: $e');
      rethrow;
    }
  }

  /// Request additional documents from a driver
  /// Updates status to 'documents_requested' and sends notification
  @override
  Future<bool> requestDocuments(
    String driverId,
    String adminId,
    List<String> documentTypes,
    String? message,
  ) async {
    try {
      debugPrint('Requesting documents from driver: $driverId');
      debugPrint('Documents: ${documentTypes.join(', ')}');

      // Convert document types to JSON array
      final documentsJson = documentTypes.map((d) => <String, dynamic>{
        'type': d,
        'name': d,
      }).toList();

      // Update driver status to documents_requested
      final response = await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client.rpc(
          'update_driver_verification',
          params: {
            'p_driver_id': driverId,
            'p_admin_id': adminId,
            'p_new_status': 'documents_requested',
            'p_reason': 'Additional documents required',
            'p_notes': message,
          },
        ),
        'request documents - update status',
      );

      debugPrint('Driver status updated to documents_requested: $response');

      // Log the specific documents requested
      await _logDocumentsRequested(
        driverId: driverId,
        adminId: adminId,
        documents: documentsJson,
        message: message ?? '',
      );

      // Send notification to driver
      await _sendDocumentRequestNotification(
        driverId: driverId,
        documentTypes: documentTypes,
        message: message ?? '',
      );

      return true;
    } catch (e) {
      debugPrint('Error requesting documents: $e');
      rethrow;
    }
  }

  /// Log a custom approval action to the history
  Future<void> logApprovalAction({
    required String driverId,
    required String adminId,
    required String action,
    required String previousStatus,
    required String newStatus,
    String? reason,
    String? notes,
    List<Map<String, dynamic>>? documentsReviewed,
  }) async {
    try {
      await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client
            .from('driver_approval_history')
            .insert({
          'driver_id': driverId,
          'admin_id': adminId,
          'previous_status': previousStatus,
          'new_status': newStatus,
          'reason': reason,
          'notes': notes,
          'documents_reviewed': documentsReviewed ?? <Map<String, dynamic>>[],
        }),
        'log approval action',
      );

      debugPrint('Approval action logged: $action');
    } catch (e) {
      debugPrint('Error logging approval action: $e');
      // Don't rethrow - logging failure shouldn't break the main operation
    }
  }

  // ==========================================================================
  // PRIVATE HELPER METHODS
  // ==========================================================================

  /// Send approval notification to driver
  Future<void> _sendApprovalNotification({
    required String driverId,
  }) async {
    try {
      const message = 'Congratulations! Your driver application has been approved!\n\n'
          'You can now:\n'
          '- Browse and bid on available shipments\n'
          '- Accept delivery jobs\n'
          '- Start earning\n\n'
          'Welcome to LoadRunner! Safe travels!';

      await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client.from('notifications').insert({
          'user_id': driverId,
          'message': message,
          'type': 'general',
          'delivery_method': 'both', // Push and SMS
          'related_id': driverId,
        }),
        'send approval notification',
      );

      debugPrint('Approval notification sent to driver');
    } catch (e) {
      debugPrint('Error sending approval notification: $e');
      // Don't rethrow - notification failure shouldn't break approval
    }
  }

  /// Send rejection notification to driver
  Future<void> _sendRejectionNotification({
    required String driverId,
    required String reason,
  }) async {
    try {
      final message = 'We regret to inform you that your driver application has been rejected.\n\n'
          'Reason: $reason\n\n'
          'If you believe this was a mistake or have additional documentation to provide, please contact support.\n\n'
          'You may re-apply after addressing the issues mentioned above.';

      await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client.from('notifications').insert({
          'user_id': driverId,
          'message': message,
          'type': 'general',
          'delivery_method': 'both',
          'related_id': driverId,
        }),
        'send rejection notification',
      );

      debugPrint('Rejection notification sent to driver');
    } catch (e) {
      debugPrint('Error sending rejection notification: $e');
    }
  }

  /// Send document request notification to driver
  Future<void> _sendDocumentRequestNotification({
    required String driverId,
    required List<String> documentTypes,
    required String message,
  }) async {
    try {
      final documentList = documentTypes.map((d) => '- $d').join('\n');
      final notificationMessage =
          'Additional Documents Required\n\n'
          'We need you to upload the following documents to complete your verification:\n\n'
          '$documentList\n\n'
          'Admin note: $message\n\n'
          'Please upload these documents as soon as possible to continue your application.';

      await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client.from('notifications').insert({
          'user_id': driverId,
          'message': notificationMessage,
          'type': 'general',
          'delivery_method': 'both',
          'related_id': driverId,
        }),
        'send document request notification',
      );

      debugPrint('Document request notification sent to driver');
    } catch (e) {
      debugPrint('Error sending document request notification: $e');
    }
  }

  /// Log the specific documents that were requested
  Future<void> _logDocumentsRequested({
    required String driverId,
    required String adminId,
    required List<Map<String, dynamic>> documents,
    required String message,
  }) async {
    try {
      // Update the most recent approval history entry with documents_reviewed
      // This is already done by update_driver_verification, but we can add
      // more details if needed
      await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client
            .from('driver_approval_history')
            .update({
          'documents_reviewed': documents,
        })
            .eq('driver_id', driverId)
            .eq('admin_id', adminId)
            .eq('new_status', 'documents_requested')
            .order('created_at', ascending: false)
            .limit(1),
        'log documents requested',
      );

      debugPrint('Documents requested logged');
    } catch (e) {
      debugPrint('Error logging documents requested: $e');
    }
  }

  // ==========================================================================
  // ADDITIONAL UTILITY METHODS
  // ==========================================================================

  /// Get the current admin user ID from the session
  Future<String?> getCurrentAdminId() async {
    return _sessionService.userId;
  }

  /// Check if a driver can be approved (has all required documents)
  Future<bool> canApproveDriver(String driverId) async {
    try {
      final documents = await fetchDriverDocuments(driverId);

      // Check for required documents
      final hasLicenseFront =
          documents.any((d) => d.docType == 'license_front');
      final hasLicenseBack =
          documents.any((d) => d.docType == 'license_back');
      final hasIdDocument =
          documents.any((d) => d.docType == 'id_document');

      return hasLicenseFront && hasLicenseBack && hasIdDocument;
    } catch (e) {
      debugPrint('Error checking if driver can be approved: $e');
      return false;
    }
  }
}
