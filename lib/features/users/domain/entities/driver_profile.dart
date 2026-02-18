import 'package:equatable/equatable.dart';

import 'vehicle_entity.dart';
import 'driver_document.dart';
import 'approval_history_item.dart';
import 'driver_bank_account.dart';

/// Full driver profile entity with all related data
class DriverProfile extends Equatable {
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

  // Related data
  final List<VehicleEntity> vehicles;
  final List<DriverDocument> documents;
  final List<ApprovalHistoryItem> approvalHistory;
  final DriverBankAccount? bankAccount;

  const DriverProfile({
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
    this.vehicles = const [],
    this.documents = const [],
    this.approvalHistory = const [],
    this.bankAccount,
  });

  /// Get full name or phone number as fallback
  String get displayName {
    if (firstName != null || lastName != null) {
      return '${firstName ?? ''} ${lastName ?? ''}'.trim();
    }
    return phoneNumber;
  }

  /// Get initials for avatar
  String get initials {
    if (firstName != null && lastName != null) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    }
    if (firstName != null) {
      return firstName![0].toUpperCase();
    }
    return phoneNumber.substring(phoneNumber.length - 2);
  }

  /// Check if driver is pending approval
  bool get isPending => verificationStatus == 'pending';

  /// Check if driver is approved
  bool get isApproved => verificationStatus == 'approved';

  /// Check if driver is rejected
  bool get isRejected => verificationStatus == 'rejected';

  /// Check if driver has documents requested
  bool get hasDocumentsRequested => verificationStatus == 'documents_requested';

  /// Check if driver is under review
  bool get isUnderReview => verificationStatus == 'under_review';

  /// Masked ID number for display (show last 4 digits)
  String? get maskedIdNumber {
    if (idNumber == null || idNumber!.length < 4) return idNumber;
    return '****${idNumber!.substring(idNumber!.length - 4)}';
  }

  /// Count of pending documents
  int get pendingDocumentsCount =>
      documents.where((d) => d.verificationStatus == 'pending').length;

  /// Count of approved documents
  int get approvedDocumentsCount =>
      documents.where((d) => d.verificationStatus == 'approved').length;

  /// Count of verified vehicles
  int get verifiedVehiclesCount =>
      vehicles.where((v) => v.verificationStatus == 'approved').length;

  DriverProfile copyWith({
    String? id,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? email,
    DateTime? dateOfBirth,
    String? idNumber,
    String? profilePhotoUrl,
    String? verificationStatus,
    DateTime? createdAt,
    DateTime? verifiedAt,
    String? verifiedBy,
    String? verificationNotes,
    bool? isSuspended,
    DateTime? suspendedAt,
    String? suspendedReason,
    String? suspendedBy,
    DateTime? suspensionEndsAt,
    List<VehicleEntity>? vehicles,
    List<DriverDocument>? documents,
    List<ApprovalHistoryItem>? approvalHistory,
    DriverBankAccount? bankAccount,
  }) {
    return DriverProfile(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      idNumber: idNumber ?? this.idNumber,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdAt: createdAt ?? this.createdAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verificationNotes: verificationNotes ?? this.verificationNotes,
      isSuspended: isSuspended ?? this.isSuspended,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      suspendedReason: suspendedReason ?? this.suspendedReason,
      suspendedBy: suspendedBy ?? this.suspendedBy,
      suspensionEndsAt: suspensionEndsAt ?? this.suspensionEndsAt,
      vehicles: vehicles ?? this.vehicles,
      documents: documents ?? this.documents,
      approvalHistory: approvalHistory ?? this.approvalHistory,
      bankAccount: bankAccount ?? this.bankAccount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        phoneNumber,
        firstName,
        lastName,
        email,
        dateOfBirth,
        idNumber,
        profilePhotoUrl,
        verificationStatus,
        createdAt,
        verifiedAt,
        verifiedBy,
        verificationNotes,
        isSuspended,
        suspendedAt,
        suspendedReason,
        suspendedBy,
        suspensionEndsAt,
        vehicles,
        documents,
        approvalHistory,
        bankAccount,
      ];
}
