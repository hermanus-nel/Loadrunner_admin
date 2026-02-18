import 'package:equatable/equatable.dart';

/// Driver document entity
class DriverDocument extends Equatable {
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

  const DriverDocument({
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

  /// Get human-readable label for document type
  String get label {
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
      case 'vehicle_registration':
        return 'Vehicle Registration';
      case 'vehicle_insurance':
        return 'Vehicle Insurance';
      case 'roadworthy_certificate':
        return 'Roadworthy Certificate';
      case 'pdp':
        return 'PDP (Public Driving Permit)';
      default:
        return docType.replaceAll('_', ' ').split(' ').map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' ');
    }
  }

  /// Check if document is approved
  bool get isApproved => verificationStatus == 'approved';

  /// Check if document is pending
  bool get isPending => verificationStatus == 'pending';

  /// Check if document is rejected
  bool get isRejected => verificationStatus == 'rejected';

  /// Check if document is under review
  bool get isUnderReview => verificationStatus == 'under_review';

  /// Check if document has been requested for re-upload
  bool get isDocumentsRequested => verificationStatus == 'documents_requested';

  /// Check if document can be reviewed (pending or under review)
  bool get isReviewable =>
      verificationStatus == 'pending' ||
      verificationStatus == 'under_review' ||
      verificationStatus == 'documents_requested';

  /// Check if document is expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  /// Check if document is expiring soon (within 30 days)
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final thirtyDaysFromNow = DateTime.now().add(const Duration(days: 30));
    return expiryDate!.isBefore(thirtyDaysFromNow) && !isExpired;
  }

  /// Days until expiry (negative if expired)
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  DriverDocument copyWith({
    String? id,
    String? driverId,
    String? docType,
    String? docUrl,
    String? verificationStatus,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? rejectionReason,
    String? adminNotes,
    DateTime? expiryDate,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return DriverDocument(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      docType: docType ?? this.docType,
      docUrl: docUrl ?? this.docUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      adminNotes: adminNotes ?? this.adminNotes,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        driverId,
        docType,
        docUrl,
        verificationStatus,
        verifiedBy,
        verifiedAt,
        rejectionReason,
        adminNotes,
        expiryDate,
        createdAt,
        modifiedAt,
      ];
}
