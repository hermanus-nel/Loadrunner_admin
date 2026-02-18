import '../../domain/entities/vehicle_entity.dart';

/// Data model for Vehicle with JSON serialization
class VehicleModel {
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

  VehicleModel({
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
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    // Parse additional_photos JSONB field
    List<String>? additionalPhotos;
    if (json['additional_photos'] != null) {
      if (json['additional_photos'] is List) {
        additionalPhotos = (json['additional_photos'] as List)
            .map((e) => e.toString())
            .toList();
      }
    }

    // Parse driver join data (from Supabase foreign key join)
    String? driverName;
    String? driverPhone;
    final driver = json['driver'] as Map<String, dynamic>?;
    if (driver != null) {
      final nameParts = <String>[
        if (driver['first_name'] is String) driver['first_name'] as String,
        if (driver['last_name'] is String) driver['last_name'] as String,
      ];
      final joined = nameParts.join(' ').trim();
      if (joined.isNotEmpty) driverName = joined;
      driverPhone = driver['phone_number'] as String?;
    }

    return VehicleModel(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      type: json['type'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      year: json['year'] as int?,
      licensePlate: json['license_plate'] as String,
      capacityTons: json['capacity_tons'] != null
          ? (json['capacity_tons'] as num).toDouble()
          : null,
      photoUrl: json['photo_url'] as String?,
      color: json['color'] as String?,
      verificationStatus:
          json['verification_status'] as String? ?? 'pending',
      verifiedBy: json['verified_by'] as String?,
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'] as String)
          : null,
      registrationDocumentUrl: json['registration_document_url'] as String?,
      insuranceDocumentUrl: json['insurance_document_url'] as String?,
      roadworthyCertificateUrl: json['roadworthy_certificate_url'] as String?,
      additionalPhotos: additionalPhotos,
      rejectionReason: json['rejection_reason'] as String?,
      adminNotes: json['admin_notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      driverName: driverName,
      driverPhone: driverPhone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'type': type,
      'make': make,
      'model': model,
      'year': year,
      'license_plate': licensePlate,
      'capacity_tons': capacityTons,
      'photo_url': photoUrl,
      'color': color,
      'verification_status': verificationStatus,
      'verified_by': verifiedBy,
      'verified_at': verifiedAt?.toIso8601String(),
      'registration_document_url': registrationDocumentUrl,
      'insurance_document_url': insuranceDocumentUrl,
      'roadworthy_certificate_url': roadworthyCertificateUrl,
      'additional_photos': additionalPhotos,
      'rejection_reason': rejectionReason,
      'admin_notes': adminNotes,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  VehicleEntity toEntity() {
    return VehicleEntity(
      id: id,
      driverId: driverId,
      type: type,
      make: make,
      model: model,
      year: year,
      licensePlate: licensePlate,
      capacityTons: capacityTons,
      photoUrl: photoUrl,
      color: color,
      verificationStatus: verificationStatus,
      verifiedBy: verifiedBy,
      verifiedAt: verifiedAt,
      registrationDocumentUrl: registrationDocumentUrl,
      insuranceDocumentUrl: insuranceDocumentUrl,
      roadworthyCertificateUrl: roadworthyCertificateUrl,
      additionalPhotos: additionalPhotos,
      rejectionReason: rejectionReason,
      adminNotes: adminNotes,
      createdAt: createdAt,
      driverName: driverName,
      driverPhone: driverPhone,
    );
  }

  static VehicleModel fromEntity(VehicleEntity entity) {
    return VehicleModel(
      id: entity.id,
      driverId: entity.driverId,
      type: entity.type,
      make: entity.make,
      model: entity.model,
      year: entity.year,
      licensePlate: entity.licensePlate,
      capacityTons: entity.capacityTons,
      photoUrl: entity.photoUrl,
      color: entity.color,
      verificationStatus: entity.verificationStatus,
      verifiedBy: entity.verifiedBy,
      verifiedAt: entity.verifiedAt,
      registrationDocumentUrl: entity.registrationDocumentUrl,
      insuranceDocumentUrl: entity.insuranceDocumentUrl,
      roadworthyCertificateUrl: entity.roadworthyCertificateUrl,
      additionalPhotos: entity.additionalPhotos,
      rejectionReason: entity.rejectionReason,
      adminNotes: entity.adminNotes,
      createdAt: entity.createdAt,
      driverName: entity.driverName,
      driverPhone: entity.driverPhone,
    );
  }
}
