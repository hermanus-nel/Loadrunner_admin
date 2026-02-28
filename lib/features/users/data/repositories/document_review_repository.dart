import 'package:flutter/foundation.dart';
import '../../../../core/services/jwt_recovery_handler.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/services/supabase_provider.dart';
import '../../domain/entities/document_queue_item.dart';
import '../models/document_queue_item_model.dart';
import '../models/driver_document_model.dart';

/// Repository for per-document review workflow operations.
///
/// Handles the document review queue, individual document actions
/// (approve, reject, request reupload, flag), notifications, and audit trail.
class DocumentReviewRepository {
  final SupabaseProvider _supabaseProvider;
  final JwtRecoveryHandler _jwtRecoveryHandler;
  final SessionService _sessionService;

  DocumentReviewRepository({
    required SupabaseProvider supabaseProvider,
    required JwtRecoveryHandler jwtRecoveryHandler,
    required SessionService sessionService,
  })  : _supabaseProvider = supabaseProvider,
        _jwtRecoveryHandler = jwtRecoveryHandler,
        _sessionService = sessionService;

  // ==========================================================================
  // UTILITY
  // ==========================================================================

  /// Get the current admin user ID from the session
  Future<String?> getCurrentAdminId() async {
    return _sessionService.userId;
  }

  // ==========================================================================
  // DOCUMENT QUEUE METHODS
  // ==========================================================================

