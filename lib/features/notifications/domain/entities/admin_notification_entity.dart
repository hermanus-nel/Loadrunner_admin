import 'package:flutter/material.dart';

/// Admin notification types matching the DB admin_event_type enum.
enum AdminNotificationType {
  newUser,
  newShipment,
  paymentCompleted,
  driverRegistered,
  disputeLodged,
  driverPayout,
  disputeEscalated,
  disputeResolved,
  driverDocumentUploaded,
  driverSuspended,
  vehicleAdded,
  vehicleDocumentUploaded;

  /// Parse from database string.
  static AdminNotificationType fromString(String value) {
    switch (value) {
      case 'new_user':
        return AdminNotificationType.newUser;
      case 'new_shipment':
        return AdminNotificationType.newShipment;
      case 'payment_completed':
        return AdminNotificationType.paymentCompleted;
      case 'driver_registered':
        return AdminNotificationType.driverRegistered;
      case 'dispute_lodged':
        return AdminNotificationType.disputeLodged;
      case 'driver_payout':
        return AdminNotificationType.driverPayout;
      case 'dispute_escalated':
        return AdminNotificationType.disputeEscalated;
      case 'dispute_resolved':
        return AdminNotificationType.disputeResolved;
      case 'driver_document_uploaded':
        return AdminNotificationType.driverDocumentUploaded;
      case 'driver_suspended':
        return AdminNotificationType.driverSuspended;
      case 'vehicle_added':
        return AdminNotificationType.vehicleAdded;
      case 'vehicle_document_uploaded':
        return AdminNotificationType.vehicleDocumentUploaded;
      default:
        return AdminNotificationType.newUser;
    }
  }

  /// Convert to database string.
  String toJson() {
    switch (this) {
      case AdminNotificationType.newUser:
        return 'new_user';
      case AdminNotificationType.newShipment:
        return 'new_shipment';
      case AdminNotificationType.paymentCompleted:
        return 'payment_completed';
      case AdminNotificationType.driverRegistered:
        return 'driver_registered';
      case AdminNotificationType.disputeLodged:
        return 'dispute_lodged';
      case AdminNotificationType.driverPayout:
        return 'driver_payout';
      case AdminNotificationType.disputeEscalated:
        return 'dispute_escalated';
      case AdminNotificationType.disputeResolved:
        return 'dispute_resolved';
      case AdminNotificationType.driverDocumentUploaded:
        return 'driver_document_uploaded';
      case AdminNotificationType.driverSuspended:
        return 'driver_suspended';
      case AdminNotificationType.vehicleAdded:
        return 'vehicle_added';
      case AdminNotificationType.vehicleDocumentUploaded:
        return 'vehicle_document_uploaded';
    }
  }

  String get displayName {
    switch (this) {
      case AdminNotificationType.newUser:
        return 'New User';
      case AdminNotificationType.newShipment:
        return 'New Shipment';
      case AdminNotificationType.paymentCompleted:
        return 'Payment Completed';
      case AdminNotificationType.driverRegistered:
        return 'Driver Registered';
      case AdminNotificationType.disputeLodged:
        return 'Dispute Filed';
      case AdminNotificationType.driverPayout:
        return 'Driver Payout';
      case AdminNotificationType.disputeEscalated:
        return 'Dispute Escalated';
      case AdminNotificationType.disputeResolved:
        return 'Dispute Resolved';
      case AdminNotificationType.driverDocumentUploaded:
        return 'Document Uploaded';
      case AdminNotificationType.driverSuspended:
        return 'Driver Suspended';
      case AdminNotificationType.vehicleAdded:
        return 'Vehicle Added';
      case AdminNotificationType.vehicleDocumentUploaded:
        return 'Vehicle Document Uploaded';
    }
  }

  IconData get icon {
    switch (this) {
      case AdminNotificationType.newUser:
        return Icons.person_add;
      case AdminNotificationType.newShipment:
        return Icons.local_shipping;
      case AdminNotificationType.paymentCompleted:
        return Icons.payment;
      case AdminNotificationType.driverRegistered:
        return Icons.how_to_reg;
      case AdminNotificationType.disputeLodged:
        return Icons.gavel;
      case AdminNotificationType.driverPayout:
        return Icons.account_balance_wallet;
      case AdminNotificationType.disputeEscalated:
        return Icons.priority_high;
      case AdminNotificationType.disputeResolved:
        return Icons.check_circle;
      case AdminNotificationType.driverDocumentUploaded:
        return Icons.upload_file;
      case AdminNotificationType.driverSuspended:
        return Icons.person_off;
      case AdminNotificationType.vehicleAdded:
        return Icons.directions_car;
      case AdminNotificationType.vehicleDocumentUploaded:
        return Icons.description;
    }
  }

  Color get color {
    switch (this) {
      case AdminNotificationType.newUser:
        return Colors.blue;
      case AdminNotificationType.newShipment:
        return Colors.indigo;
      case AdminNotificationType.paymentCompleted:
        return Colors.green;
      case AdminNotificationType.driverRegistered:
        return Colors.blue;
      case AdminNotificationType.disputeLodged:
        return Colors.orange;
      case AdminNotificationType.driverPayout:
        return Colors.teal;
      case AdminNotificationType.disputeEscalated:
        return Colors.red;
      case AdminNotificationType.disputeResolved:
        return Colors.green;
      case AdminNotificationType.driverDocumentUploaded:
        return Colors.teal;
      case AdminNotificationType.driverSuspended:
        return Colors.red;
      case AdminNotificationType.vehicleAdded:
        return Colors.indigo;
      case AdminNotificationType.vehicleDocumentUploaded:
        return Colors.teal;
    }
  }
}

/// Represents a notification record from the admin_event_notifications table.
class AdminNotificationEntity {
  final String id;
  final String adminId;
  final AdminNotificationType eventType;
  final String message;
  final bool isRead;
  final bool archived;
  final String? relatedId;
  final Map<String, dynamic>? metadata;
  final String? deliveryMethod;
  final DateTime? sentAt;
  final DateTime createdAt;

  const AdminNotificationEntity({
    required this.id,
    required this.adminId,
    required this.eventType,
    required this.message,
    required this.isRead,
    required this.archived,
    this.relatedId,
    this.metadata,
    this.deliveryMethod,
    this.sentAt,
    required this.createdAt,
  });

  AdminNotificationEntity copyWith({
    bool? isRead,
    bool? archived,
  }) {
    return AdminNotificationEntity(
      id: id,
      adminId: adminId,
      eventType: eventType,
      message: message,
      isRead: isRead ?? this.isRead,
      archived: archived ?? this.archived,
      relatedId: relatedId,
      metadata: metadata,
      deliveryMethod: deliveryMethod,
      sentAt: sentAt,
      createdAt: createdAt,
    );
  }

  /// Time ago formatted string.
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
