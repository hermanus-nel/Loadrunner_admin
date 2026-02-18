import 'package:equatable/equatable.dart';

/// Driver bank account entity
class DriverBankAccount extends Equatable {
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

  const DriverBankAccount({
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

  /// Get masked account number (show last 4 digits)
  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    return '****${accountNumber.substring(accountNumber.length - 4)}';
  }

  /// Check if bank account was rejected
  bool get isRejected => rejectedAt != null;

  /// Get verification status string
  String get verificationStatusLabel {
    if (isVerified) return 'Verified';
    if (isRejected) return 'Rejected';
    return 'Pending';
  }

  DriverBankAccount copyWith({
    String? id,
    String? driverId,
    String? bankCode,
    String? bankName,
    String? accountNumber,
    String? accountName,
    bool? isVerified,
    DateTime? verifiedAt,
    String? verificationMethod,
    String? verificationNotes,
    bool? isPrimary,
    bool? isActive,
    String? currency,
    DateTime? rejectedAt,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DriverBankAccount(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      bankCode: bankCode ?? this.bankCode,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      isVerified: isVerified ?? this.isVerified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      verificationNotes: verificationNotes ?? this.verificationNotes,
      isPrimary: isPrimary ?? this.isPrimary,
      isActive: isActive ?? this.isActive,
      currency: currency ?? this.currency,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        driverId,
        bankCode,
        bankName,
        accountNumber,
        accountName,
        isVerified,
        verifiedAt,
        verificationMethod,
        verificationNotes,
        isPrimary,
        isActive,
        currency,
        rejectedAt,
        rejectionReason,
        createdAt,
        updatedAt,
      ];
}
