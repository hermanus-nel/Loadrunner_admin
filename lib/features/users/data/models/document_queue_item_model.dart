import '../../domain/entities/document_queue_item.dart';
import 'driver_document_model.dart';

/// Data model for DocumentQueueItem from Supabase joined query
///
/// Expected JSON shape from the query:
/// ```json
/// {
///   "id": "...",
///   "driver_id": "...",
///   "doc_type": "...",
///   "doc_url": "...",
///   "verification_status": "...",
///   ... other driver_docs fields,
///   "driver": {
///     "first_name": "...",
///     "last_name": "...",
///     "phone_number": "...",
///     "profile_photo_url": "...",
///     "driver_verification_status": "...",
///     "created_at": "..."
///   }
/// }
/// ```
class DocumentQueueItemModel {
  final DriverDocumentModel document;
  final String driverFirstName;
  final String driverLastName;
  final String? driverProfilePhotoUrl;
  final String? driverPhone;
  final String driverVerificationStatus;
  final DateTime driverCreatedAt;

  DocumentQueueItemModel({
    required this.document,
    required this.driverFirstName,
    required this.driverLastName,
    this.driverProfilePhotoUrl,
    this.driverPhone,
    required this.driverVerificationStatus,
    required this.driverCreatedAt,
  });

  factory DocumentQueueItemModel.fromJson(Map<String, dynamic> json) {
    final driverJson = json['driver'] as Map<String, dynamic>? ?? {};

    return DocumentQueueItemModel(
      document: DriverDocumentModel.fromJson(json),
      driverFirstName: driverJson['first_name'] as String? ?? '',
      driverLastName: driverJson['last_name'] as String? ?? '',
      driverProfilePhotoUrl: driverJson['profile_photo_url'] as String?,
      driverPhone: driverJson['phone_number'] as String?,
      driverVerificationStatus:
          driverJson['driver_verification_status'] as String? ?? 'pending',
      driverCreatedAt: driverJson['created_at'] != null
          ? DateTime.parse(driverJson['created_at'] as String)
          : DateTime.now(),
    );
  }

  DocumentQueueItem toEntity() {
    return DocumentQueueItem(
      document: document.toEntity(),
      driverFirstName: driverFirstName,
      driverLastName: driverLastName,
      driverProfilePhotoUrl: driverProfilePhotoUrl,
      driverPhone: driverPhone,
      driverVerificationStatus: driverVerificationStatus,
      driverCreatedAt: driverCreatedAt,
    );
  }
}
