import 'package:equatable/equatable.dart';

/// Vehicle entity for driver's vehicles
class VehicleEntity extends Equatable {
  final String id;
  final String driverId;
  final String type;
  final String make;
  final String model;
  final int? year;
  final String licensePlate;
  final double? capacityTons;
  final String? photoUrl;
  final String? color;
  final String verificationStatus;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? registrationDocumentUrl;
  final String? insuranceDocumentUrl;
  final String? roadworthyCertificateUrl;
  final List<String>? additionalPhotos;
  final String? rejectionReason;
  final String? adminNotes;
  final DateTime? createdAt;
  final String? driverName;
  final String? driverPhone;

  // Per-document review fields
  final String? registrationDocStatus;
  final String? registrationDocVerifiedBy;
  final DateTime? registrationDocVerifiedAt;
  final String? registrationDocRejectionReason;
  final String? insuranceDocStatus;
  final String? insuranceDocVerifiedBy;
  final DateTime? insuranceDocVerifiedAt;
  final String? insuranceDocRejectionReason;
  final String? roadworthyDocStatus;
  final String? roadworthyDocVerifiedBy;
  final DateTime? roadworthyDocVerifiedAt;
  final String? roadworthyDocRejectionReason;

  const VehicleEntity({
    required this.id,
    required this.driverId,
    required this.type,
    required this.make,
    required this.model,
    this.year,
    required this.licensePlate,
    this.capacityTons,
    this.photoUrl,
    this.color,
    required this.verificationStatus,
    this.verifiedBy,
    this.verifiedAt,
    this.registrationDocumentUrl,
    this.insuranceDocumentUrl,
    this.roadworthyCertificateUrl,
    this.additionalPhotos,
    this.rejectionReason,
    this.adminNotes,
    this.createdAt,
    this.driverName,
    this.driverPhone,
    this.registrationDocStatus,
    this.registrationDocVerifiedBy,
    this.registrationDocVerifiedAt,
    this.registrationDocRejectionReason,
    this.insuranceDocStatus,
    this.insuranceDocVerifiedBy,
    this.insuranceDocVerifiedAt,
    this.insuranceDocRejectionReason,
    this.roadworthyDocStatus,
    this.roadworthyDocVerifiedBy,
    this.roadworthyDocVerifiedAt,
    this.roadworthyDocRejectionReason,
  });

  /// Display name for vehicle (e.g., "Toyota Hilux 2020")
  String get displayName {
    final parts = [make, model];
    if (year != null) parts.add(year.toString());
    return parts.join(' ');
  }

  /// Short description (type and capacity)
  String get shortDescription {
    if (capacityTons != null) {
      return '$type • ${capacityTons!.toStringAsFixed(1)}t';
    }
    return type;
  }

  /// Check if vehicle is approved
  bool get isApproved => verificationStatus == 'approved';

  /// Check if vehicle is pending
  bool get isPending => verificationStatus == 'pending';

  /// Check if vehicle is rejected
  bool get isRejected => verificationStatus == 'rejected';

  /// Check if vehicle is under review
  bool get isUnderReview => verificationStatus == 'under_review';

  /// Check if vehicle has documents requested
  bool get isDocumentsRequested => verificationStatus == 'documents_requested';

  /// Check if vehicle is suspended
  bool get isSuspended => verificationStatus == 'suspended';

  /// Check if vehicle is in an actionable state (can be transitioned)
  bool get isActionable =>
      isPending || isUnderReview || isDocumentsRequested || isRejected;

  /// Get count of document URLs available
  int get documentsCount {
    int count = 0;
    if (registrationDocumentUrl != null) count++;
    if (insuranceDocumentUrl != null) count++;
    if (roadworthyCertificateUrl != null) count++;
    return count;
  }

  /// Get all photo URLs including main and additional
  List<String> get allPhotoUrls {
    final urls = <String>[];
    if (photoUrl != null) urls.add(photoUrl!);
    if (additionalPhotos != null) urls.addAll(additionalPhotos!);
    return urls;
  }

  /// Get per-document status for a given doc type
  String? getDocStatus(String docType) {
    switch (docType) {
      case 'Registration':
        return registrationDocStatus;
      case 'Insurance':
        return insuranceDocStatus;
      case 'Roadworthy':
        return roadworthyDocStatus;
      default:
        return null;
    }
  }

  /// Get per-document rejection reason for a given doc type
  String? getDocRejectionReason(String docType) {
    switch (docType) {
      case 'Registration':
        return registrationDocRejectionReason;
      case 'Insurance':
        return insuranceDocRejectionReason;
      case 'Roadworthy':
        return roadworthyDocRejectionReason;
      default:
        return null;
    }
  }

