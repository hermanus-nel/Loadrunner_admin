import 'package:flutter/material.dart';

/// Admin notification types matching the DB notification_type enum.
enum AdminNotificationType {
  disputeFiled,
  disputeEscalated,
  disputeResolved,
  driverPendingApproval,
  driverDocumentUploaded,
  driverSuspended,
  paymentFailed,
  paymentRefundRequested,
  adminSystemAlert;

  /// Parse from database string.
  static AdminNotificationType fromString(String value) {
    switch (value) {
      case 'dispute_filed':
        return AdminNotificationType.disputeFiled;
      case 'dispute_escalated':
        return AdminNotificationType.disputeEscalated;
      case 'dispute_resolved':
        return AdminNotificationType.disputeResolved;
      case 'driver_pending_approval':
        return AdminNotificationType.driverPendingApproval;
      case 'driver_document_uploaded':
        return AdminNotificationType.driverDocumentUploaded;
      case 'driver_suspended':
        return AdminNotificationType.driverSuspended;
      case 'payment_failed':
        return AdminNotificationType.paymentFailed;
      case 'payment_refund_requested':
        return AdminNotificationType.paymentRefundRequested;
      case 'admin_system_alert':
        return AdminNotificationType.adminSystemAlert;
      default:
        return AdminNotificationType.adminSystemAlert;
    }
  }

  /// Convert to database string.
  String toJson() {
    switch (this) {
      case AdminNotificationType.disputeFiled:
        return 'dispute_filed';
      case AdminNotificationType.disputeEscalated:
        return 'dispute_escalated';
      case AdminNotificationType.disputeResolved:
        return 'dispute_resolved';
      case AdminNotificationType.driverPendingApproval:
        return 'driver_pending_approval';
      case AdminNotificationType.driverDocumentUploaded:
        return 'driver_document_uploaded';
      case AdminNotificationType.driverSuspended:
        return 'driver_suspended';
      case AdminNotificationType.paymentFailed:
        return 'payment_failed';
      case AdminNotificationType.paymentRefundRequested:
        return 'payment_refund_requested';
      case AdminNotificationType.adminSystemAlert:
        return 'admin_system_alert';
    }
  }

  String get displayName {
    switch (this) {
      case AdminNotificationType.disputeFiled:
        return 'Dispute Filed';
      case AdminNotificationType.disputeEscalated:
        return 'Dispute Escalated';
      case AdminNotificationType.disputeResolved:
        return 'Dispute Resolved';
      case AdminNotificationType.driverPendingApproval:
        return 'Driver Pending Approval';
      case AdminNotificationType.driverDocumentUploaded:
        return 'Document Uploaded';
      case AdminNotificationType.driverSuspended:
        return 'Driver Suspended';
      case AdminNotificationType.paymentFailed:
        return 'Payment Failed';
      case AdminNotificationType.paymentRefundRequested:
        return 'Refund Requested';
      case AdminNotificationType.adminSystemAlert:
        return 'System Alert';
    }
  }

  IconData get icon {
    switch (this) {
      case AdminNotificationType.disputeFiled:
        return Icons.gavel;
      case AdminNotificationType.disputeEscalated:
        return Icons.priority_high;
      case AdminNotificationType.disputeResolved:
        return Icons.check_circle;
      case AdminNotificationType.driverPendingApproval:
        return Icons.person_add;
      case AdminNotificationType.driverDocumentUploaded:
        return Icons.upload_file;
      case AdminNotificationType.driverSuspended:
        return Icons.person_off;
      case AdminNotificationType.paymentFailed:
        return Icons.money_off;
      case AdminNotificationType.paymentRefundRequested:
        return Icons.request_quote;
      case AdminNotificationType.adminSystemAlert:
        return Icons.warning_amber;
    }
  }

  Color get color {
    switch (this) {
      case AdminNotificationType.disputeFiled:
        return Colors.orange;
      case AdminNotificationType.disputeEscalated:
        return Colors.red;
      case AdminNotificationType.disputeResolved:
        return Colors.green;
      case AdminNotificationType.driverPendingApproval:
        return Colors.blue;
      case AdminNotificationType.driverDocumentUploaded:
        return Colors.teal;
      case AdminNotificationType.driverSuspended:
        return Colors.red;
      case AdminNotificationType.paymentFailed:
        return Colors.red;
      case AdminNotificationType.paymentRefundRequested:
        return Colors.orange;
      case AdminNotificationType.adminSystemAlert:
        return Colors.purple;
    }
  }
}

/// Represents a notification record from the notifications table.
class AdminNotificationEntity {
  final String id;
  final String userId;
  final String message;
  final bool isRead;
  final bool archived;
  final AdminNotificationType? type;
  final String? relatedId;
  final String? deliveryMethod;
  final DateTime? sentAt;
  final DateTime createdAt;

  const AdminNotificationEntity({
    required this.id,
    required this.userId,
    required this.message,
    required this.isRead,
    required this.archived,
    this.type,
    this.relatedId,
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
      userId: userId,
      message: message,
      isRead: isRead ?? this.isRead,
      archived: archived ?? this.archived,
      type: type,
      relatedId: relatedId,
      deliveryMethod: deliveryMethod,
      sentAt: sentAt,
      createdAt: createdAt,
    );
  }

  /// Check if this is an admin-specific notification type.
  bool get isAdminType => type != null;

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
