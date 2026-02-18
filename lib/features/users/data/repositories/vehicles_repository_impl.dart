// lib/features/users/data/repositories/vehicles_repository_impl.dart
import 'package:flutter/foundation.dart';
import '../../../../core/services/jwt_recovery_handler.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/services/supabase_provider.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/repositories/vehicles_repository.dart';
import '../models/vehicle_model.dart';

/// Implementation of VehiclesRepository using Supabase
class VehiclesRepositoryImpl implements VehiclesRepository {
  final SupabaseProvider _supabaseProvider;
  final JwtRecoveryHandler _jwtRecoveryHandler;
  final SessionService _sessionService;

  VehiclesRepositoryImpl({
    required SupabaseProvider supabaseProvider,
    required JwtRecoveryHandler jwtRecoveryHandler,
    required SessionService sessionService,
  })  : _supabaseProvider = supabaseProvider,
        _jwtRecoveryHandler = jwtRecoveryHandler,
        _sessionService = sessionService;

  // ==========================================================================
  // VEHICLE FETCH METHODS
  // ==========================================================================

  @override
  Future<VehicleEntity> fetchVehicleDetails(String vehicleId) async {
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
              created_at,
              driver:users!vehicles_driver_id_fkey(
                first_name,
                last_name,
                phone_number
              )
            ''')
            .eq('id', vehicleId)
            .single(),
        'fetch vehicle details',
      );

      return VehicleModel.fromJson(response as Map<String, dynamic>).toEntity();
    } catch (e) {
      debugPrint('Error fetching vehicle details: $e');
      rethrow;
    }
  }

  @override
  Future<List<VehicleEntity>> fetchVehicles({
    String? status,
    String? driverId,
    String? searchQuery,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _jwtRecoveryHandler.executeWithRecovery(
        () async {
          var query = _supabaseProvider.client
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
                verification_status,
                created_at,
                driver:users!vehicles_driver_id_fkey(
                  first_name,
                  last_name,
                  phone_number
                )
              ''');

          // Apply status filter
          if (status != null && status.isNotEmpty) {
            query = query.eq('verification_status', status);
          }

          // Apply driver filter
          if (driverId != null && driverId.isNotEmpty) {
            query = query.eq('driver_id', driverId);
          }

          // Apply search filter
          if (searchQuery != null && searchQuery.isNotEmpty) {
            final searchTerm = '%$searchQuery%';
            query = query.or(
              'make.ilike.$searchTerm,'
              'model.ilike.$searchTerm,'
              'license_plate.ilike.$searchTerm',
            );
          }

