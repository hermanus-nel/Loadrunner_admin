// lib/features/users/domain/entities/driver_entity.dart

/// Verification status for drivers
enum DriverVerificationStatus {
  pending,
  approved,
  rejected;

  /// Create from string value
  static DriverVerificationStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'approved':
        return DriverVerificationStatus.approved;
      case 'rejected':
        return DriverVerificationStatus.rejected;
      case 'pending':
      default:
        return DriverVerificationStatus.pending;
    }
  }

  /// Convert to display string
  String get displayName {
    switch (this) {
      case DriverVerificationStatus.pending:
        return 'Pending';
      case DriverVerificationStatus.approved:
        return 'Approved';
      case DriverVerificationStatus.rejected:
        return 'Rejected';
    }
  }
}

/// Driver entity representing a driver in the system
class DriverEntity {
  final String id;
  final String visibleId;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? email;
  final String? profilePhotoUrl;
  final DriverVerificationStatus verificationStatus;
  final bool isVerified;
  final DateTime? verifiedAt;
  final String? driverLicenseNumber;
  final DateTime? driverLicenseExpiry;
  final int vehicleCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const DriverEntity({
    required this.id,
    required this.visibleId,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.email,
    this.profilePhotoUrl,
    required this.verificationStatus,
    required this.isVerified,
    this.verifiedAt,
    this.driverLicenseNumber,
    this.driverLicenseExpiry,
    this.vehicleCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  /// Full name of the driver
  String get fullName => '$firstName $lastName'.trim();

  /// Initials for avatar placeholder
  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  /// Check if driver has profile photo
  bool get hasProfilePhoto => 
      profilePhotoUrl != null && profilePhotoUrl!.isNotEmpty;

  /// Check if license is expired
  bool get isLicenseExpired {
    if (driverLicenseExpiry == null) return false;
    return driverLicenseExpiry!.isBefore(DateTime.now());
  }

  /// Check if license expires within 30 days
  bool get isLicenseExpiringSoon {
    if (driverLicenseExpiry == null) return false;
    final thirtyDaysFromNow = DateTime.now().add(const Duration(days: 30));
    return driverLicenseExpiry!.isBefore(thirtyDaysFromNow) && 
           !driverLicenseExpiry!.isBefore(DateTime.now());
  }

  /// Copy with new values
  DriverEntity copyWith({
    String? id,
    String? visibleId,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? email,
    String? profilePhotoUrl,
    DriverVerificationStatus? verificationStatus,
    bool? isVerified,
    DateTime? verifiedAt,
    String? driverLicenseNumber,
    DateTime? driverLicenseExpiry,
    int? vehicleCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DriverEntity(
      id: id ?? this.id,
      visibleId: visibleId ?? this.visibleId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isVerified: isVerified ?? this.isVerified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      driverLicenseNumber: driverLicenseNumber ?? this.driverLicenseNumber,
      driverLicenseExpiry: driverLicenseExpiry ?? this.driverLicenseExpiry,
      vehicleCount: vehicleCount ?? this.vehicleCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DriverEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DriverEntity(id: $id, name: $fullName, status: $verificationStatus)';
  }
}

/// Driver counts by status
class DriverStatusCounts {
  final int total;
  final int pending;
  final int approved;
  final int rejected;

  const DriverStatusCounts({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  factory DriverStatusCounts.empty() {
    return const DriverStatusCounts(
      total: 0,
      pending: 0,
      approved: 0,
      rejected: 0,
    );
  }
}
