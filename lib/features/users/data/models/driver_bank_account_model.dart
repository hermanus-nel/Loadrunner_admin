import '../../domain/entities/driver_bank_account.dart';

/// Data model for DriverBankAccount with JSON serialization
class DriverBankAccountModel {
  final String id;
  final String driverId;
  final String bankCode;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final bool isVerified;
  final DateTime? verifiedAt;
  final String? verificationMethod;
  final String? verificationNotes;
  final bool isPrimary;
  final bool isActive;
  final String currency;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  DriverBankAccountModel({
    required this.id,
    required this.driverId,
    required this.bankCode,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    this.isVerified = false,
    this.verifiedAt,
    this.verificationMethod,
    this.verificationNotes,
    this.isPrimary = true,
    this.isActive = true,
    this.currency = 'ZAR',
    this.rejectedAt,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverBankAccountModel.fromJson(Map<String, dynamic> json) {
    return DriverBankAccountModel(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      bankCode: json['bank_code'] as String,
      bankName: json['bank_name'] as String,
      accountNumber: json['account_number'] as String,
      accountName: json['account_name'] as String,
      isVerified: json['is_verified'] as bool? ?? false,
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'] as String)
          : null,
      verificationMethod: json['verification_method'] as String?,
      verificationNotes: json['verification_notes'] as String?,
      isPrimary: json['is_primary'] as bool? ?? true,
      isActive: json['is_active'] as bool? ?? true,
      currency: json['currency'] as String? ?? 'ZAR',
      rejectedAt: json['rejected_at'] != null
          ? DateTime.tryParse(json['rejected_at'] as String)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'bank_code': bankCode,
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_name': accountName,
      'is_verified': isVerified,
      'verified_at': verifiedAt?.toIso8601String(),
      'verification_method': verificationMethod,
      'verification_notes': verificationNotes,
      'is_primary': isPrimary,
      'is_active': isActive,
      'currency': currency,
      'rejected_at': rejectedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DriverBankAccount toEntity() {
    return DriverBankAccount(
      id: id,
      driverId: driverId,
      bankCode: bankCode,
      bankName: bankName,
      accountNumber: accountNumber,
      accountName: accountName,
      isVerified: isVerified,
      verifiedAt: verifiedAt,
      verificationMethod: verificationMethod,
      verificationNotes: verificationNotes,
      isPrimary: isPrimary,
      isActive: isActive,
      currency: currency,
      rejectedAt: rejectedAt,
      rejectionReason: rejectionReason,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DriverBankAccountModel fromEntity(DriverBankAccount entity) {
    return DriverBankAccountModel(
      id: entity.id,
      driverId: entity.driverId,
      bankCode: entity.bankCode,
      bankName: entity.bankName,
      accountNumber: entity.accountNumber,
      accountName: entity.accountName,
      isVerified: entity.isVerified,
      verifiedAt: entity.verifiedAt,
      verificationMethod: entity.verificationMethod,
      verificationNotes: entity.verificationNotes,
      isPrimary: entity.isPrimary,
      isActive: entity.isActive,
      currency: entity.currency,
      rejectedAt: entity.rejectedAt,
      rejectionReason: entity.rejectionReason,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
