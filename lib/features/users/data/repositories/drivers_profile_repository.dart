import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/jwt_recovery_handler.dart';
import '../../../../core/services/supabase_provider.dart';
import '../../../../core/services/core_providers.dart';
import '../../domain/entities/driver_profile.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/entities/driver_document.dart';
import '../../domain/entities/approval_history_item.dart';
import '../../domain/entities/driver_bank_account.dart';
import '../models/driver_profile_model.dart';
import '../models/vehicle_model.dart';
import '../models/driver_document_model.dart';
import '../models/approval_history_model.dart';
import '../models/driver_bank_account_model.dart';

/// Repository for driver profile operations
class DriversProfileRepository {
  final Ref _ref;

  DriversProfileRepository(this._ref);

  JwtRecoveryHandler get _jwtHandler => _ref.read(jwtRecoveryHandlerProvider);
  SupabaseClient get _supabase => _ref.read(supabaseProviderInstance).client;

  /// Fetch complete driver profile with all related data
  Future<DriverProfile> fetchDriverProfile(String driverId) async {
    // Fetch all data in parallel for better performance
    final results = await Future.wait([
      _fetchDriverData(driverId),
      fetchDriverVehicles(driverId),
      fetchDriverDocuments(driverId),
      fetchApprovalHistory(driverId),
      fetchDriverBankAccount(driverId),
    ]);

    final driverData = results[0] as DriverProfileModel;
    final vehicles = results[1] as List<VehicleEntity>;
    final documents = results[2] as List<DriverDocument>;
    final history = results[3] as List<ApprovalHistoryItem>;
    final bankAccount = results[4] as DriverBankAccount?;

    return driverData.toEntity(
      vehicles: vehicles,
      documents: documents,
      approvalHistory: history,
      bankAccount: bankAccount,
    );
  }

  /// Fetch driver basic data from users table
  Future<DriverProfileModel> _fetchDriverData(String driverId) async {
    final response = await _jwtHandler.executeWithRecovery(
      () => _supabase
          .from('users')
          .select()
          .eq('id', driverId)
          .single(),
    );

    return DriverProfileModel.fromJson(response);
  }

  /// Fetch driver's vehicles
  Future<List<VehicleEntity>> fetchDriverVehicles(String driverId) async {
    final response = await _jwtHandler.executeWithRecovery(
      () => _supabase
          .from('vehicles')
          .select()
          .eq('driver_id', driverId)
          .order('created_at', ascending: false),
    );

    return (response as List)
        .map((json) => VehicleModel.fromJson(json as Map<String, dynamic>).toEntity())
        .toList();
  }

  /// Fetch driver's documents
  Future<List<DriverDocument>> fetchDriverDocuments(String driverId) async {
    final response = await _jwtHandler.executeWithRecovery(
      () => _supabase
          .from('driver_docs')
          .select()
          .eq('driver_id', driverId)
          .order('created_at', ascending: false),
    );

    return (response as List)
        .map((json) => DriverDocumentModel.fromJson(json as Map<String, dynamic>).toEntity())
        .toList();
  }

  /// Fetch driver approval history with admin names
  Future<List<ApprovalHistoryItem>> fetchApprovalHistory(String driverId) async {
    final response = await _jwtHandler.executeWithRecovery(
      () => _supabase
          .from('driver_approval_history')
          .select('''
            *,
            admin:admin_id(first_name, last_name)
          ''')
          .eq('driver_id', driverId)
          .order('created_at', ascending: false),
    );

    return (response as List)
        .map((json) => ApprovalHistoryModel.fromJson(json as Map<String, dynamic>).toEntity())
        .toList();
  }

  /// Fetch driver's primary bank account
  Future<DriverBankAccount?> fetchDriverBankAccount(String driverId) async {
    try {
      final response = await _jwtHandler.executeWithRecovery(
        () => _supabase
            .from('driver_bank_accounts')
            .select()
            .eq('driver_id', driverId)
            .eq('is_primary', true)
            .eq('is_active', true)
            .limit(1)
            .maybeSingle(),
      );

      if (response == null) return null;
      return DriverBankAccountModel.fromJson(response).toEntity();
    } catch (e) {
      // Return null if no bank account found
      return null;
    }
  }

