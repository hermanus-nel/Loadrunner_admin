import 'admin_notification_entity.dart';

/// Groups notification types into logical categories for the preferences screen.
enum NotificationCategory {
  disputeEvents,
  driverEvents,
  vehicleEvents,
  paymentEvents,
  shipmentEvents;

  String get displayName {
    switch (this) {
      case NotificationCategory.disputeEvents:
        return 'Dispute Events';
      case NotificationCategory.driverEvents:
        return 'Driver Events';
      case NotificationCategory.vehicleEvents:
        return 'Vehicle Events';
      case NotificationCategory.paymentEvents:
        return 'Payment Events';
      case NotificationCategory.shipmentEvents:
        return 'Shipment Events';
    }
  }

  List<AdminNotificationType> get types {
    switch (this) {
      case NotificationCategory.disputeEvents:
        return [
          AdminNotificationType.disputeLodged,
          AdminNotificationType.disputeEscalated,
          AdminNotificationType.disputeResolved,
        ];
      case NotificationCategory.driverEvents:
        return [
          AdminNotificationType.newUser,
          AdminNotificationType.driverRegistered,
          AdminNotificationType.driverDocumentUploaded,
          AdminNotificationType.driverSuspended,
        ];
      case NotificationCategory.vehicleEvents:
        return [
          AdminNotificationType.vehicleAdded,
          AdminNotificationType.vehicleDocumentUploaded,
        ];
      case NotificationCategory.paymentEvents:
        return [
          AdminNotificationType.paymentCompleted,
          AdminNotificationType.driverPayout,
        ];
      case NotificationCategory.shipmentEvents:
        return [
          AdminNotificationType.newShipment,
        ];
    }
  }

  /// Description for each notification type within this category.
  static String descriptionFor(AdminNotificationType type) {
    switch (type) {
      case AdminNotificationType.newUser:
        return 'When a new user registers on the platform';
      case AdminNotificationType.newShipment:
        return 'When a new shipment is posted for bidding';
      case AdminNotificationType.paymentCompleted:
        return 'When a payment is completed';
      case AdminNotificationType.driverRegistered:
        return 'When a new driver registers and is pending approval';
      case AdminNotificationType.disputeLodged:
        return 'When a new dispute is filed by a user';
      case AdminNotificationType.driverPayout:
        return 'When a driver payout is processed';
      case AdminNotificationType.disputeEscalated:
        return 'When a dispute is escalated to urgent priority';
      case AdminNotificationType.disputeResolved:
        return 'When a dispute is resolved';
      case AdminNotificationType.driverDocumentUploaded:
        return 'When a driver uploads a new document';
      case AdminNotificationType.driverSuspended:
        return 'When a driver account is suspended';
      case AdminNotificationType.vehicleAdded:
        return 'When a driver adds a new vehicle';
      case AdminNotificationType.vehicleDocumentUploaded:
        return 'When a vehicle document is uploaded';
    }
  }
}