          return query
              .order('created_at', ascending: false)
              .range(offset, offset + limit - 1);
        },
        'fetch vehicles',
      );

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => VehicleModel.fromJson(json as Map<String, dynamic>).toEntity()).toList();
    } catch (e) {
      debugPrint('Error fetching vehicles: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, int>> fetchVehicleCounts() async {
    try {
      final response = await _jwtRecoveryHandler.executeWithRecovery(
() => _supabaseProvider.client
            .from('vehicles')
            .select('verification_status'),
'fetch vehicle counts',
      );

      final List<dynamic> data = response as List<dynamic>;
      final counts = <String, int>{
        'all': data.length,
        'pending': 0,
        'under_review': 0,
        'documents_requested': 0,
        'approved': 0,
        'rejected': 0,
        'suspended': 0,
      };

      for (final item in data) {
        final status = item['verification_status'] as String? ?? 'pending';
        counts[status] = (counts[status] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      debugPrint('Error fetching vehicle counts: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // VEHICLE APPROVAL METHODS
  // ==========================================================================

  @override
  Future<bool> approveVehicle({
    required String vehicleId,
    required String adminId,
    String? notes,
  }) async {
    try {
      debugPrint('🟢 Approving vehicle $vehicleId by admin $adminId');

      // Get current vehicle status for audit log
      final currentVehicle = await fetchVehicleDetails(vehicleId);
      final previousStatus = currentVehicle.verificationStatus;

      // Update vehicle status
      await _jwtRecoveryHandler.executeWithRecovery(
() => _supabaseProvider.client
            .from('vehicles')
            .update({
          'verification_status': 'approved',
          'verified_by': adminId,
          'verified_at': DateTime.now().toUtc().toIso8601String(),
          'admin_notes': notes,
          'rejection_reason': null, // Clear any previous rejection reason
        }).eq('id', vehicleId),
'approve vehicle',
      );

      debugPrint('✅ Vehicle status updated to approved');

      // Log admin action
      await _logAdminAction(
        adminId: adminId,
        action: 'approve_vehicle',
        targetType: 'vehicle',
        targetId: vehicleId,
        details: {
          'previous_status': previousStatus,
          'new_status': 'approved',
          'notes': notes,
        },
      );

      // Send notification to driver
      await _sendVehicleApprovalNotification(
        driverId: currentVehicle.driverId,
        vehicleName: currentVehicle.displayName,
      );

      return true;
    } catch (e) {
      debugPrint('❌ Error approving vehicle: $e');
      rethrow;
    }
  }

  @override
  Future<bool> rejectVehicle({
    required String vehicleId,
    required String adminId,
    required String reason,
    String? notes,
  }) async {
    try {
      debugPrint('🔴 Rejecting vehicle $vehicleId by admin $adminId');
      debugPrint('📝 Reason: $reason');

      // Get current vehicle status for audit log
      final currentVehicle = await fetchVehicleDetails(vehicleId);
      final previousStatus = currentVehicle.verificationStatus;

      // Update vehicle status
      await _jwtRecoveryHandler.executeWithRecovery(
() => _supabaseProvider.client
            .from('vehicles')
            .update({
          'verification_status': 'rejected',
          'rejection_reason': reason,
          'admin_notes': notes,
        }).eq('id', vehicleId),
'reject vehicle',
      );

      debugPrint('✅ Vehicle status updated to rejected');

      // Log admin action
      await _logAdminAction(
        adminId: adminId,
        action: 'reject_vehicle',
        targetType: 'vehicle',
        targetId: vehicleId,
        details: {
          'previous_status': previousStatus,
          'new_status': 'rejected',
          'reason': reason,
          'notes': notes,
        },
      );

      // Send notification to driver
      await _sendVehicleRejectionNotification(
        driverId: currentVehicle.driverId,
        vehicleName: currentVehicle.displayName,
        reason: reason,
      );

      return true;
    } catch (e) {
      debugPrint('❌ Error rejecting vehicle: $e');
      rethrow;
    }
  }

  @override
  Future<bool> requestVehicleDocuments({
    required String vehicleId,
    required String adminId,
    required List<String> documentTypes,
    required String message,
  }) async {
    try {
      debugPrint('📤 Requesting documents for vehicle $vehicleId');

      // Get current vehicle info
      final currentVehicle = await fetchVehicleDetails(vehicleId);
      final previousStatus = currentVehicle.verificationStatus;

      // Update vehicle status to documents_requested
      await _jwtRecoveryHandler.executeWithRecovery(
() => _supabaseProvider.client
            .from('vehicles')
            .update({
          'verification_status': 'documents_requested',
          'admin_notes': message,
        }).eq('id', vehicleId),
'request vehicle documents',
      );

      debugPrint('✅ Vehicle status updated to documents_requested');

      // Log admin action
      await _logAdminAction(
        adminId: adminId,
        action: 'request_vehicle_documents',
        targetType: 'vehicle',
        targetId: vehicleId,
        details: {
          'previous_status': previousStatus,
          'new_status': 'documents_requested',
          'requested_documents': documentTypes,
          'message': message,
        },
      );

      // Send notification to driver
      await _sendVehicleDocumentRequestNotification(
        driverId: currentVehicle.driverId,
        vehicleName: currentVehicle.displayName,
        documentTypes: documentTypes,
        message: message,
      );

      return true;
    } catch (e) {
      debugPrint('❌ Error requesting vehicle documents: $e');
      rethrow;
    }
  }

  @override
  Future<bool> markVehicleUnderReview({
    required String vehicleId,
    required String adminId,
    String? notes,
  }) async {
    try {
      debugPrint('🔵 Marking vehicle $vehicleId as under review by admin $adminId');

      // Get current vehicle status for audit log
      final currentVehicle = await fetchVehicleDetails(vehicleId);
      final previousStatus = currentVehicle.verificationStatus;

      // Update vehicle status
      await _jwtRecoveryHandler.executeWithRecovery(
() => _supabaseProvider.client
            .from('vehicles')
            .update({
          'verification_status': 'under_review',
          'admin_notes': notes,
        }).eq('id', vehicleId),
'mark vehicle under review',
      );

      debugPrint('✅ Vehicle status updated to under_review');

      // Log admin action
      await _logAdminAction(
        adminId: adminId,
        action: 'review_vehicle',
        targetType: 'vehicle',
        targetId: vehicleId,
        details: {
          'previous_status': previousStatus,
          'new_status': 'under_review',
          'notes': notes,
        },
      );

      // Send notification to driver
      await _sendVehicleUnderReviewNotification(
        driverId: currentVehicle.driverId,
        vehicleName: currentVehicle.displayName,
      );

      return true;
    } catch (e) {
      debugPrint('❌ Error marking vehicle under review: $e');
      rethrow;
    }
  }

  @override
  Future<bool> suspendVehicle({
    required String vehicleId,
    required String adminId,
    required String reason,
    String? notes,
  }) async {
    try {
      debugPrint('🟤 Suspending vehicle $vehicleId by admin $adminId');
      debugPrint('📝 Reason: $reason');

      // Get current vehicle status for audit log
      final currentVehicle = await fetchVehicleDetails(vehicleId);
      final previousStatus = currentVehicle.verificationStatus;

      // Update vehicle status
      await _jwtRecoveryHandler.executeWithRecovery(
() => _supabaseProvider.client
            .from('vehicles')
            .update({
          'verification_status': 'suspended',
          'rejection_reason': reason,
          'admin_notes': notes,
        }).eq('id', vehicleId),
'suspend vehicle',
      );

      debugPrint('✅ Vehicle status updated to suspended');

      // Log admin action
      await _logAdminAction(
        adminId: adminId,
        action: 'suspend_vehicle',
        targetType: 'vehicle',
        targetId: vehicleId,
        details: {
          'previous_status': previousStatus,
          'new_status': 'suspended',
          'reason': reason,
          'notes': notes,
        },
      );

      // Send notification to driver
      await _sendVehicleSuspensionNotification(
        driverId: currentVehicle.driverId,
        vehicleName: currentVehicle.displayName,
        reason: reason,
      );

      return true;
    } catch (e) {
      debugPrint('❌ Error suspending vehicle: $e');
      rethrow;
    }
  }

  @override
  Future<bool> reinstateVehicle({
    required String vehicleId,
    required String adminId,
    String? notes,
  }) async {
    try {
      debugPrint('🟢 Reinstating vehicle $vehicleId by admin $adminId');

      // Get current vehicle status for audit log
      final currentVehicle = await fetchVehicleDetails(vehicleId);
      final previousStatus = currentVehicle.verificationStatus;

      // Update vehicle status
      await _jwtRecoveryHandler.executeWithRecovery(
() => _supabaseProvider.client
            .from('vehicles')
            .update({
          'verification_status': 'approved',
          'verified_by': adminId,
          'verified_at': DateTime.now().toUtc().toIso8601String(),
          'admin_notes': notes,
          'rejection_reason': null, // Clear suspension reason
        }).eq('id', vehicleId),
'reinstate vehicle',
      );

      debugPrint('✅ Vehicle status updated to approved (reinstated)');

      // Log admin action
      await _logAdminAction(
        adminId: adminId,
        action: 'reinstate_vehicle',
        targetType: 'vehicle',
        targetId: vehicleId,
        details: {
          'previous_status': previousStatus,
          'new_status': 'approved',
          'notes': notes,
        },
      );

      // Send notification to driver
      await _sendVehicleReinstateNotification(
        driverId: currentVehicle.driverId,
        vehicleName: currentVehicle.displayName,
      );

      return true;
    } catch (e) {
      debugPrint('❌ Error reinstating vehicle: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // UTILITY METHODS
  // ==========================================================================

  @override
  Future<String?> getCurrentAdminId() async {
    return _sessionService.userId;
  }

  @override
  Future<bool> canApproveVehicle(String vehicleId) async {
    try {
      final vehicle = await fetchVehicleDetails(vehicleId);

      // Check for required documents
      final hasPhoto = vehicle.photoUrl != null;
      final hasRegistration = vehicle.registrationDocumentUrl != null;
      final hasInsurance = vehicle.insuranceDocumentUrl != null;

      return hasPhoto && hasRegistration && hasInsurance;
    } catch (e) {
      debugPrint('Error checking if vehicle can be approved: $e');
      return false;
    }
  }

  @override
  Future<List<VehicleApprovalHistoryItem>> fetchVehicleHistory(String vehicleId) async {
    try {
      final response = await _jwtRecoveryHandler.executeWithRecovery(
() => _supabaseProvider.client
            .from('admin_audit_logs')
            .select('''
              id,
              admin_id,
              action,
              details,
              created_at,
              admin:users!admin_audit_logs_admin_id_fkey(
                first_name,
                last_name
              )
            ''')
            .eq('target_type', 'vehicle')
            .eq('target_id', vehicleId)
            .order('created_at', ascending: false)
            .limit(20),
'fetch vehicle history',
      );

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) {
        final details = json['details'] as Map<String, dynamic>? ?? {};
        final admin = json['admin'] as Map<String, dynamic>?;
        final adminFirstName = admin?['first_name'] as String?;
        final adminLastName = admin?['last_name'] as String?;
        final adminName = (adminFirstName != null || adminLastName != null)
            ? '${adminFirstName ?? ''} ${adminLastName ?? ''}'.trim()
            : null;

        return VehicleApprovalHistoryItem(
          id: json['id'] as String,
          vehicleId: vehicleId,
          adminId: json['admin_id'] as String,
          adminName: adminName,
          previousStatus: details['previous_status'] as String? ?? 'unknown',
          newStatus: details['new_status'] as String? ?? 'unknown',
          reason: details['reason'] as String?,
          notes: details['notes'] as String?,
          createdAt: DateTime.parse(json['created_at'] as String),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching vehicle history: $e');
      return [];
    }
  }

  // ==========================================================================
  // PRIVATE HELPER METHODS
  // ==========================================================================

  /// Log an admin action to the audit log
  Future<void> _logAdminAction({
    required String adminId,
    required String action,
    required String targetType,
    required String targetId,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _jwtRecoveryHandler.executeWithRecovery(
() => _supabaseProvider.client
            .from('admin_audit_logs')
            .insert({
          'admin_id': adminId,
          'action': action,
          'target_type': targetType,
          'target_id': targetId,
          'details': details ?? {},
        }),
'log admin action',
      );

      debugPrint('✅ Admin action logged: $action');
    } catch (e) {
      debugPrint('⚠️ Error logging admin action: $e');
      // Don't rethrow - logging failure shouldn't break the main operation
    }
  }

  /// Send vehicle approval notification to driver
  Future<void> _sendVehicleApprovalNotification({
    required String driverId,
    required String vehicleName,
  }) async {
    try {
      final message = '''
🚗 Vehicle Approved!

Great news! Your vehicle "$vehicleName" has been verified and approved.

You can now use this vehicle for deliveries. Drive safely!
''';

      await _jwtRecoveryHandler.executeWithRecovery(
() => _supabaseProvider.client.from('notifications').insert({
          'user_id': driverId,
          'message': message.trim(),
          'type': 'general',
          'delivery_method': 'both',
          'related_id': driverId,
        }),
'send vehicle approval notification',
      );

      debugPrint('✅ Vehicle approval notification sent');
    } catch (e) {
      debugPrint('⚠️ Error sending vehicle approval notification: $e');
    }
  }

  /// Send vehicle rejection notification to driver
  Future<void> _sendVehicleRejectionNotification({
    required String driverId,
    required String vehicleName,
    required String reason,
  }) async {
    try {
      final message = '''
Vehicle Not Approved

We were unable to approve your vehicle "$vehicleName".

Reason: $reason

Please update your vehicle documents or information and try again. If you believe this was a mistake, contact support.
''';

      await _jwtRecoveryHandler.executeWithRecovery(
() => _supabaseProvider.client.from('notifications').insert({
          'user_id': driverId,
          'message': message.trim(),
          'type': 'general',
          'delivery_method': 'both',
          'related_id': driverId,
        }),
'send vehicle rejection notification',
      );

      debugPrint('✅ Vehicle rejection notification sent');
    } catch (e) {
      debugPrint('⚠️ Error sending vehicle rejection notification: $e');
    }
  }

  /// Send vehicle document request notification to driver
  Future<void> _sendVehicleDocumentRequestNotification({
    required String driverId,
    required String vehicleName,
    required List<String> documentTypes,
    required String message,
  }) async {
    try {
      final documentList = documentTypes.map((d) => '• $d').join('\n');
      final notificationMessage = '''
📄 Vehicle Documents Required

We need additional documents for your vehicle "$vehicleName":

$documentList

Admin note: $message

Please upload these documents as soon as possible.
''';

      await _jwtRecoveryHandler.executeWithRecovery(
() => _supabaseProvider.client.from('notifications').insert({
          'user_id': driverId,
          'message': notificationMessage.trim(),
          'type': 'general',
          'delivery_method': 'both',
          'related_id': driverId,
        }),
'send vehicle document request notification',
      );

      debugPrint('✅ Vehicle document request notification sent');
    } catch (e) {
      debugPrint('⚠️ Error sending vehicle document request notification: $e');
    }
  }

  /// Send vehicle under review notification to driver
  Future<void> _sendVehicleUnderReviewNotification({
    required String driverId,
    required String vehicleName,
  }) async {
    try {
      final message = '''
🔍 Vehicle Under Review

Your vehicle "$vehicleName" is currently being reviewed by our team.

We will notify you once the review is complete. Thank you for your patience.
''';

      await _jwtRecoveryHandler.executeWithRecovery(
() => _supabaseProvider.client.from('notifications').insert({
          'user_id': driverId,
          'message': message.trim(),
          'type': 'general',
          'delivery_method': 'both',
          'related_id': driverId,
        }),
'send vehicle under review notification',
      );

      debugPrint('✅ Vehicle under review notification sent');
    } catch (e) {
      debugPrint('⚠️ Error sending vehicle under review notification: $e');
    }
  }

  /// Send vehicle suspension notification to driver
  Future<void> _sendVehicleSuspensionNotification({
    required String driverId,
    required String vehicleName,
    required String reason,
  }) async {
    try {
      final message = '''
⚠️ Vehicle Suspended

Your vehicle "$vehicleName" has been suspended.

Reason: $reason

You will no longer be able to use this vehicle for deliveries until it is reinstated. If you believe this was a mistake, please contact support.
''';

      await _jwtRecoveryHandler.executeWithRecovery(
() => _supabaseProvider.client.from('notifications').insert({
          'user_id': driverId,
          'message': message.trim(),
          'type': 'general',
          'delivery_method': 'both',
          'related_id': driverId,
        }),
'send vehicle suspension notification',
      );

      debugPrint('✅ Vehicle suspension notification sent');
    } catch (e) {
      debugPrint('⚠️ Error sending vehicle suspension notification: $e');
    }
  }

  /// Send vehicle reinstatement notification to driver
  Future<void> _sendVehicleReinstateNotification({
    required String driverId,
    required String vehicleName,
  }) async {
    try {
      final message = '''
🚗 Vehicle Reinstated!

Great news! Your vehicle "$vehicleName" has been reinstated and approved.

You can now use this vehicle for deliveries again. Drive safely!
''';

      await _jwtRecoveryHandler.executeWithRecovery(
() => _supabaseProvider.client.from('notifications').insert({
          'user_id': driverId,
          'message': message.trim(),
          'type': 'general',
          'delivery_method': 'both',
          'related_id': driverId,
        }),
'send vehicle reinstate notification',
      );

      debugPrint('✅ Vehicle reinstate notification sent');
    } catch (e) {
      debugPrint('⚠️ Error sending vehicle reinstate notification: $e');
    }
  }
}
