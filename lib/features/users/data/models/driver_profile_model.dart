import '../../domain/entities/driver_profile.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/entities/driver_document.dart';
import '../../domain/entities/approval_history_item.dart';
import '../../domain/entities/driver_bank_account.dart';
import 'vehicle_model.dart';
import 'driver_document_model.dart';
import 'approval_history_model.dart';
import 'driver_bank_account_model.dart';

/// Data model for DriverProfile with JSON serialization
class DriverProfileModel {
  final String id;
  final String phoneNumber;
  final String? firstName;
  final String? lastName;
  final String? email;
  final DateTime? dateOfBirth;
  final String? idNumber;
  final String? profilePhotoUrl;
  final String verificationStatus;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final String? verificationNotes;
  final bool isSuspended;
  final DateTime? suspendedAt;
  final String? suspendedReason;
  final String? suspendedBy;
  final DateTime? suspensionEndsAt;

  DriverProfileModel({
    required this.id,
    required this.phoneNumber,
    this.firstName,
    this.lastName,
    this.email,
    this.dateOfBirth,
    this.idNumber,
    this.profilePhotoUrl,
    required this.verificationStatus,
    required this.createdAt,
    this.verifiedAt,
    this.verifiedBy,
    this.verificationNotes,
    this.isSuspended = false,
    this.suspendedAt,
    this.suspendedReason,
    this.suspendedBy,
    this.suspensionEndsAt,
  });

  factory DriverProfileModel.fromJson(Map<String, dynamic> json) {
    return DriverProfileModel(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      dateOfBirth: json['dob'] != null
          ? DateTime.tryParse(json['dob'] as String)
          : null,
      idNumber: json['id_no'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      verificationStatus:
          json['driver_verification_status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      verifiedAt: json['driver_verified_at'] != null
          ? DateTime.tryParse(json['driver_verified_at'] as String)
          : null,
      verifiedBy: json['driver_verified_by'] as String?,
      verificationNotes: json['verification_notes'] as String?,
      isSuspended: json['is_suspended'] as bool? ?? false,
      suspendedAt: json['suspended_at'] != null
          ? DateTime.tryParse(json['suspended_at'] as String)
          : null,
      suspendedReason: json['suspended_reason'] as String?,
      suspendedBy: json['suspended_by'] as String?,
      suspensionEndsAt: json['suspension_ends_at'] != null
          ? DateTime.tryParse(json['suspension_ends_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'dob': dateOfBirth?.toIso8601String(),
      'id_no': idNumber,
      'profile_photo_url': profilePhotoUrl,
      'driver_verification_status': verificationStatus,
      'created_at': createdAt.toIso8601String(),
      'driver_verified_at': verifiedAt?.toIso8601String(),
      'driver_verified_by': verifiedBy,
      'verification_notes': verificationNotes,
      'is_suspended': isSuspended,
      'suspended_at': suspendedAt?.toIso8601String(),
      'suspended_reason': suspendedReason,
      'suspended_by': suspendedBy,
      'suspension_ends_at': suspensionEndsAt?.toIso8601String(),
    };
  }

  /// Convert to entity with related data
  DriverProfile toEntity({
    List<VehicleEntity> vehicles = const [],
    List<DriverDocument> documents = const [],
    List<ApprovalHistoryItem> approvalHistory = const [],
    DriverBankAccount? bankAccount,
  }) {
    return DriverProfile(
      id: id,
      phoneNumber: phoneNumber,
      firstName: firstName,
      lastName: lastName,
      email: email,
      dateOfBirth: dateOfBirth,
      idNumber: idNumber,
      profilePhotoUrl: profilePhotoUrl,
      verificationStatus: verificationStatus,
      createdAt: createdAt,
      verifiedAt: verifiedAt,
      verifiedBy: verifiedBy,
      verificationNotes: verificationNotes,
      isSuspended: isSuspended,
      suspendedAt: suspendedAt,
      suspendedReason: suspendedReason,
      suspendedBy: suspendedBy,
      suspensionEndsAt: suspensionEndsAt,
      vehicles: vehicles,
      documents: documents,
      approvalHistory: approvalHistory,
      bankAccount: bankAccount,
    );
  }

  static DriverProfileModel fromEntity(DriverProfile entity) {
    return DriverProfileModel(
      id: entity.id,
      phoneNumber: entity.phoneNumber,
      firstName: entity.firstName,
      lastName: entity.lastName,
      email: entity.email,
      dateOfBirth: entity.dateOfBirth,
      idNumber: entity.idNumber,
      profilePhotoUrl: entity.profilePhotoUrl,
      verificationStatus: entity.verificationStatus,
      createdAt: entity.createdAt,
      verifiedAt: entity.verifiedAt,
      verifiedBy: entity.verifiedBy,
      verificationNotes: entity.verificationNotes,
      isSuspended: entity.isSuspended,
      suspendedAt: entity.suspendedAt,
      suspendedReason: entity.suspendedReason,
      suspendedBy: entity.suspendedBy,
      suspensionEndsAt: entity.suspensionEndsAt,
    );
  }
}
