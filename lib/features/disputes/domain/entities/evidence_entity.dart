// lib/features/disputes/domain/entities/evidence_entity.dart

import 'package:flutter/foundation.dart';
import 'dispute_entity.dart';

/// Evidence type enum
enum EvidenceType {
  photo,
  document,
  deliveryProof,
  damagePhoto,
  receipt,
  gpsData,
  communication,
  other;

  static EvidenceType fromString(String value) {
    switch (value.toLowerCase().replaceAll('_', '')) {
      case 'photo':
      case 'image':
        return EvidenceType.photo;
      case 'document':
      case 'doc':
        return EvidenceType.document;
      case 'deliveryproof':
      case 'delivery_proof':
        return EvidenceType.deliveryProof;
      case 'damagephoto':
      case 'damage_photo':
        return EvidenceType.damagePhoto;
      case 'receipt':
        return EvidenceType.receipt;
      case 'gpsdata':
      case 'gps_data':
      case 'gps':
        return EvidenceType.gpsData;
      case 'communication':
      case 'message':
        return EvidenceType.communication;
      default:
        return EvidenceType.other;
    }
  }

  String get displayName {
    switch (this) {
      case EvidenceType.photo:
        return 'Photo';
      case EvidenceType.document:
        return 'Document';
      case EvidenceType.deliveryProof:
        return 'Delivery Proof';
      case EvidenceType.damagePhoto:
        return 'Damage Photo';
      case EvidenceType.receipt:
        return 'Receipt';
      case EvidenceType.gpsData:
        return 'GPS Data';
      case EvidenceType.communication:
        return 'Communication';
      case EvidenceType.other:
        return 'Other';
    }
  }

  String toJson() {
    switch (this) {
      case EvidenceType.photo:
        return 'photo';
      case EvidenceType.document:
        return 'document';
      case EvidenceType.deliveryProof:
        return 'delivery_proof';
      case EvidenceType.damagePhoto:
        return 'damage_photo';
      case EvidenceType.receipt:
        return 'receipt';
      case EvidenceType.gpsData:
        return 'gps_data';
      case EvidenceType.communication:
        return 'communication';
      case EvidenceType.other:
        return 'other';
    }
  }

  bool get isImage =>
      this == EvidenceType.photo ||
      this == EvidenceType.damagePhoto ||
      this == EvidenceType.deliveryProof;
}

/// Evidence Entity
@immutable
class EvidenceEntity {
  final String id;
  final String disputeId;
  final String submittedById;
  final EvidenceType evidenceType;
  final String? fileUrl;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  // Related entities (populated when fetching)
  final DisputeUserInfo? submittedBy;

  const EvidenceEntity({
    required this.id,
    required this.disputeId,
    required this.submittedById,
    required this.evidenceType,
    this.fileUrl,
    this.description,
    this.metadata,
    required this.createdAt,
    this.submittedBy,
  });

  /// Check if this is an image evidence
  bool get isImage => evidenceType.isImage;

  /// Check if this has a file
  bool get hasFile => fileUrl != null && fileUrl!.isNotEmpty;

  /// Get file extension from URL
  String? get fileExtension {
    if (fileUrl == null) return null;
    final uri = Uri.tryParse(fileUrl!);
    if (uri == null) return null;
    final path = uri.path;
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == path.length - 1) return null;
    return path.substring(dotIndex + 1).toLowerCase();
  }

  /// Check if file is a known image format
  bool get isImageFile {
    final ext = fileExtension;
    if (ext == null) return false;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  /// Check if file is a known document format
  bool get isDocumentFile {
    final ext = fileExtension;
    if (ext == null) return false;
    return ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx'].contains(ext);
  }

  /// Get GPS coordinates if present in metadata
  ({double lat, double lng})? get gpsCoordinates {
    if (metadata == null) return null;
    final lat = metadata!['latitude'] as double?;
    final lng = metadata!['longitude'] as double?;
    if (lat == null || lng == null) return null;
    return (lat: lat, lng: lng);
  }

  /// Get timestamp from metadata if present
  DateTime? get capturedAt {
    if (metadata == null) return null;
    final timestamp = metadata!['captured_at'] as String?;
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp);
  }

  /// Copy with method for immutability
  EvidenceEntity copyWith({
    String? id,
    String? disputeId,
    String? submittedById,
    EvidenceType? evidenceType,
    String? fileUrl,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DisputeUserInfo? submittedBy,
  }) {
    return EvidenceEntity(
      id: id ?? this.id,
      disputeId: disputeId ?? this.disputeId,
      submittedById: submittedById ?? this.submittedById,
      evidenceType: evidenceType ?? this.evidenceType,
      fileUrl: fileUrl ?? this.fileUrl,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      submittedBy: submittedBy ?? this.submittedBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EvidenceEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Timeline event for dispute history
@immutable
class DisputeTimelineEvent {
  final String id;
  final String disputeId;
  final String eventType;
  final String? description;
  final String? performedById;
  final DisputeUserInfo? performedBy;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const DisputeTimelineEvent({
    required this.id,
    required this.disputeId,
    required this.eventType,
    this.description,
    this.performedById,
    this.performedBy,
    this.metadata,
    required this.createdAt,
  });

  String get eventDisplayName {
    switch (eventType.toLowerCase()) {
      case 'created':
        return 'Dispute Created';
      case 'assigned':
        return 'Admin Assigned';
      case 'status_changed':
        return 'Status Updated';
      case 'evidence_added':
        return 'Evidence Added';
      case 'escalated':
        return 'Escalated';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      case 'comment_added':
        return 'Comment Added';
      case 'priority_changed':
        return 'Priority Changed';
      default:
        return eventType;
    }
  }

  factory DisputeTimelineEvent.fromJson(Map<String, dynamic> json) {
    return DisputeTimelineEvent(
      id: json['id'] as String,
      disputeId: json['dispute_id'] as String,
      eventType: json['event_type'] as String? ?? json['action'] as String? ?? 'unknown',
      description: json['description'] as String? ?? json['notes'] as String?,
      performedById: json['performed_by'] as String? ?? json['admin_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      performedBy: json['performer'] != null
          ? DisputeUserInfo.fromJson(json['performer'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Admin note for disputes
@immutable
class DisputeNote {
  final String id;
  final String disputeId;
  final String adminId;
  final String content;
  final bool isInternal;
  final DateTime createdAt;
  final DisputeUserInfo? admin;

  const DisputeNote({
    required this.id,
    required this.disputeId,
    required this.adminId,
    required this.content,
    this.isInternal = true,
    required this.createdAt,
    this.admin,
  });

  factory DisputeNote.fromJson(Map<String, dynamic> json) {
    return DisputeNote(
      id: json['id'] as String,
      disputeId: json['dispute_id'] as String,
      adminId: json['admin_id'] as String,
      content: json['content'] as String,
      isInternal: json['is_internal'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      admin: json['admin'] != null
          ? DisputeUserInfo.fromJson(json['admin'] as Map<String, dynamic>)
          : null,
    );
  }
}