  /// Approve a driver
  Future<void> approveDriver(
    String driverId,
    String adminId, {
    String? notes,
  }) async {
    // Get current status first
    final currentData = await _fetchDriverData(driverId);
    final previousStatus = currentData.verificationStatus;

    // Update driver status
    await _jwtHandler.executeWithRecovery(
      () => _supabase.from('users').update({
        'driver_verification_status': 'approved',
        'driver_verified_at': DateTime.now().toIso8601String(),
        'driver_verified_by': adminId,
        'verification_notes': notes,
      }).eq('id', driverId),
    );

    // Log to approval history
    await _logApprovalAction(
      driverId: driverId,
      adminId: adminId,
      previousStatus: previousStatus,
      newStatus: 'approved',
      notes: notes,
    );

    // Log to admin audit logs
    try {
      await _supabase.from('admin_audit_logs').insert({
        'admin_id': adminId,
        'action': 'driver_approved',
        'target_type': 'user',
        'target_id': driverId,
        'new_values': {
          'previous_status': previousStatus,
          'new_status': 'approved',
          'notes': notes,
        },
      });
    } catch (_) {}
  }

  /// Reject a driver
  Future<void> rejectDriver(
    String driverId,
    String adminId,
    String reason, {
    String? notes,
  }) async {
    // Get current status first
    final currentData = await _fetchDriverData(driverId);
    final previousStatus = currentData.verificationStatus;

    // Update driver status
    await _jwtHandler.executeWithRecovery(
      () => _supabase.from('users').update({
        'driver_verification_status': 'rejected',
        'driver_verified_at': DateTime.now().toIso8601String(),
        'driver_verified_by': adminId,
        'verification_notes': notes,
      }).eq('id', driverId),
    );

    // Log to approval history
    await _logApprovalAction(
      driverId: driverId,
      adminId: adminId,
      previousStatus: previousStatus,
      newStatus: 'rejected',
      reason: reason,
      notes: notes,
    );

    // Log to admin audit logs
    try {
      await _supabase.from('admin_audit_logs').insert({
        'admin_id': adminId,
        'action': 'driver_rejected',
        'target_type': 'user',
        'target_id': driverId,
        'new_values': {
          'previous_status': previousStatus,
          'new_status': 'rejected',
          'reason': reason,
          'notes': notes,
        },
      });
    } catch (_) {}
  }

  /// Request additional documents from driver.
  ///
  /// Updates both `users.driver_verification_status` AND the individual
  /// `driver_docs` rows for each requested document type (latest row per type).
  Future<void> requestDocuments(
    String driverId,
    String adminId,
    List<String> documentTypes, {
    String? message,
  }) async {
    // Get current status first
    final currentData = await _fetchDriverData(driverId);
    final previousStatus = currentData.verificationStatus;

    // Update driver-level verification status
    await _jwtHandler.executeWithRecovery(
      () => _supabase.from('users').update({
        'driver_verification_status': 'documents_requested',
        'verification_notes': message,
      }).eq('id', driverId),
    );

    // Update individual driver_docs rows for each requested doc type.
    // For each type, find the latest row and set its status.
    for (final docType in documentTypes) {
      try {
        final rows = await _jwtHandler.executeWithRecovery(
          () => _supabase
              .from('driver_docs')
              .select('id')
              .eq('driver_id', driverId)
              .eq('doc_type', docType)
              .order('created_at', ascending: false)
              .limit(1),
        );

        final List<dynamic> data = rows as List<dynamic>;
        if (data.isNotEmpty) {
          final docId = (data.first as Map<String, dynamic>)['id'] as String;
          await _jwtHandler.executeWithRecovery(
            () => _supabase.from('driver_docs').update({
              'verification_status': 'documents_requested',
              'admin_notes': message,
              'modified_at': DateTime.now().toUtc().toIso8601String(),
            }).eq('id', docId),
          );
        }
      } catch (e) {
        // Don't break the loop if one doc type fails
        // The driver-level status is already updated
      }
    }

    // Log to approval history
    await _logApprovalAction(
      driverId: driverId,
      adminId: adminId,
      previousStatus: previousStatus,
      newStatus: 'documents_requested',
      reason: message,
      notes: 'Requested: ${documentTypes.join(", ")}',
      documentsReviewed: documentTypes,
    );

    // Log to admin audit logs
    try {
      await _supabase.from('admin_audit_logs').insert({
        'admin_id': adminId,
        'action': 'driver_documents_requested',
        'target_type': 'user',
        'target_id': driverId,
        'new_values': {
          'previous_status': previousStatus,
          'new_status': 'documents_requested',
          'document_types': documentTypes,
          'message': message,
        },
      });
    } catch (_) {}

    // Send notification to driver
    final docLabels = documentTypes.map(_getDocTypeLabel).join(', ');
    try {
      await _jwtHandler.executeWithRecovery(
        () => _supabase.from('notifications').insert({
          'user_id': driverId,
          'message': 'Please re-upload the following documents: $docLabels. '
              '${message != null ? message : "Please open your driver profile and upload new copies."}',
          'type': 'document_reupload_requested',
          'delivery_method': 'push',
          'related_id': driverId,
        }),
      );
    } catch (e) {
      // Don't fail the whole operation if notification fails
    }
  }

