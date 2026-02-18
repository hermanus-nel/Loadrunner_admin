import '../../domain/entities/driver_document.dart';

/// Data model for DriverDocument with JSON serialization
class DriverDocumentModel {
  final String id;
  final String driverId;
  final String docType;
  final String docUrl;
  final String verificationStatus;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final String? adminNotes;
  final DateTime? expiryDate;
  final DateTime createdAt;
  final DateTime modifiedAt;

  DriverDocumentModel({
    required this.id,
    required this.driverId,
    required this.docType,
    required this.docUrl,
    required this.verificationStatus,
    this.verifiedBy,
    this.verifiedAt,
    this.rejectionReason,
    this.adminNotes,
    this.expiryDate,
    required this.createdAt,
    required this.modifiedAt,
  });

  factory DriverDocumentModel.fromJson(Map<String, dynamic> json) {
    return DriverDocumentModel(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      docType: json['doc_type'] as String,
      docUrl: json['doc_url'] as String,
      verificationStatus:
          json['verification_status'] as String? ?? 'pending',
      verifiedBy: json['verified_by'] as String?,
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'] as String)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      adminNotes: json['admin_notes'] as String?,
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      modifiedAt: DateTime.parse(json['modified_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'doc_type': docType,
      'doc_url': docUrl,
      'verification_status': verificationStatus,
      'verified_by': verifiedBy,
      'verified_at': verifiedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'admin_notes': adminNotes,
      'expiry_date': expiryDate?.toIso8601String().split('T').first,
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt.toIso8601String(),
    };
  }

  DriverDocument toEntity() {
    return DriverDocument(
      id: id,
      driverId: driverId,
      docType: docType,
      docUrl: docUrl,
      verificationStatus: verificationStatus,
      verifiedBy: verifiedBy,
      verifiedAt: verifiedAt,
      rejectionReason: rejectionReason,
      adminNotes: adminNotes,
      expiryDate: expiryDate,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
    );
  }

  static DriverDocumentModel fromEntity(DriverDocument entity) {
    return DriverDocumentModel(
      id: entity.id,
      driverId: entity.driverId,
      docType: entity.docType,
      docUrl: entity.docUrl,
      verificationStatus: entity.verificationStatus,
      verifiedBy: entity.verifiedBy,
      verifiedAt: entity.verifiedAt,
      rejectionReason: entity.rejectionReason,
      adminNotes: entity.adminNotes,
      expiryDate: entity.expiryDate,
      createdAt: entity.createdAt,
      modifiedAt: entity.modifiedAt,
    );
  }
}
