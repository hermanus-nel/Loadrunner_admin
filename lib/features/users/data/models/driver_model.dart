// lib/features/users/data/models/driver_model.dart

import '../../domain/entities/driver_entity.dart';

/// Data model for driver with JSON serialization
class DriverModel extends DriverEntity {
  const DriverModel({
    required super.id,
    required super.visibleId,
    required super.firstName,
    required super.lastName,
    super.phoneNumber,
    super.email,
    super.profilePhotoUrl,
    required super.verificationStatus,
    required super.isVerified,
    super.verifiedAt,
    super.driverLicenseNumber,
    super.driverLicenseExpiry,
    super.vehicleCount,
    required super.createdAt,
    super.updatedAt,
  });

  /// Create from Supabase query result (joined with users table)
  factory DriverModel.fromJson(Map<String, dynamic> json) {
    // Handle nested user data from join
    final userData = json['users'] as Map<String, dynamic>?;
    
    // Determine verification status
    // The column is `driver_verification_status` in the users table,
    // but some queries may alias it as `verification_status`.
    DriverVerificationStatus status;
    final isVerified = json['is_verified'] as bool? ?? false;
    final verificationStatusStr =
        json['driver_verification_status'] as String? ??
        json['verification_status'] as String?;

    if (verificationStatusStr != null) {
      status = DriverVerificationStatus.fromString(verificationStatusStr);
    } else {
      // Fallback to is_verified field
      status = isVerified
          ? DriverVerificationStatus.approved
          : DriverVerificationStatus.pending;
    }

    return DriverModel(
      id: json['id'] as String,
      visibleId: json['visible_id'] as String? ?? '',
      firstName: userData?['first_name'] as String? ?? json['first_name'] as String? ?? '',
      lastName: userData?['last_name'] as String? ?? json['last_name'] as String? ?? '',
      phoneNumber: userData?['phone'] as String? ?? json['phone'] as String?,
      email: userData?['email'] as String? ?? json['email'] as String?,
      profilePhotoUrl: userData?['profile_photo_url'] as String? ?? 
                       json['profile_photo_url'] as String?,
      verificationStatus: status,
      isVerified: isVerified,
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'] as String)
          : null,
      driverLicenseNumber: json['driver_license_number'] as String?,
      driverLicenseExpiry: json['driver_license_expiry'] != null
          ? DateTime.tryParse(json['driver_license_expiry'] as String)
          : null,
      vehicleCount: _extractVehicleCount(json),
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  /// Extract vehicle count from joined vehicles(count) or fallback to vehicle_count field
  static int _extractVehicleCount(Map<String, dynamic> json) {
    // Handle Supabase resource embedding: vehicles(count) returns [{"count": N}]
    final vehiclesData = json['vehicles'] as List<dynamic>?;
    if (vehiclesData != null && vehiclesData.isNotEmpty) {
      final first = vehiclesData[0] as Map<String, dynamic>;
      return first['count'] as int? ?? 0;
    }
    // Fallback to direct vehicle_count field
    return json['vehicle_count'] as int? ?? 0;
  }

  /// Create from Supabase query with separate user data
  factory DriverModel.fromDriverAndUser(
    Map<String, dynamic> driverJson,
    Map<String, dynamic>? userJson,
  ) {
    final isVerified = driverJson['is_verified'] as bool? ?? false;
    final verificationStatusStr = driverJson['verification_status'] as String?;
    
    DriverVerificationStatus status;
    if (verificationStatusStr != null) {
      status = DriverVerificationStatus.fromString(verificationStatusStr);
    } else {
      status = isVerified 
          ? DriverVerificationStatus.approved 
          : DriverVerificationStatus.pending;
    }

    return DriverModel(
      id: driverJson['id'] as String,
      visibleId: driverJson['visible_id'] as String? ?? '',
      firstName: userJson?['first_name'] as String? ?? '',
      lastName: userJson?['last_name'] as String? ?? '',
      phoneNumber: userJson?['phone'] as String?,
      email: userJson?['email'] as String?,
      profilePhotoUrl: userJson?['profile_photo_url'] as String?,
      verificationStatus: status,
      isVerified: isVerified,
      verifiedAt: driverJson['verified_at'] != null
          ? DateTime.tryParse(driverJson['verified_at'] as String)
          : null,
      driverLicenseNumber: driverJson['driver_license_number'] as String?,
      driverLicenseExpiry: driverJson['driver_license_expiry'] != null
          ? DateTime.tryParse(driverJson['driver_license_expiry'] as String)
          : null,
      vehicleCount: driverJson['vehicle_count'] as int? ?? 0,
      createdAt: DateTime.parse(
        driverJson['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: driverJson['updated_at'] != null
          ? DateTime.tryParse(driverJson['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visible_id': visibleId,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phoneNumber,
      'email': email,
      'profile_photo_url': profilePhotoUrl,
      'verification_status': verificationStatus.statusName,
      'is_verified': isVerified,
      'verified_at': verifiedAt?.toIso8601String(),
      'driver_license_number': driverLicenseNumber,
      'driver_license_expiry': driverLicenseExpiry?.toIso8601String(),
      'vehicle_count': vehicleCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