  /// Get all document URLs
  Map<String, String> get documentUrls {
    final docs = <String, String>{};
    if (registrationDocumentUrl != null) {
      docs['Registration'] = registrationDocumentUrl!;
    }
    if (insuranceDocumentUrl != null) {
      docs['Insurance'] = insuranceDocumentUrl!;
    }
    if (roadworthyCertificateUrl != null) {
      docs['Roadworthy'] = roadworthyCertificateUrl!;
    }
    return docs;
  }

  VehicleEntity copyWith({
    String? id,
    String? driverId,
    String? type,
    String? make,
    String? model,
    int? year,
    String? licensePlate,
    double? capacityTons,
    String? photoUrl,
    String? color,
    String? verificationStatus,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? registrationDocumentUrl,
    String? insuranceDocumentUrl,
    String? roadworthyCertificateUrl,
    List<String>? additionalPhotos,
    String? rejectionReason,
    String? adminNotes,
    DateTime? createdAt,
    String? driverName,
    String? driverPhone,
    String? registrationDocStatus,
    String? registrationDocVerifiedBy,
    DateTime? registrationDocVerifiedAt,
    String? registrationDocRejectionReason,
    String? insuranceDocStatus,
    String? insuranceDocVerifiedBy,
    DateTime? insuranceDocVerifiedAt,
    String? insuranceDocRejectionReason,
    String? roadworthyDocStatus,
    String? roadworthyDocVerifiedBy,
    DateTime? roadworthyDocVerifiedAt,
    String? roadworthyDocRejectionReason,
  }) {
    return VehicleEntity(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      type: type ?? this.type,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      licensePlate: licensePlate ?? this.licensePlate,
      capacityTons: capacityTons ?? this.capacityTons,
      photoUrl: photoUrl ?? this.photoUrl,
      color: color ?? this.color,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      registrationDocumentUrl:
          registrationDocumentUrl ?? this.registrationDocumentUrl,
      insuranceDocumentUrl: insuranceDocumentUrl ?? this.insuranceDocumentUrl,
      roadworthyCertificateUrl:
          roadworthyCertificateUrl ?? this.roadworthyCertificateUrl,
      additionalPhotos: additionalPhotos ?? this.additionalPhotos,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt ?? this.createdAt,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      registrationDocStatus:
          registrationDocStatus ?? this.registrationDocStatus,
      registrationDocVerifiedBy:
          registrationDocVerifiedBy ?? this.registrationDocVerifiedBy,
      registrationDocVerifiedAt:
          registrationDocVerifiedAt ?? this.registrationDocVerifiedAt,
      registrationDocRejectionReason:
          registrationDocRejectionReason ?? this.registrationDocRejectionReason,
      insuranceDocStatus: insuranceDocStatus ?? this.insuranceDocStatus,
      insuranceDocVerifiedBy:
          insuranceDocVerifiedBy ?? this.insuranceDocVerifiedBy,
      insuranceDocVerifiedAt:
          insuranceDocVerifiedAt ?? this.insuranceDocVerifiedAt,
      insuranceDocRejectionReason:
          insuranceDocRejectionReason ?? this.insuranceDocRejectionReason,
      roadworthyDocStatus: roadworthyDocStatus ?? this.roadworthyDocStatus,
      roadworthyDocVerifiedBy:
          roadworthyDocVerifiedBy ?? this.roadworthyDocVerifiedBy,
      roadworthyDocVerifiedAt:
          roadworthyDocVerifiedAt ?? this.roadworthyDocVerifiedAt,
      roadworthyDocRejectionReason:
          roadworthyDocRejectionReason ?? this.roadworthyDocRejectionReason,
    );
  }

  @override
  List<Object?> get props => [
        id,
        driverId,
        type,
        make,
        model,
        year,
        licensePlate,
        capacityTons,
        photoUrl,
        color,
        verificationStatus,
        verifiedBy,
        verifiedAt,
        registrationDocumentUrl,
        insuranceDocumentUrl,
        roadworthyCertificateUrl,
        additionalPhotos,
        rejectionReason,
        adminNotes,
        createdAt,
        driverName,
        driverPhone,
        registrationDocStatus,
        registrationDocVerifiedBy,
        registrationDocVerifiedAt,
        registrationDocRejectionReason,
        insuranceDocStatus,
        insuranceDocVerifiedBy,
        insuranceDocVerifiedAt,
        insuranceDocRejectionReason,
        roadworthyDocStatus,
        roadworthyDocVerifiedBy,
        roadworthyDocVerifiedAt,
        roadworthyDocRejectionReason,
      ];
}