  /// Fetch documents pending review, joined with driver info.
  /// Ordered oldest-first so the longest-waiting documents are reviewed first.
  Future<List<DocumentQueueItem>> fetchDocumentQueue({
    int limit = 20,
    int offset = 0,
    String? docTypeFilter,
  }) async {
    try {
      final response = await _jwtRecoveryHandler.executeWithRecovery(
        () {
          var query = _supabaseProvider.client
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
                modified_at,
                driver:users!driver_docs_driver_id_fkey(
                  first_name,
                  last_name,
                  phone_number,
                  profile_photo_url,
                  driver_verification_status,
                  created_at
                )
              ''')
              .inFilter(
                'verification_status',
                ['pending', 'under_review'],
              );

          if (docTypeFilter != null && docTypeFilter.isNotEmpty) {
            query = query.eq('doc_type', docTypeFilter);
          }

          return query
              .order('created_at', ascending: true)
              .range(offset, offset + limit - 1);
        },
        'fetch document queue',
      );

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => DocumentQueueItemModel.fromJson(
                json as Map<String, dynamic>,
              ).toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error fetching document queue: $e');
      rethrow;
    }
  }

  /// Fetch the count of documents pending review (for badge display).
  Future<int> fetchDocumentQueueCount() async {
    try {
      final response = await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client
            .from('driver_docs')
            .select('id')
            .inFilter('verification_status', ['pending', 'under_review']),
        'fetch document queue count',
      );

      final List<dynamic> data = response as List<dynamic>;
      return data.length;
    } catch (e) {
      debugPrint('Error fetching document queue count: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // PER-DOCUMENT ACTION METHODS
  // ==========================================================================

  /// Approve a single document.
  ///
  /// Updates the document status to 'approved', sends a notification,
  /// logs to approval history, and checks if all required docs are now approved.
  Future<bool> approveDocument({
    required String documentId,
    required String driverId,
    required String adminId,
    required String docType,
    String? adminNotes,
  }) async {
    try {
      debugPrint('Approving document $documentId for driver $driverId');

      // Update document status
      await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client.from('driver_docs').update({
          'verification_status': 'approved',
          'verified_by': adminId,
          'verified_at': DateTime.now().toUtc().toIso8601String(),
          'admin_notes': adminNotes,
          'modified_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', documentId),
        'approve document',
      );

      // Get the document label for the notification
      final docLabel = _getDocTypeLabel(docType);

      // Send notification
      await _sendNotification(
        driverId: driverId,
        message: 'Your $docLabel has been approved. '
            'Thank you for submitting valid documentation.',
        type: 'document_approved',
        relatedId: documentId,
      );

      // Log to approval history
      await _logDocumentAction(
        driverId: driverId,
        adminId: adminId,
        action: 'document_approved',
        docType: docType,
        documentId: documentId,
        notes: adminNotes,
      );

      // Check if all required docs are approved -> auto-verify driver
      await _checkAndHandleAllDocsApproved(
        driverId: driverId,
        adminId: adminId,
      );

      debugPrint('Document $documentId approved successfully');
      return true;
    } catch (e) {
      debugPrint('Error approving document: $e');
      rethrow;
    }
  }

  /// Reject a single document.
  ///
  /// Updates the document status to 'rejected', sends a notification with
  /// the rejection reason, and logs to approval history.
  Future<bool> rejectDocument({
    required String documentId,
    required String driverId,
    required String adminId,
    required String docType,
    required String rejectionReason,
    String? customReason,
    String? adminNotes,
  }) async {
    try {
      debugPrint('Rejecting document $documentId for driver $driverId');

      final reason = customReason ?? rejectionReason;

      // Update document status
      await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client.from('driver_docs').update({
          'verification_status': 'rejected',
          'rejection_reason': reason,
          'admin_notes': adminNotes,
          'modified_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', documentId),
        'reject document',
      );

      final docLabel = _getDocTypeLabel(docType);

      // Send notification
      await _sendNotification(
        driverId: driverId,
        message: 'Your $docLabel could not be approved. '
            'Reason: $reason. '
            'Please upload a new $docLabel from your driver profile.',
        type: 'document_rejected',
        relatedId: documentId,
      );

      // Log to approval history
      await _logDocumentAction(
        driverId: driverId,
        adminId: adminId,
        action: 'document_rejected',
        docType: docType,
        documentId: documentId,
        reason: reason,
        notes: adminNotes,
      );

      debugPrint('Document $documentId rejected successfully');
      return true;
    } catch (e) {
      debugPrint('Error rejecting document: $e');
      rethrow;
    }
  }

  /// Request a document re-upload.
  ///
  /// Updates the document status to 'documents_requested', sends a
  /// notification, and logs to approval history.
  Future<bool> requestDocumentReupload({
    required String documentId,
    required String driverId,
    required String adminId,
    required String docType,
    required String requestReason,
    String? customReason,
    String? adminNotes,
  }) async {
    try {
      debugPrint(
        'Requesting reupload of document $documentId for driver $driverId',
      );

      final reason = customReason ?? requestReason;

      // Update document status
      await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client.from('driver_docs').update({
          'verification_status': 'documents_requested',
          'admin_notes': adminNotes,
          'modified_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', documentId),
        'request document reupload',
      );

      final docLabel = _getDocTypeLabel(docType);

      // Send notification
      await _sendNotification(
        driverId: driverId,
        message: 'We need you to re-upload your $docLabel. '
            '$reason '
            'Please open your driver profile and upload a new copy.',
        type: 'document_reupload_requested',
        relatedId: documentId,
      );

      // Log to approval history
      await _logDocumentAction(
        driverId: driverId,
        adminId: adminId,
        action: 'document_reupload_requested',
        docType: docType,
        documentId: documentId,
        reason: reason,
        notes: adminNotes,
      );

      debugPrint('Document $documentId reupload requested successfully');
      return true;
    } catch (e) {
      debugPrint('Error requesting document reupload: $e');
      rethrow;
    }
  }

  /// Flag a document for fraud/suspicious content.
  ///
  /// Inserts into flagged_documents, updates the document status to
  /// 'documents_requested', and sends a neutral notification (no mention
  /// of fraud).
  Future<bool> flagDocument({
    required String documentId,
    required String driverId,
    required String adminId,
    required String docType,
    required String flagReason,
    String? flagNotes,
  }) async {
    try {
      debugPrint('Flagging document $documentId for driver $driverId');

      // Insert into flagged_documents
      await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client.from('flagged_documents').insert({
          'document_id': documentId,
          'driver_id': driverId,
          'flagged_by': adminId,
          'reason': flagReason,
          'notes': flagNotes,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        }),
        'flag document - insert',
      );

      // Update document status to documents_requested
      await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client.from('driver_docs').update({
          'verification_status': 'documents_requested',
          'admin_notes': flagNotes,
          'modified_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', documentId),
        'flag document - update status',
      );

      final docLabel = _getDocTypeLabel(docType);

      // Send NEUTRAL notification (no mention of fraud)
      await _sendNotification(
        driverId: driverId,
        message: 'We were unable to verify your $docLabel. '
            'Please upload a new copy from your driver profile.',
        type: 'document_reupload_requested',
        relatedId: documentId,
      );

      // Log to approval history
      await _logDocumentAction(
        driverId: driverId,
        adminId: adminId,
        action: 'document_flagged',
        docType: docType,
        documentId: documentId,
        reason: flagReason,
        notes: flagNotes,
      );

      debugPrint('Document $documentId flagged successfully');
      return true;
    } catch (e) {
      debugPrint('Error flagging document: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // BULK ACTION METHODS
  // ==========================================================================

  /// Approve all pending/under_review documents for a driver.
  ///
  /// Approves each document individually with its own notification.
  /// A DB trigger (`trg_auto_verify_driver`) may auto-verify the driver
  /// when docs are approved. This method captures the driver's status
  /// beforehand and restores it so that only the documents are affected.
  Future<bool> approveAllDocuments({
    required String driverId,
    required String adminId,
    String? adminNotes,
  }) async {
    try {
      debugPrint('Approving all documents for driver $driverId');

      // Capture driver's current verification status before any doc updates,
      // because the DB trigger may auto-verify the driver.
      final driverRow = await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client
            .from('users')
            .select('driver_verification_status, verification_notes')
            .eq('id', driverId)
            .single(),
        'snapshot driver status before bulk approve',
      );
      final statusBefore =
          driverRow['driver_verification_status'] as String?;
      final notesBefore = driverRow['verification_notes'] as String?;

      // Fetch all pending/under_review docs for this driver
      final response = await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client
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
            .inFilter(
              'verification_status',
              ['pending', 'under_review', 'documents_requested'],
            ),
        'fetch pending docs for bulk approve',
      );

      final List<dynamic> data = response as List<dynamic>;
      final docs = data
          .map((json) =>
              DriverDocumentModel.fromJson(json as Map<String, dynamic>)
                  .toEntity())
          .toList();

      if (docs.isEmpty) {
        debugPrint('No pending documents to approve');
        return true;
      }

      // Approve each document
      for (final doc in docs) {
        await _jwtRecoveryHandler.executeWithRecovery(
          () => _supabaseProvider.client.from('driver_docs').update({
            'verification_status': 'approved',
            'verified_by': adminId,
            'verified_at': DateTime.now().toUtc().toIso8601String(),
            'admin_notes': adminNotes,
            'modified_at': DateTime.now().toUtc().toIso8601String(),
          }).eq('id', doc.id),
          'bulk approve document ${doc.id}',
        );

        final docLabel = _getDocTypeLabel(doc.docType);

        // Send individual notification for each document
        await _sendNotification(
          driverId: driverId,
          message: 'Your $docLabel has been approved. '
              'Thank you for submitting valid documentation.',
          type: 'document_approved',
          relatedId: doc.id,
        );

        // Log each approval
        await _logDocumentAction(
          driverId: driverId,
          adminId: adminId,
          action: 'document_approved',
          docType: doc.docType,
          documentId: doc.id,
          notes: adminNotes,
        );
      }

      // The DB trigger (trg_auto_verify_driver) auto-verifies the driver
      // when all required docs are approved. Restore the original status
      // via the update_driver_verification RPC (SECURITY DEFINER) so that
      // "Approve Documents" only approves documents, not the driver.
      if (statusBefore != null && statusBefore != 'approved') {
        await _jwtRecoveryHandler.executeWithRecovery(
          () => _supabaseProvider.client.rpc(
            'update_driver_verification',
            params: {
              'p_driver_id': driverId,
              'p_admin_id': adminId,
              'p_new_status': statusBefore,
              'p_reason': 'bulk_doc_approve_status_restore',
              'p_notes': notesBefore,
            },
          ),
          'restore driver status after bulk doc approve',
        );
        debugPrint(
          'Restored driver $driverId status to $statusBefore '
          '(reverted auto-verify by DB trigger)',
        );
      }

      debugPrint('All ${docs.length} documents approved for driver $driverId');
      return true;
    } catch (e) {
      debugPrint('Error bulk approving documents: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  /// Send a push notification to the driver.
  Future<void> _sendNotification({
    required String driverId,
    required String message,
    required String type,
    required String relatedId,
  }) async {
    try {
      await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client.from('notifications').insert({
          'user_id': driverId,
          'message': message,
          'type': type,
          'delivery_method': 'push',
          'related_id': relatedId,
        }),
        'send document notification',
      );
      debugPrint('Notification sent to driver $driverId');
    } catch (e) {
      debugPrint('Error sending notification: $e');
      // Don't rethrow - notification failure shouldn't break the main action
    }
  }

  /// Check if all required documents (ID Document + Driver's License) are
  /// approved. If so, update the driver's verification status to 'approved'
  /// and send an "Account Verified" notification.
  ///
  /// This check is idempotent: if the driver is already approved, it skips.
  Future<void> _checkAndHandleAllDocsApproved({
    required String driverId,
    required String adminId,
  }) async {
    try {
      // First check current driver status
      final driverResponse = await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client
            .from('users')
            .select('driver_verification_status')
            .eq('id', driverId)
            .single(),
        'check driver status for all-docs-approved',
      );

      final currentStatus =
          driverResponse['driver_verification_status'] as String?;

      // If already approved, skip
      if (currentStatus == 'approved') {
        debugPrint(
          'Driver $driverId already approved, skipping all-docs check',
        );
        return;
      }

      // Fetch all documents for this driver
      final docsResponse = await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client
            .from('driver_docs')
            .select('doc_type, verification_status')
            .eq('driver_id', driverId),
        'fetch all docs for all-docs-approved check',
      );

      final List<dynamic> docsData = docsResponse as List<dynamic>;

      // Check required document types
      bool hasApprovedIdDoc = false;
      bool hasApprovedLicense = false;

      for (final doc in docsData) {
        final docMap = doc as Map<String, dynamic>;
        final docType = docMap['doc_type'] as String;
        final status = docMap['verification_status'] as String;

        if (status == 'approved') {
          if (docType == 'id_document' || docType == 'id_front') {
            hasApprovedIdDoc = true;
          }
          if (docType == 'license_front') {
            hasApprovedLicense = true;
          }
        }
      }

      if (hasApprovedIdDoc && hasApprovedLicense) {
        debugPrint(
          'All required docs approved for driver $driverId — verifying driver',
        );

        // Update driver verification status
        await _jwtRecoveryHandler.executeWithRecovery(
          () => _supabaseProvider.client.rpc(
            'update_driver_verification',
            params: {
              'p_driver_id': driverId,
              'p_admin_id': adminId,
              'p_new_status': 'approved',
              'p_reason': 'All required documents approved',
              'p_notes': null,
            },
          ),
          'auto-verify driver after all docs approved',
        );

        // Send Account Verified notification
        await _sendNotification(
          driverId: driverId,
          message: 'Congratulations! All your documents have been reviewed and '
              'approved. Your driver account is now fully verified and you '
              'can start bidding on available loads.',
          type: 'account_verified',
          relatedId: driverId,
        );

        debugPrint('Driver $driverId auto-verified successfully');
      } else {
        debugPrint(
          'Not all required docs approved yet for driver $driverId '
          '(ID: $hasApprovedIdDoc, License: $hasApprovedLicense)',
        );
      }
    } catch (e) {
      debugPrint('Error checking all-docs-approved: $e');
      // Don't rethrow — this is a secondary check
    }
  }

  /// Log a document review action to the driver_approval_history table.
  Future<void> _logDocumentAction({
    required String driverId,
    required String adminId,
    required String action,
    required String docType,
    required String documentId,
    String? reason,
    String? notes,
  }) async {
    try {
      await _jwtRecoveryHandler.executeWithRecovery(
        () => _supabaseProvider.client
            .from('driver_approval_history')
            .insert({
          'driver_id': driverId,
          'admin_id': adminId,
          'previous_status': action,
          'new_status': action,
          'reason': reason,
          'notes': notes,
          'documents_reviewed': [
            {'document_id': documentId, 'doc_type': docType},
          ],
        }),
        'log document action',
      );

      debugPrint('Document action logged: $action for doc $documentId');
    } catch (e) {
      debugPrint('Error logging document action: $e');
      // Don't rethrow — logging failure shouldn't break the main operation
    }
  }

  /// Get a human-readable label for a document type code.
  /// Mirrors the logic in DriverDocument.label.
  String _getDocTypeLabel(String docType) {
    switch (docType.toLowerCase()) {
      case 'license_front':
        return 'License (Front)';
      case 'license_back':
        return 'License (Back)';
      case 'id_document':
      case 'id_front':
        return 'ID Document';
      case 'id_back':
        return 'ID (Back)';
      case 'proof_of_address':
        return 'Proof of Address';
      case 'selfie':
        return 'Selfie';
      case 'profile_photo':
        return 'Profile Photo';
      case 'pdp':
        return 'PDP (Public Driving Permit)';
      default:
        return docType.replaceAll('_', ' ').split(' ').map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' ');
    }
  }
}
