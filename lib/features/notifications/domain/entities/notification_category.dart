import 'admin_notification_entity.dart';

/// Groups notification types into logical categories for the preferences screen.
enum NotificationCategory {
  disputeEvents,
  driverEvents,
  paymentEvents,
  systemEvents;

  String get displayName {
    switch (this) {
      case NotificationCategory.disputeEvents:
        return 'Dispute Events';
      case NotificationCategory.driverEvents:
        return 'Driver Events';
      case NotificationCategory.paymentEvents:
        return 'Payment Events';
      case NotificationCategory.systemEvents:
        return 'System Events';
    }
  }

  List<AdminNotificationType> get types {
    switch (this) {
      case NotificationCategory.disputeEvents:
        return [
          AdminNotificationType.disputeFiled,
          AdminNotificationType.disputeEscalated,
          AdminNotificationType.disputeResolved,
        ];
      case NotificationCategory.driverEvents:
        return [
          AdminNotificationType.driverPendingApproval,
          AdminNotificationType.driverDocumentUploaded,
          AdminNotificationType.driverSuspended,
        ];
      case NotificationCategory.paymentEvents:
        return [
          AdminNotificationType.paymentFailed,
          AdminNotificationType.paymentRefundRequested,
        ];
      case NotificationCategory.systemEvents:
        return [
          AdminNotificationType.adminSystemAlert,
        ];
    }
  }

  /// Description for each notification type within this category.
  static String descriptionFor(AdminNotificationType type) {
    switch (type) {
      case AdminNotificationType.disputeFiled:
        return 'When a new dispute is filed by a user';
      case AdminNotificationType.disputeEscalated:
        return 'When a dispute is escalated to urgent priority';
      case AdminNotificationType.disputeResolved:
        return 'When a dispute is resolved';
      case AdminNotificationType.driverPendingApproval:
        return 'When a new driver registers or resubmits documents';
      case AdminNotificationType.driverDocumentUploaded:
        return 'When a driver uploads a new document';
      case AdminNotificationType.driverSuspended:
        return 'When a driver account is suspended';
      case AdminNotificationType.paymentFailed:
        return 'When a payment fails';
      case AdminNotificationType.paymentRefundRequested:
        return 'When a refund is requested';
      case AdminNotificationType.adminSystemAlert:
        return 'Critical system alerts and warnings';
    }
  }
}
