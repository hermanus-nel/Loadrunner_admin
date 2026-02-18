import 'package:equatable/equatable.dart';
import 'driver_document.dart';

/// Composite entity combining a DriverDocument with driver context info
/// for display in the document review queue.
class DocumentQueueItem extends Equatable {
  final DriverDocument document;
  final String driverFirstName;
  final String driverLastName;
  final String? driverProfilePhotoUrl;
  final String? driverPhone;
  final String driverVerificationStatus;
  final DateTime driverCreatedAt;

  const DocumentQueueItem({
    required this.document,
    required this.driverFirstName,
    required this.driverLastName,
    this.driverProfilePhotoUrl,
    this.driverPhone,
    required this.driverVerificationStatus,
    required this.driverCreatedAt,
  });

  /// Full name of the driver
  String get driverFullName => '$driverFirstName $driverLastName';

  /// Driver initials for avatar fallback
  String get driverInitials {
    final first = driverFirstName.isNotEmpty ? driverFirstName[0] : '';
    final last = driverLastName.isNotEmpty ? driverLastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  DocumentQueueItem copyWith({
    DriverDocument? document,
    String? driverFirstName,
    String? driverLastName,
    String? driverProfilePhotoUrl,
    String? driverPhone,
    String? driverVerificationStatus,
    DateTime? driverCreatedAt,
  }) {
    return DocumentQueueItem(
      document: document ?? this.document,
      driverFirstName: driverFirstName ?? this.driverFirstName,
      driverLastName: driverLastName ?? this.driverLastName,
      driverProfilePhotoUrl:
          driverProfilePhotoUrl ?? this.driverProfilePhotoUrl,
      driverPhone: driverPhone ?? this.driverPhone,
      driverVerificationStatus:
          driverVerificationStatus ?? this.driverVerificationStatus,
      driverCreatedAt: driverCreatedAt ?? this.driverCreatedAt,
    );
  }

  @override
  List<Object?> get props => [
        document,
        driverFirstName,
        driverLastName,
        driverProfilePhotoUrl,
        driverPhone,
        driverVerificationStatus,
        driverCreatedAt,
      ];
}
