// lib/features/disputes/data/repositories/disputes_repository_impl.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/dispute_entity.dart';
import '../../domain/entities/evidence_entity.dart';
import '../../domain/repositories/disputes_repository.dart';
import '../../../../core/services/jwt_recovery_handler.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/services/supabase_provider.dart';

class DisputesRepositoryImpl implements DisputesRepository {
  final JwtRecoveryHandler _jwtHandler;
  final SupabaseProvider _supabaseProvider;
  final SessionService _sessionService;

  DisputesRepositoryImpl({
    required JwtRecoveryHandler jwtHandler,
    required SupabaseProvider supabaseProvider,
    required SessionService sessionService,
  })  : _jwtHandler = jwtHandler,
        _supabaseProvider = supabaseProvider,
        _sessionService = sessionService;

  SupabaseClient get _supabase => _supabaseProvider.client;

  String? get _adminId => _sessionService.userId;

  @override
  Future<DisputesResult> fetchDisputes({
    DisputeFilters filters = const DisputeFilters(),
    DisputesPagination pagination = const DisputesPagination(),
  }) async {
    try {
      final offset = (pagination.page - 1) * pagination.pageSize;

      var query = _supabase.from('disputes').select('''
        *,
        raised_by_user:raised_by(id, first_name, last_name, phone_number, email, role, profile_photo_url),
        raised_against_user:raised_against(id, first_name, last_name, phone_number, email, role, profile_photo_url),
        admin_assigned_user:admin_assigned(id, first_name, last_name, phone_number, email, role, profile_photo_url),
        freight_post:freight_post_id(id, pickup_location, delivery_location, status, created_at),
        evidence:dispute_evidence(count)
      ''');

      // Apply filters
      if (filters.status != null) {
        query = query.eq('status', filters.status!.toJson());
      }
      if (filters.type != null) {
        query = query.eq('dispute_type', filters.type!.toJson());
      }
      if (filters.priority != null) {
        query = query.eq('priority', filters.priority!.toJson());
      }
      if (filters.startDate != null) {
        query = query.gte('created_at', filters.startDate!.toIso8601String());
      }
      if (filters.endDate != null) {
        query = query.lte('created_at', filters.endDate!.toIso8601String());
      }
      if (filters.assignedToMe == true) {
        final adminId = _adminId;
        if (adminId != null) {
          query = query.eq('admin_assigned', adminId);
        }
      }
      if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
        query = query.or(
          'title.ilike.%${filters.searchQuery}%,description.ilike.%${filters.searchQuery}%',
        );
      }

      final result = await _jwtHandler.executeWithRecovery(
        () => query
            .order('priority', ascending: true)
            .order('created_at', ascending: false)
            .range(offset, offset + pagination.pageSize - 1),
        'fetch disputes',
      );

      // Get total count
      var countQuery = _supabase.from('disputes').select('id');
      if (filters.status != null) {
        countQuery = countQuery.eq('status', filters.status!.toJson());
      }
      if (filters.type != null) {
        countQuery = countQuery.eq('dispute_type', filters.type!.toJson());
      }
      if (filters.priority != null) {
        countQuery = countQuery.eq('priority', filters.priority!.toJson());
      }

      final countResult = await _jwtHandler.executeWithRecovery(
        () => countQuery,
        'count disputes',
      );

      final data = result as List<dynamic>;
      final totalCount = (countResult as List).length;

      final disputes = data.map((json) => _mapToDisputeEntity(json as Map<String, dynamic>)).toList();

      // Get stats
      final stats = await getStats();

      return DisputesResult(
        disputes: disputes,
        pagination: pagination.copyWith(
          totalCount: totalCount,
          hasMore: offset + data.length < totalCount,
        ),
        stats: stats,
      );
    } catch (e) {
      debugPrint('Error fetching disputes: $e');
      rethrow;
    }
  }

  @override
  Future<DisputeDetailResult> fetchDisputeDetail({
    required String disputeId,
  }) async {
    try {
      final result = await _jwtHandler.executeWithRecovery(
        () => _supabase.from('disputes').select('''
          *,
          raised_by_user:raised_by(id, first_name, last_name, phone_number, email, role, profile_photo_url),
          raised_against_user:raised_against(id, first_name, last_name, phone_number, email, role, profile_photo_url),
          admin_assigned_user:admin_assigned(id, first_name, last_name, phone_number, email, role, profile_photo_url),
          resolved_by_user:resolved_by(id, first_name, last_name, phone_number, email, role, profile_photo_url),
          freight_post:freight_post_id(id, pickup_location, delivery_location, status, created_at)
        ''').eq('id', disputeId).single(),
        'fetch dispute detail $disputeId',
      );

      final dispute = _mapToDisputeEntity(result as Map<String, dynamic>);

      // Fetch evidence
      final evidence = await fetchEvidence(disputeId: disputeId);

      // Fetch timeline
      final timeline = await fetchTimeline(disputeId: disputeId);

      return DisputeDetailResult(
        dispute: dispute,
        evidence: evidence,
        timeline: timeline,
      );
    } catch (e) {
      debugPrint('Error fetching dispute detail: $e');
      rethrow;
    }
  }

  @override
  Future<ResolveDisputeResult> resolveDispute({
    required String disputeId,
    required ResolutionType resolution,
    required String notes,
    double? refundAmount,
  }) async {
    try {
      final adminId = _adminId;
      if (adminId == null) {
        return ResolveDisputeResult.failure('Not authenticated');
      }

      final result = await _jwtHandler.executeWithRecovery(
() => _supabase
            .from('disputes')
            .update({
              'status': 'resolved',
              'resolution': resolution.toJson(),
              'resolved_by': adminId,
              'resolved_at': DateTime.now().toIso8601String(),
              'refund_amount': refundAmount,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', disputeId)
            .select('''
              *,
              raised_by_user:raised_by(id, first_name, last_name, phone_number, email, role, profile_photo_url),
              raised_against_user:raised_against(id, first_name, last_name, phone_number, email, role, profile_photo_url)
            ''')
            .single(),
'resolve dispute $disputeId',
      );

      // Log audit
      await _logAudit(
        action: 'dispute_resolved',
        targetType: 'dispute',
        targetId: disputeId,
        newValues: {
          'resolution': resolution.toJson(),
          'notes': notes,
          'refund_amount': refundAmount,
        },
      );

      // Add to timeline
      await _addTimelineEvent(
        disputeId: disputeId,
        eventType: 'resolved',
        description: notes,
        metadata: {
          'resolution': resolution.toJson(),
          'refund_amount': refundAmount,
        },
      );

      final dispute = _mapToDisputeEntity(result);
      return ResolveDisputeResult.success(dispute);
    } catch (e) {
      debugPrint('Error resolving dispute: $e');
      return ResolveDisputeResult.failure(e.toString());
    }
  }

  @override
  Future<EscalateDisputeResult> escalateDispute({
    required String disputeId,
    required String reason,
  }) async {
    try {
      final adminId = _adminId;
      if (adminId == null) {
        return EscalateDisputeResult.failure('Not authenticated');
      }

      final result = await _jwtHandler.executeWithRecovery(
() => _supabase
            .from('disputes')
            .update({
              'status': 'escalated',
              'priority': 'urgent',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', disputeId)
            .select('''
              *,
              raised_by_user:raised_by(id, first_name, last_name, phone_number, email, role, profile_photo_url),
              raised_against_user:raised_against(id, first_name, last_name, phone_number, email, role, profile_photo_url)
            ''')
            .single(),
'escalate dispute $disputeId',
      );

      // Log audit
      await _logAudit(
        action: 'dispute_escalated',
        targetType: 'dispute',
        targetId: disputeId,
        newValues: {'reason': reason},
      );

      // Add to timeline
      await _addTimelineEvent(
        disputeId: disputeId,
        eventType: 'escalated',
        description: reason,
      );

      final dispute = _mapToDisputeEntity(result);
      return EscalateDisputeResult.success(dispute);
    } catch (e) {
      debugPrint('Error escalating dispute: $e');
      return EscalateDisputeResult.failure(e.toString());
    }
  }

  @override
  Future<UpdateDisputeResult> updateDisputeStatus({
    required String disputeId,
    required DisputeStatus status,
    String? notes,
  }) async {
    try {
      final result = await _jwtHandler.executeWithRecovery(
() => _supabase
            .from('disputes')
            .update({
              'status': status.toJson(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', disputeId)
            .select()
            .single(),
'update dispute status $disputeId',
      );

      // Log audit
      await _logAudit(
        action: 'dispute_status_changed',
        targetType: 'dispute',
        targetId: disputeId,
        newValues: {'status': status.toJson(), 'notes': notes},
      );

      // Add to timeline
      await _addTimelineEvent(
        disputeId: disputeId,
        eventType: 'status_changed',
        description: notes ?? 'Status changed to ${status.displayName}',
        metadata: {'new_status': status.toJson()},
      );

      final dispute = _mapToDisputeEntity(result);
      return UpdateDisputeResult.success(dispute);
    } catch (e) {
      debugPrint('Error updating dispute status: $e');
      return UpdateDisputeResult.failure(e.toString());
    }
  }

  @override
  Future<UpdateDisputeResult> updateDisputePriority({
    required String disputeId,
    required DisputePriority priority,
  }) async {
    try {
      final result = await _jwtHandler.executeWithRecovery(
() => _supabase
            .from('disputes')
            .update({
              'priority': priority.toJson(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', disputeId)
            .select()
            .single(),
'update dispute priority $disputeId',
      );

      // Log audit
      await _logAudit(
        action: 'dispute_priority_changed',
        targetType: 'dispute',
        targetId: disputeId,
        newValues: {'priority': priority.toJson()},
      );

      // Add to timeline
      await _addTimelineEvent(
        disputeId: disputeId,
        eventType: 'priority_changed',
        description: 'Priority changed to ${priority.displayName}',
        metadata: {'new_priority': priority.toJson()},
      );

      final dispute = _mapToDisputeEntity(result);
      return UpdateDisputeResult.success(dispute);
    } catch (e) {
      debugPrint('Error updating dispute priority: $e');
      return UpdateDisputeResult.failure(e.toString());
    }
  }

  @override
  Future<UpdateDisputeResult> assignDispute({
    required String disputeId,
    String? adminId,
  }) async {
    try {
      final result = await _jwtHandler.executeWithRecovery(
() => _supabase
            .from('disputes')
            .update({
              'admin_assigned': adminId,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', disputeId)
            .select()
            .single(),
'assign dispute $disputeId',
      );

      // Log audit
      await _logAudit(
        action: adminId != null ? 'dispute_assigned' : 'dispute_unassigned',
        targetType: 'dispute',
        targetId: disputeId,
        newValues: {'admin_assigned': adminId},
      );

      // Add to timeline
      await _addTimelineEvent(
        disputeId: disputeId,
        eventType: 'assigned',
        description: adminId != null ? 'Dispute assigned to admin' : 'Dispute unassigned',
        metadata: {'admin_id': adminId},
      );

      final dispute = _mapToDisputeEntity(result);
      return UpdateDisputeResult.success(dispute);
    } catch (e) {
      debugPrint('Error assigning dispute: $e');
      return UpdateDisputeResult.failure(e.toString());
    }
  }

  @override
  Future<UpdateDisputeResult> assignToSelf({required String disputeId}) async {
    final adminId = _adminId;
    if (adminId == null) {
      return UpdateDisputeResult.failure('Not authenticated');
    }
    return assignDispute(disputeId: disputeId, adminId: adminId);
  }

  @override
  Future<AddEvidenceResult> addEvidence({
    required String disputeId,
    required EvidenceType type,
    required String description,
    String? fileUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final adminId = _adminId;
      if (adminId == null) {
        return AddEvidenceResult.failure('Not authenticated');
      }

      final result = await _jwtHandler.executeWithRecovery(
() => _supabase
            .from('dispute_evidence')
            .insert({
              'dispute_id': disputeId,
              'submitted_by': adminId,
              'evidence_type': type.toJson(),
              'file_url': fileUrl,
              'description': description,
              'metadata': metadata ?? {},
            })
            .select('''
              *,
              submitted_by_user:submitted_by(id, first_name, last_name, phone_number, email, role, profile_photo_url)
            ''')
            .single(),
'add evidence to dispute $disputeId',
      );

      // Log audit
      await _logAudit(
        action: 'evidence_added',
        targetType: 'dispute',
        targetId: disputeId,
        newValues: {
          'evidence_type': type.toJson(),
          'description': description,
        },
      );

      // Add to timeline
      await _addTimelineEvent(
        disputeId: disputeId,
        eventType: 'evidence_added',
        description: 'Evidence added: $description',
        metadata: {'evidence_type': type.toJson()},
      );

      final evidence = _mapToEvidenceEntity(result);
      return AddEvidenceResult.success(evidence);
    } catch (e) {
      debugPrint('Error adding evidence: $e');
      return AddEvidenceResult.failure(e.toString());
    }
  }

  @override
  Future<bool> requestEvidence({
    required String disputeId,
    required String userId,
    required String message,
  }) async {
    try {
      // Update dispute status to awaiting evidence
      await updateDisputeStatus(
        disputeId: disputeId,
        status: DisputeStatus.awaitingEvidence,
        notes: 'Evidence requested from user',
      );

      // Send message to user (using admin_messages table)
      final adminId = _adminId;
      await _jwtHandler.executeWithRecovery(
() => _supabase.from('admin_messages').insert({
          'sent_by': adminId,
          'recipient_id': userId,
          'message_type': 'direct',
          'subject': 'Evidence Requested for Dispute',
          'body': message,
          'metadata': {'dispute_id': disputeId},
        }),
'send evidence request message',
      );

      // Log audit
      await _logAudit(
        action: 'evidence_requested',
        targetType: 'dispute',
        targetId: disputeId,
        newValues: {'user_id': userId, 'message': message},
      );

      return true;
    } catch (e) {
      debugPrint('Error requesting evidence: $e');
      return false;
    }
  }

  @override
  Future<bool> addNote({
    required String disputeId,
    required String content,
    bool isInternal = true,
  }) async {
    try {
      // Add to timeline as a comment
      await _addTimelineEvent(
        disputeId: disputeId,
        eventType: 'comment_added',
        description: content,
        metadata: {'is_internal': isInternal},
      );

      return true;
    } catch (e) {
      debugPrint('Error adding note: $e');
      return false;
    }
  }

  @override
  Future<List<EvidenceEntity>> fetchEvidence({required String disputeId}) async {
    try {
      final result = await _jwtHandler.executeWithRecovery(
() => _supabase
            .from('dispute_evidence')
            .select('''
              *,
              submitted_by_user:submitted_by(id, first_name, last_name, phone_number, email, role, profile_photo_url)
            ''')
            .eq('dispute_id', disputeId)
            .order('created_at', ascending: false),
'fetch evidence for dispute $disputeId',
      );

      final data = result as List<dynamic>;
      return data.map((json) => _mapToEvidenceEntity(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching evidence: $e');
      return [];
    }
  }

  @override
  Future<List<DisputeTimelineEvent>> fetchTimeline({
    required String disputeId,
  }) async {
    try {
      // Fetch from admin_audit_logs related to this dispute
      final result = await _jwtHandler.executeWithRecovery(
() => _supabase
            .from('admin_audit_logs')
            .select('''
              *,
              admin:admin_id(id, first_name, last_name, phone_number, email, role, profile_photo_url)
            ''')
            .eq('target_type', 'dispute')
            .eq('target_id', disputeId)
            .order('created_at', ascending: false),
'fetch timeline for dispute $disputeId',
      );

      final data = result as List<dynamic>;
      
      return data.map((json) {
        return DisputeTimelineEvent(
          id: json['id'] as String,
          disputeId: disputeId,
          eventType: json['action'] as String,
          description: (json['new_values'] as Map<String, dynamic>?)?['notes'] as String?,
          performedById: json['admin_id'] as String?,
          performedBy: json['admin'] != null
              ? DisputeUserInfo.fromJson(json['admin'] as Map<String, dynamic>)
              : null,
          metadata: json['new_values'] as Map<String, dynamic>?,
          createdAt: DateTime.parse(json['created_at'] as String),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching timeline: $e');
      return [];
    }
  }

  @override
  Future<DisputeStats> getStats({DateTime? startDate, DateTime? endDate}) async {
    try {
      var query = _supabase.from('disputes').select('id, status, priority, created_at, resolved_at');

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final result = await _jwtHandler.executeWithRecovery(
() => query,
'get dispute stats',
      );

      final data = result as List<dynamic>;

      int open = 0;
      int investigating = 0;
      int resolved = 0;
      int escalated = 0;
      int urgent = 0;
      int totalResolutionDays = 0;
      int resolvedCount = 0;

      for (final row in data) {
        final status = DisputeStatus.fromString(row['status'] as String? ?? 'open');
        final priority = DisputePriority.fromString(row['priority'] as String? ?? 'medium');

        switch (status) {
          case DisputeStatus.open:
            open++;
            break;
          case DisputeStatus.investigating:
          case DisputeStatus.awaitingEvidence:
            investigating++;
            break;
          case DisputeStatus.resolved:
          case DisputeStatus.closed:
            resolved++;
            if (row['resolved_at'] != null && row['created_at'] != null) {
              final createdAt = DateTime.parse(row['created_at'] as String);
              final resolvedAt = DateTime.parse(row['resolved_at'] as String);
              totalResolutionDays += resolvedAt.difference(createdAt).inDays;
              resolvedCount++;
            }
            break;
          case DisputeStatus.escalated:
            escalated++;
            break;
        }

        if (priority == DisputePriority.urgent) {
          urgent++;
        }
      }

      final total = data.length;
      final avgResolutionDays = resolvedCount > 0
          ? totalResolutionDays / resolvedCount
          : 0.0;
      final resolutionRate = total > 0 ? (resolved / total) * 100 : 0.0;

      return DisputeStats(
        totalDisputes: total,
        openDisputes: open,
        investigatingDisputes: investigating,
        resolvedDisputes: resolved,
        escalatedDisputes: escalated,
        urgentDisputes: urgent,
        averageResolutionDays: avgResolutionDays,
        resolutionRate: resolutionRate,
      );
    } catch (e) {
      debugPrint('Error getting stats: $e');
      return DisputeStats.empty();
    }
  }

  @override
  Future<List<DisputeEntity>> getDisputesByUser({required String userId}) async {
    try {
      final result = await _jwtHandler.executeWithRecovery(
() => _supabase
            .from('disputes')
            .select('''
              *,
              raised_by_user:raised_by(id, first_name, last_name, phone_number, email, role, profile_photo_url),
              raised_against_user:raised_against(id, first_name, last_name, phone_number, email, role, profile_photo_url),
              freight_post:freight_post_id(id, pickup_location, delivery_location, status, created_at)
            ''')
            .or('raised_by.eq.$userId,raised_against.eq.$userId')
            .order('created_at', ascending: false),
'get disputes by user $userId',
      );

      final data = result as List<dynamic>;
      return data.map((json) => _mapToDisputeEntity(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error getting disputes by user: $e');
      return [];
    }
  }

  @override
  Future<List<DisputeEntity>> getDisputesByShipment({
    required String shipmentId,
  }) async {
    try {
      final result = await _jwtHandler.executeWithRecovery(
() => _supabase
            .from('disputes')
            .select('''
              *,
              raised_by_user:raised_by(id, first_name, last_name, phone_number, email, role, profile_photo_url),
              raised_against_user:raised_against(id, first_name, last_name, phone_number, email, role, profile_photo_url)
            ''')
            .eq('freight_post_id', shipmentId)
            .order('created_at', ascending: false),
'get disputes by shipment $shipmentId',
      );

      final data = result as List<dynamic>;
      return data.map((json) => _mapToDisputeEntity(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error getting disputes by shipment: $e');
      return [];
    }
  }

  // Helper methods

  DisputeEntity _mapToDisputeEntity(Map<String, dynamic> json) {
    DisputeUserInfo? raisedBy;
    DisputeUserInfo? raisedAgainst;
    DisputeUserInfo? adminAssigned;
    DisputeUserInfo? resolvedBy;
    DisputeShipmentInfo? shipment;

    if (json['raised_by_user'] != null) {
      raisedBy = DisputeUserInfo.fromJson(json['raised_by_user'] as Map<String, dynamic>);
    }
    if (json['raised_against_user'] != null) {
      raisedAgainst = DisputeUserInfo.fromJson(json['raised_against_user'] as Map<String, dynamic>);
    }
    if (json['admin_assigned_user'] != null) {
      adminAssigned = DisputeUserInfo.fromJson(json['admin_assigned_user'] as Map<String, dynamic>);
    }
    if (json['resolved_by_user'] != null) {
      resolvedBy = DisputeUserInfo.fromJson(json['resolved_by_user'] as Map<String, dynamic>);
    }
    if (json['freight_post'] != null) {
      shipment = DisputeShipmentInfo.fromJson(json['freight_post'] as Map<String, dynamic>);
    }

    // Handle evidence count
    int? evidenceCount;
    if (json['evidence'] != null) {
      if (json['evidence'] is List) {
        final evidenceList = json['evidence'] as List;
        if (evidenceList.isNotEmpty && evidenceList.first is Map) {
          evidenceCount = evidenceList.first['count'] as int?;
        }
      }
    }

    return DisputeEntity(
      id: json['id'] as String,
      freightPostId: json['freight_post_id'] as String,
      raisedById: json['raised_by'] as String,
      raisedAgainstId: json['raised_against'] as String,
      disputeType: DisputeType.fromString(json['dispute_type'] as String? ?? 'other'),
      priority: DisputePriority.fromString(json['priority'] as String? ?? 'medium'),
      status: DisputeStatus.fromString(json['status'] as String? ?? 'open'),
      title: json['title'] as String,
      description: json['description'] as String,
      adminAssignedId: json['admin_assigned'] as String?,
      resolution: json['resolution'] as String?,
      resolvedById: json['resolved_by'] as String?,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      refundAmount: (json['refund_amount'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      raisedBy: raisedBy,
      raisedAgainst: raisedAgainst,
      adminAssigned: adminAssigned,
      resolvedBy: resolvedBy,
      shipment: shipment,
      evidenceCount: evidenceCount,
    );
  }

  EvidenceEntity _mapToEvidenceEntity(Map<String, dynamic> json) {
    DisputeUserInfo? submittedBy;
    if (json['submitted_by_user'] != null) {
      submittedBy = DisputeUserInfo.fromJson(json['submitted_by_user'] as Map<String, dynamic>);
    }

    return EvidenceEntity(
      id: json['id'] as String,
      disputeId: json['dispute_id'] as String,
      submittedById: json['submitted_by'] as String,
      evidenceType: EvidenceType.fromString(json['evidence_type'] as String? ?? 'other'),
      fileUrl: json['file_url'] as String?,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      submittedBy: submittedBy,
    );
  }

  Future<void> _addTimelineEvent({
    required String disputeId,
    required String eventType,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final adminId = _adminId;
      await _supabase.from('admin_audit_logs').insert({
        'admin_id': adminId,
        'action': eventType,
        'target_type': 'dispute',
        'target_id': disputeId,
        'new_values': {
          'notes': description,
          ...?metadata,
        },
      });
    } catch (e) {
      debugPrint('Error adding timeline event: $e');
    }
  }

  Future<void> _logAudit({
    required String action,
    required String targetType,
    String? targetId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) async {
    try {
      final adminId = _adminId;
      await _supabase.from('admin_audit_logs').insert({
        'admin_id': adminId,
        'action': action,
        'target_type': targetType,
        'target_id': targetId,
        'old_values': oldValues,
        'new_values': newValues,
      });
    } catch (e) {
      debugPrint('Error logging audit: $e');
    }
  }
}
