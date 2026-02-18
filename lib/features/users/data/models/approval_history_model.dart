import '../../domain/entities/approval_history_item.dart';

/// Data model for ApprovalHistoryItem with JSON serialization
class ApprovalHistoryModel {
  final String id;
  final String driverId;
  final String adminId;
  final String? adminName;
  final String? previousStatus;
  final String newStatus;
  final String? reason;
  final String? notes;
  final List<String>? documentsReviewed;
  final DateTime createdAt;

  ApprovalHistoryModel({
    required this.id,
    required this.driverId,
    required this.adminId,
    this.adminName,
    this.previousStatus,
    required this.newStatus,
    this.reason,
    this.notes,
    this.documentsReviewed,
    required this.createdAt,
  });

  factory ApprovalHistoryModel.fromJson(Map<String, dynamic> json) {
    // Parse documents_reviewed JSONB field
    List<String>? documentsReviewed;
    if (json['documents_reviewed'] != null) {
      if (json['documents_reviewed'] is List) {
        documentsReviewed = (json['documents_reviewed'] as List)
            .map((e) => e.toString())
            .toList();
      }
    }

    // Handle nested admin data from join
    String? adminName;
    if (json['admin'] != null && json['admin'] is Map) {
      final admin = json['admin'] as Map<String, dynamic>;
      final firstName = admin['first_name'] as String?;
      final lastName = admin['last_name'] as String?;
      if (firstName != null || lastName != null) {
        adminName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
      }
    } else {
      adminName = json['admin_name'] as String?;
    }

    return ApprovalHistoryModel(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      adminId: json['admin_id'] as String,
      adminName: adminName,
      previousStatus: json['previous_status'] as String?,
      newStatus: json['new_status'] as String,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      documentsReviewed: documentsReviewed,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'admin_id': adminId,
      'admin_name': adminName,
      'previous_status': previousStatus,
      'new_status': newStatus,
      'reason': reason,
      'notes': notes,
      'documents_reviewed': documentsReviewed,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ApprovalHistoryItem toEntity() {
    return ApprovalHistoryItem(
      id: id,
      driverId: driverId,
      adminId: adminId,
      adminName: adminName,
      previousStatus: previousStatus,
      newStatus: newStatus,
      reason: reason,
      notes: notes,
      documentsReviewed: documentsReviewed,
      createdAt: createdAt,
    );
  }

  static ApprovalHistoryModel fromEntity(ApprovalHistoryItem entity) {
    return ApprovalHistoryModel(
      id: entity.id,
      driverId: entity.driverId,
      adminId: entity.adminId,
      adminName: entity.adminName,
      previousStatus: entity.previousStatus,
      newStatus: entity.newStatus,
      reason: entity.reason,
      notes: entity.notes,
      documentsReviewed: entity.documentsReviewed,
      createdAt: entity.createdAt,
    );
  }
}
