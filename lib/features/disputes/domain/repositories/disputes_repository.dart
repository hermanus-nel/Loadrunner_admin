// lib/features/disputes/domain/repositories/disputes_repository.dart

import '../entities/dispute_entity.dart';
import '../entities/evidence_entity.dart';

/// Result types for repository operations

class DisputesResult {
  final List<DisputeEntity> disputes;
  final DisputesPagination pagination;
  final DisputeStats stats;

  const DisputesResult({
    required this.disputes,
    required this.pagination,
    required this.stats,
  });
}

class DisputeDetailResult {
  final DisputeEntity dispute;
  final List<EvidenceEntity> evidence;
  final List<DisputeTimelineEvent> timeline;

  const DisputeDetailResult({
    required this.dispute,
    required this.evidence,
    required this.timeline,
  });
}

class ResolveDisputeResult {
  final bool success;
  final DisputeEntity? dispute;
  final String? error;

  const ResolveDisputeResult({
    required this.success,
    this.dispute,
    this.error,
  });

  factory ResolveDisputeResult.success(DisputeEntity dispute) =>
      ResolveDisputeResult(success: true, dispute: dispute);

  factory ResolveDisputeResult.failure(String error) =>
      ResolveDisputeResult(success: false, error: error);
}

class EscalateDisputeResult {
  final bool success;
  final DisputeEntity? dispute;
  final String? error;

  const EscalateDisputeResult({
    required this.success,
    this.dispute,
    this.error,
  });

  factory EscalateDisputeResult.success(DisputeEntity dispute) =>
      EscalateDisputeResult(success: true, dispute: dispute);

  factory EscalateDisputeResult.failure(String error) =>
      EscalateDisputeResult(success: false, error: error);
}

class AddEvidenceResult {
  final bool success;
  final EvidenceEntity? evidence;
  final String? error;

  const AddEvidenceResult({
    required this.success,
    this.evidence,
    this.error,
  });

  factory AddEvidenceResult.success(EvidenceEntity evidence) =>
      AddEvidenceResult(success: true, evidence: evidence);

  factory AddEvidenceResult.failure(String error) =>
      AddEvidenceResult(success: false, error: error);
}

class UpdateDisputeResult {
  final bool success;
  final DisputeEntity? dispute;
  final String? error;

  const UpdateDisputeResult({
    required this.success,
    this.dispute,
    this.error,
  });

  factory UpdateDisputeResult.success(DisputeEntity dispute) =>
      UpdateDisputeResult(success: true, dispute: dispute);

  factory UpdateDisputeResult.failure(String error) =>
      UpdateDisputeResult(success: false, error: error);
}

/// Abstract repository interface for disputes
abstract class DisputesRepository {
  /// Fetch list of disputes with filters and pagination
  Future<DisputesResult> fetchDisputes({
    DisputeFilters filters = const DisputeFilters(),
    DisputesPagination pagination = const DisputesPagination(),
  });

  /// Fetch full dispute details including evidence and timeline
  Future<DisputeDetailResult> fetchDisputeDetail({required String disputeId});

  /// Resolve a dispute with resolution details
  Future<ResolveDisputeResult> resolveDispute({
    required String disputeId,
    required ResolutionType resolution,
    required String notes,
    double? refundAmount,
  });

  /// Escalate a dispute to higher level
  Future<EscalateDisputeResult> escalateDispute({
    required String disputeId,
    required String reason,
  });

  /// Update dispute status
  Future<UpdateDisputeResult> updateDisputeStatus({
    required String disputeId,
    required DisputeStatus status,
    String? notes,
  });

  /// Update dispute priority
  Future<UpdateDisputeResult> updateDisputePriority({
    required String disputeId,
    required DisputePriority priority,
  });

  /// Assign dispute to admin
  Future<UpdateDisputeResult> assignDispute({
    required String disputeId,
    String? adminId, // null to unassign
  });

  /// Assign dispute to self
  Future<UpdateDisputeResult> assignToSelf({required String disputeId});

  /// Add evidence to dispute
  Future<AddEvidenceResult> addEvidence({
    required String disputeId,
    required EvidenceType type,
    required String description,
    String? fileUrl,
    Map<String, dynamic>? metadata,
  });

  /// Request evidence from user
  Future<bool> requestEvidence({
    required String disputeId,
    required String userId,
    required String message,
  });

  /// Add admin note to dispute
  Future<bool> addNote({
    required String disputeId,
    required String content,
    bool isInternal = true,
  });

  /// Fetch evidence for a dispute
  Future<List<EvidenceEntity>> fetchEvidence({required String disputeId});

  /// Fetch timeline events for a dispute
  Future<List<DisputeTimelineEvent>> fetchTimeline({required String disputeId});

  /// Get dispute statistics
  Future<DisputeStats> getStats({DateTime? startDate, DateTime? endDate});

  /// Get disputes by user (raised by or raised against)
  Future<List<DisputeEntity>> getDisputesByUser({required String userId});

  /// Get disputes for a specific shipment
  Future<List<DisputeEntity>> getDisputesByShipment({required String shipmentId});

  /// Get count of active disputes (open, investigating, awaiting evidence, escalated)
  Future<int> fetchActiveDisputesCount();
}
