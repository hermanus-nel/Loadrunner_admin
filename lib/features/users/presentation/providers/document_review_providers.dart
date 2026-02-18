import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/document_review_repository.dart';
import '../../domain/entities/document_rejection_reason.dart';
import '../../domain/entities/document_reupload_reason.dart';
import 'document_queue_providers.dart';

// ============================================================
// DOCUMENT REVIEW STATE
// ============================================================

/// State for per-document review actions
class DocumentReviewState {
  final bool isActionLoading;
  final String? actionError;
  final String? actionSuccess;

  const DocumentReviewState({
    this.isActionLoading = false,
    this.actionError,
    this.actionSuccess,
  });

  DocumentReviewState copyWith({
    bool? isActionLoading,
    String? actionError,
    String? actionSuccess,
  }) {
    return DocumentReviewState(
      isActionLoading: isActionLoading ?? this.isActionLoading,
      actionError: actionError,
      actionSuccess: actionSuccess,
    );
  }

  bool get hasError => actionError != null;
  bool get hasSuccess => actionSuccess != null;
}

// ============================================================
// DOCUMENT REVIEW NOTIFIER
// ============================================================

/// StateNotifier for per-document review actions
class DocumentReviewNotifier extends StateNotifier<DocumentReviewState> {
  final DocumentReviewRepository _repository;

  DocumentReviewNotifier(this._repository)
      : super(const DocumentReviewState());

  /// Approve a single document
  Future<bool> approveDocument({
    required String documentId,
    required String driverId,
    required String docType,
    String? adminNotes,
  }) async {
    state = const DocumentReviewState(isActionLoading: true);

    try {
      final adminId = await _repository.getCurrentAdminId();
      if (adminId == null) {
        state = const DocumentReviewState(
          actionError: 'Unable to identify admin user',
        );
        return false;
      }

      final success = await _repository.approveDocument(
        documentId: documentId,
        driverId: driverId,
        adminId: adminId,
        docType: docType,
        adminNotes: adminNotes,
      );

      if (success) {
        state = const DocumentReviewState(
          actionSuccess: 'Document approved successfully',
        );
      } else {
        state = const DocumentReviewState(
          actionError: 'Failed to approve document',
        );
      }
      return success;
    } catch (e) {
      debugPrint('Error in approveDocument: $e');
      state = DocumentReviewState(actionError: 'Error: $e');
      return false;
    }
  }

  /// Reject a single document
  Future<bool> rejectDocument({
    required String documentId,
    required String driverId,
    required String docType,
    required DocumentRejectionReason reason,
    String? customReason,
    String? adminNotes,
  }) async {
    state = const DocumentReviewState(isActionLoading: true);

    try {
      final adminId = await _repository.getCurrentAdminId();
      if (adminId == null) {
        state = const DocumentReviewState(
          actionError: 'Unable to identify admin user',
        );
        return false;
      }

      final reasonText =
          reason.getMessageFragment(customReason: customReason);

      final success = await _repository.rejectDocument(
        documentId: documentId,
        driverId: driverId,
        adminId: adminId,
        docType: docType,
        rejectionReason: reasonText,
        adminNotes: adminNotes,
      );

      if (success) {
        state = const DocumentReviewState(
          actionSuccess: 'Document rejected',
        );
      } else {
        state = const DocumentReviewState(
          actionError: 'Failed to reject document',
        );
      }
      return success;
    } catch (e) {
      debugPrint('Error in rejectDocument: $e');
      state = DocumentReviewState(actionError: 'Error: $e');
      return false;
    }
  }

  /// Request a document re-upload
  Future<bool> requestReupload({
    required String documentId,
    required String driverId,
    required String docType,
    required DocumentReuploadReason reason,
    String? customReason,
    String? adminNotes,
  }) async {
    state = const DocumentReviewState(isActionLoading: true);

    try {
      final adminId = await _repository.getCurrentAdminId();
      if (adminId == null) {
        state = const DocumentReviewState(
          actionError: 'Unable to identify admin user',
        );
        return false;
      }

      final reasonText =
          reason.getMessageFragment(customReason: customReason);

      final success = await _repository.requestDocumentReupload(
        documentId: documentId,
        driverId: driverId,
        adminId: adminId,
        docType: docType,
        requestReason: reasonText,
        adminNotes: adminNotes,
      );

      if (success) {
        state = const DocumentReviewState(
          actionSuccess: 'Re-upload requested',
        );
      } else {
        state = const DocumentReviewState(
          actionError: 'Failed to request re-upload',
        );
      }
      return success;
    } catch (e) {
      debugPrint('Error in requestReupload: $e');
      state = DocumentReviewState(actionError: 'Error: $e');
      return false;
    }
  }

  /// Flag a document
  Future<bool> flagDocument({
    required String documentId,
    required String driverId,
    required String docType,
    required String flagReason,
    String? flagNotes,
  }) async {
    state = const DocumentReviewState(isActionLoading: true);

    try {
      final adminId = await _repository.getCurrentAdminId();
      if (adminId == null) {
        state = const DocumentReviewState(
          actionError: 'Unable to identify admin user',
        );
        return false;
      }

      final success = await _repository.flagDocument(
        documentId: documentId,
        driverId: driverId,
        adminId: adminId,
        docType: docType,
        flagReason: flagReason,
        flagNotes: flagNotes,
      );

      if (success) {
        state = const DocumentReviewState(
          actionSuccess: 'Document flagged',
        );
      } else {
        state = const DocumentReviewState(
          actionError: 'Failed to flag document',
        );
      }
      return success;
    } catch (e) {
      debugPrint('Error in flagDocument: $e');
      state = DocumentReviewState(actionError: 'Error: $e');
      return false;
    }
  }

  /// Approve all pending documents for a driver
  Future<bool> approveAllDocuments({
    required String driverId,
    String? adminNotes,
  }) async {
    state = const DocumentReviewState(isActionLoading: true);

    try {
      final adminId = await _repository.getCurrentAdminId();
      if (adminId == null) {
        state = const DocumentReviewState(
          actionError: 'Unable to identify admin user',
        );
        return false;
      }

      final success = await _repository.approveAllDocuments(
        driverId: driverId,
        adminId: adminId,
        adminNotes: adminNotes,
      );

      if (success) {
        state = const DocumentReviewState(
          actionSuccess: 'All documents approved',
        );
      } else {
        state = const DocumentReviewState(
          actionError: 'Failed to approve all documents',
        );
      }
      return success;
    } catch (e) {
      debugPrint('Error in approveAllDocuments: $e');
      state = DocumentReviewState(actionError: 'Error: $e');
      return false;
    }
  }

  /// Clear the action state
  void clearActionState() {
    state = const DocumentReviewState();
  }
}

// ============================================================
// PROVIDERS
// ============================================================

/// Provider for DocumentReviewNotifier
final documentReviewNotifierProvider =
    StateNotifierProvider.autoDispose<DocumentReviewNotifier, DocumentReviewState>(
  (ref) {
    final repository = ref.read(documentReviewRepositoryProvider);
    return DocumentReviewNotifier(repository);
  },
);
