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
  }

  /// Request additional documents from driver
  Future<void> requestDocuments(
    String driverId,
    String adminId,
    List<String> documentTypes, {
    String? message,
  }) async {
    // Get current status first
    final currentData = await _fetchDriverData(driverId);
    final previousStatus = currentData.verificationStatus;

    // Update driver status
    await _jwtHandler.executeWithRecovery(
      () => _supabase.from('users').update({
        'driver_verification_status': 'documents_requested',
        'verification_notes': message,
      }).eq('id', driverId),
    );

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

    // TODO: Create notification for driver
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