  /// Get a human-readable label for a document type code.
  String _getDocTypeLabel(String docType) {
    switch (docType.toLowerCase()) {
      case 'license_front':
        return "Driver's License";
      case 'id_document':
      case 'id_front':
        return 'ID Document';
      case 'proof_of_address':
        return 'Proof of Address';
      case 'pdp':
        return 'Professional Driving Permit (PDP)';
      case 'bank_confirmation':
      case 'bank_document':
        return 'Bank Confirmation Letter';
      default:
        return docType.replaceAll('_', ' ').split(' ').map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' ');
    }
  }

  /// Suspend a driver
  Future<void> suspendDriver(
    String driverId,
    String adminId,
    String reason, {
    DateTime? suspensionEndsAt,
  }) async {
    // Get current status first
    final currentData = await _fetchDriverData(driverId);
    final previousStatus = currentData.verificationStatus;

    // Update driver suspension status
    await _jwtHandler.executeWithRecovery(
      () => _supabase.from('users').update({
        'is_suspended': true,
        'suspended_at': DateTime.now().toIso8601String(),
        'suspended_reason': reason,
        'suspended_by': adminId,
        'suspension_ends_at': suspensionEndsAt?.toIso8601String(),
        'driver_verification_status': 'suspended',
      }).eq('id', driverId),
    );

    // Log to approval history
    await _logApprovalAction(
      driverId: driverId,
      adminId: adminId,
      previousStatus: previousStatus,
      newStatus: 'suspended',
      reason: reason,
      notes: suspensionEndsAt != null
          ? 'Suspension ends: ${suspensionEndsAt.toIso8601String()}'
          : 'Indefinite suspension',
    );

    // Log to admin audit logs
    try {
      await _supabase.from('admin_audit_logs').insert({
        'admin_id': adminId,
        'action': 'driver_suspended',
        'target_type': 'user',
        'target_id': driverId,
        'new_values': {
          'previous_status': previousStatus,
          'new_status': 'suspended',
          'reason': reason,
          'suspension_ends_at': suspensionEndsAt?.toIso8601String(),
        },
      });
    } catch (_) {}
  }

  /// Reinstate a suspended driver
  Future<void> reinstateDriver(
    String driverId,
    String adminId, {
    String? notes,
  }) async {
    // Get current status first
    final currentData = await _fetchDriverData(driverId);
    final previousStatus = currentData.verificationStatus;

    // Remove suspension
    await _jwtHandler.executeWithRecovery(
      () => _supabase.from('users').update({
        'is_suspended': false,
        'suspended_at': null,
        'suspended_reason': null,
        'suspended_by': null,
        'suspension_ends_at': null,
        'driver_verification_status': 'approved',
        'verification_notes': notes,
      }).eq('id', driverId),
    );

    // Log to approval history
    await _logApprovalAction(
      driverId: driverId,
      adminId: adminId,
      previousStatus: previousStatus,
      newStatus: 'approved',
      reason: 'Reinstated',
      notes: notes,
    );

    // Log to admin audit logs
    try {
      await _supabase.from('admin_audit_logs').insert({
        'admin_id': adminId,
        'action': 'driver_unsuspended',
        'target_type': 'user',
        'target_id': driverId,
        'new_values': {
          'previous_status': previousStatus,
          'new_status': 'approved',
          'notes': notes,
        },
      });
    } catch (_) {}
  }

  /// Fetch count of bank accounts pending verification
  Future<int> fetchPendingBankVerificationsCount() async {
    try {
      final response = await _jwtHandler.executeWithRecovery(
        () => _supabase
            .from('driver_bank_accounts')
            .select('id')
            .eq('is_verified', false)
            .eq('is_active', true)
            .isFilter('rejected_at', null),
      );

      final List<dynamic> data = response as List<dynamic>;
      return data.length;
    } catch (e) {
      // Return 0 if query fails
      return 0;
    }
  }

  /// Log an approval action to history
  Future<void> _logApprovalAction({
    required String driverId,
    required String adminId,
    required String? previousStatus,
    required String newStatus,
    String? reason,
    String? notes,
    List<String>? documentsReviewed,
  }) async {
    await _jwtHandler.executeWithRecovery(
      () => _supabase.from('driver_approval_history').insert({
        'driver_id': driverId,
        'admin_id': adminId,
        'previous_status': previousStatus,
        'new_status': newStatus,
        'reason': reason,
        'notes': notes,
        'documents_reviewed': documentsReviewed ?? [],
      }),
    );
  }
}

/// Provider for DriversProfileRepository
final driversProfileRepositoryProvider = Provider<DriversProfileRepository>((ref) {
  return DriversProfileRepository(ref);
});
